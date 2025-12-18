import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/hafalan_materi.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../../domain/repositories/hafalan_repository.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

class HafalanRepositoryImpl implements HafalanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _defaultHafalanPoints = 1;
  List<HafalanMateri>? _cachedQuran;

  // Collections
  CollectionReference get _materiCollection =>
      _firestore.collection('hafalan_materi');
  CollectionReference get _progressCollection =>
      _firestore.collection('hafalan_progress');

  // ==================== MATERI METHODS ====================

  @override
  Future<List<HafalanMateri>> getAllMateri() async {
    try {
      final snapshot = await _materiCollection
          .where('isActive', isEqualTo: true)
          .orderBy('urutan')
          .orderBy('createdAt')
          .get();

      final materiDb = snapshot.docs
          .map((doc) => HafalanMateri.fromFirestore(doc))
          .toList();

      final quran = await _loadQuranMateri();

      return [...quran, ...materiDb];
    } catch (e) {
      throw Exception('Gagal mengambil data materi: $e');
    }
  }

  @override
  Future<List<HafalanMateri>> getMateriByTipe(String tipe) async {
    try {
      if (tipe == 'alquran') {
        return await _loadQuranMateri();
      }
      final snapshot = await _materiCollection
          .where('tipe', isEqualTo: tipe)
          .where('isActive', isEqualTo: true)
          .orderBy('urutan')
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => HafalanMateri.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data materi tipe $tipe: $e');
    }
  }

  @override
  Future<HafalanMateri?> getMateriById(String id) async {
    try {
      final quran = await _loadQuranMateri();
      HafalanMateri? qFound;
      for (final m in quran) {
        if (m.id == id) {
          qFound = m;
          break;
        }
      }
      if (qFound != null) return qFound;

      final doc = await _materiCollection.doc(id).get();
      if (!doc.exists) return null;
      return HafalanMateri.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal mengambil materi: $e');
    }
  }

  @override
  Future<void> createMateri(HafalanMateri materi) async {
    try {
      await _materiCollection.add(materi.toFirestore());
    } catch (e) {
      throw Exception('Gagal membuat materi: $e');
    }
  }

  @override
  Future<void> updateMateri(HafalanMateri materi) async {
    try {
      await _materiCollection.doc(materi.id).update(materi.toFirestore());
    } catch (e) {
      throw Exception('Gagal update materi: $e');
    }
  }

  @override
  Future<void> deleteMateri(String id) async {
    try {
      // Soft delete
      await _materiCollection.doc(id).update({'isActive': false});
    } catch (e) {
      throw Exception('Gagal hapus materi: $e');
    }
  }

  // ==================== PROGRESS METHODS ====================

  @override
  Future<List<HafalanProgress>> getProgressBySantri(String santriId) async {
    try {
      final snapshot = await _progressCollection
          .where('santriId', isEqualTo: santriId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HafalanProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil progress santri: $e');
    }
  }

  @override
  Future<List<HafalanProgress>> getProgressByMateri(String materiId) async {
    try {
      final snapshot = await _progressCollection
          .where('materiId', isEqualTo: materiId)
          .get();

      return snapshot.docs
          .map((doc) => HafalanProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil progress materi: $e');
    }
  }

  @override
  Future<HafalanProgress?> getProgressBySantriAndMateri(
    String santriId,
    String materiId,
  ) async {
    try {
      final snapshot = await _progressCollection
          .where('santriId', isEqualTo: santriId)
          .where('materiId', isEqualTo: materiId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return HafalanProgress.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Gagal mengambil progress: $e');
    }
  }

  @override
  Future<void> createProgress(HafalanProgress progress) async {
    try {
      final poin = await _getMateriPoin(progress.materiId);
      final progressWithPoin = progress.copyWith(poin: poin);

      await _progressCollection.add(progressWithPoin.toFirestore());
      await FirestoreService.updateUserPoin(progressWithPoin.santriId, poin);
      await PresensiAggregateService.addPoinOnly(
        userId: progressWithPoin.santriId,
        poin: poin,
        tanggal: progressWithPoin.updatedAt,
      );

      // Bonus poin ketika langsung selesai
      if (progressWithPoin.status == 'selesai') {
        await FirestoreService.updateUserPoin(progressWithPoin.santriId, poin);
        await PresensiAggregateService.addPoinOnly(
          userId: progressWithPoin.santriId,
          poin: poin,
          tanggal: progressWithPoin.updatedAt,
        );
      }
    } catch (e) {
      throw Exception('Gagal membuat progress: $e');
    }
  }

  Future<int> _getMateriPoin(String materiId) async {
    try {
      final doc = await _materiCollection.doc(materiId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        // Cek dari asset Quran jika bukan materi Firestore
        final quran = await _loadQuranMateri();
        for (final m in quran) {
          if (m.id == materiId) return m.poin;
        }
        return _defaultHafalanPoints;
      }

      // Quran: poin = 1 per 5 ayat (dibulatkan ke atas), min 1
      if (data['tipe'] == 'alquran') {
        final rawTotal = data['total_verses'];
        int? totalAyat;
        if (rawTotal is int) totalAyat = rawTotal;
        if (rawTotal is double) totalAyat = rawTotal.round();
        if (totalAyat != null && totalAyat > 0) {
          final poinQuran = ((totalAyat + 4) ~/ 5).clamp(1, 1 << 31);
          return poinQuran;
        }
      }

      final poin = data['poin'];
      if (poin is int && poin >= 0) return poin;
      if (poin is double) return poin.round().clamp(0, 1 << 31);
      return _defaultHafalanPoints;
    } catch (_) {
      return _defaultHafalanPoints;
    }
  }

  Future<List<HafalanMateri>> _loadQuranMateri() async {
    if (_cachedQuran != null) return _cachedQuran!;

    try {
      final jsonStr = await rootBundle.loadString('assets/quran.json');
      final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;

      _cachedQuran = data.map((item) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int? ?? 0;
        final total = map['total_verses'] as int? ?? 0;
        final poin = ((total + 4) ~/ 5).clamp(1, 1 << 31);
        return HafalanMateri(
          id: 'quran-$id',
          nama:
              map['transliteration'] as String? ??
              map['name'] as String? ??
              'Surah $id',
          tipe: 'alquran',
          link: map['link'] as String?,
          poin: poin,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          createdBy: null,
          isActive: true,
          urutan: id,
        );
      }).toList();

      return _cachedQuran!;
    } catch (e) {
      _cachedQuran = [];
      return _cachedQuran!;
    }
  }

  @override
  Future<void> updateProgress(HafalanProgress progress) async {
    try {
      String? oldStatus;
      int? oldNilai;
      try {
        final current = await _progressCollection.doc(progress.id).get();
        final data = current.data() as Map<String, dynamic>?;
        oldStatus = data?['status'] as String?;
        final rawNilai = data?['nilai'];
        if (rawNilai is int) oldNilai = rawNilai;
        if (rawNilai is double) oldNilai = rawNilai.round();
      } catch (_) {
        oldStatus = null;
        oldNilai = null;
      }

      await _progressCollection.doc(progress.id).update(progress.toFirestore());

      // Bonus poin saat pertama kali selesai atau saat nilai pertama kali diisi
      final isNewlySelesai =
          oldStatus != 'selesai' && progress.status == 'selesai';
      final isNewlyGraded =
          progress.status == 'selesai' &&
          oldNilai == null &&
          progress.nilai != null;

      if (isNewlySelesai || isNewlyGraded) {
        final poin = progress.poin > 0
            ? progress.poin
            : await _getMateriPoin(progress.materiId);
        await FirestoreService.updateUserPoin(progress.santriId, poin);
        await PresensiAggregateService.addPoinOnly(
          userId: progress.santriId,
          poin: poin,
          tanggal: progress.updatedAt,
        );
      }
    } catch (e) {
      throw Exception('Gagal update progress: $e');
    }
  }

  @override
  Future<void> deleteProgress(String id) async {
    try {
      await _progressCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Gagal hapus progress: $e');
    }
  }

  // ==================== COMBINED QUERIES ====================

  @override
  Future<List<Map<String, dynamic>>> getProgressWithMateri(
    String santriId,
  ) async {
    try {
      // Get all progress for santri
      final progressList = await getProgressBySantri(santriId);

      // Get all materi
      final allMateri = await getAllMateri();

      // Combine data
      final result = <Map<String, dynamic>>[];

      for (final materi in allMateri) {
        final progress = progressList.firstWhere(
          (p) => p.materiId == materi.id,
          orElse: () => HafalanProgress(
            id: '',
            santriId: santriId,
            santriName: '',
            materiId: materi.id,
            status: 'belum',
            poin: materi.poin,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        result.add({'materi': materi, 'progress': progress});
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil data gabungan: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingConfirmations() async {
    try {
      // Get all progress with status 'proses'
      final snapshot = await _progressCollection
          .where('status', isEqualTo: 'proses')
          .orderBy('updatedAt', descending: true)
          .get();

      final progressList = snapshot.docs
          .map((doc) => HafalanProgress.fromFirestore(doc))
          .toList();

      // Get materi and santri data
      final result = <Map<String, dynamic>>[];

      for (final progress in progressList) {
        final materi = await getMateriById(progress.materiId);
        if (materi != null) {
          result.add({
            'progress': progress,
            'materi': materi,
            'santriName': progress.santriName,
          });
        }
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil data konfirmasi pending: $e');
    }
  }

  // ==================== STATISTICS ====================

  @override
  Future<Map<String, int>> getStatisticsBySantri(String santriId) async {
    try {
      final progressList = await getProgressBySantri(santriId);
      final allMateri = await getAllMateri();

      // Peta materi untuk fallback poin jika progress belum menyimpan poin
      final materiPoinMap = {
        for (final materi in allMateri) materi.id: materi.poin,
      };

      final belum = progressList.where((p) => p.status == 'belum').length;
      final proses = progressList.where((p) => p.status == 'proses').length;
      final selesai = progressList.where((p) => p.status == 'selesai').length;
      final total = allMateri.length;

      final totalPoinSelesai = progressList
          .where((p) => p.status == 'selesai')
          .fold<int>(0, (sum, p) {
            final poin = p.poin > 0
                ? p.poin
                : (materiPoinMap[p.materiId] ?? _defaultHafalanPoints);
            return sum + poin;
          });

      return {
        'total': total,
        'belum': belum,
        'proses': proses,
        'selesai': selesai,
        'poin': totalPoinSelesai,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }
}
