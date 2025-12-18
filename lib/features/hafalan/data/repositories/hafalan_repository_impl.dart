import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/hafalan_materi.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../../domain/repositories/hafalan_repository.dart';

class HafalanRepositoryImpl implements HafalanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      return snapshot.docs
          .map((doc) => HafalanMateri.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data materi: $e');
    }
  }

  @override
  Future<List<HafalanMateri>> getMateriByTipe(String tipe) async {
    try {
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
      await _progressCollection.add(progress.toFirestore());
    } catch (e) {
      throw Exception('Gagal membuat progress: $e');
    }
  }

  @override
  Future<void> updateProgress(HafalanProgress progress) async {
    try {
      await _progressCollection.doc(progress.id).update(progress.toFirestore());
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
            materiId: materi.id,
            status: 'belum',
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
          // Get santri name from users collection
          final santriDoc = await _firestore
              .collection('users')
              .doc(progress.santriId)
              .get();

          final santriName = santriDoc.exists
              ? (santriDoc.data()?['name'] ?? 'Unknown')
              : 'Unknown';

          result.add({
            'progress': progress,
            'materi': materi,
            'santriName': santriName,
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

      final belum = progressList.where((p) => p.status == 'belum').length;
      final proses = progressList.where((p) => p.status == 'proses').length;
      final selesai = progressList.where((p) => p.status == 'selesai').length;
      final total = allMateri.length;

      return {
        'total': total,
        'belum': belum,
        'proses': proses,
        'selesai': selesai,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }
}
