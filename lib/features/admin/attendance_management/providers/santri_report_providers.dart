import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/models/santri_report_model.dart';

/// Provider untuk data santri list
final santriListProvider = FutureProvider<List<SantriBasicInfo>>((ref) async {
  final db = FirebaseFirestore.instance;

  final snapshot = await db
      .collection('users')
      .where('role', isEqualTo: 'santri')
      .where('statusAktif', isEqualTo: true)
      .orderBy('nama')
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return SantriBasicInfo(
      userId: doc.id,
      nama: data['nama'] as String,
      nim: data['nim'] as String?,
      fotoProfil: data['fotoProfil'] as String?,
    );
  }).toList();
});

/// Provider untuk laporan detail per santri menggunakan aggregates
final santriReportProvider = FutureProvider.family<SantriReportModel, String>((
  ref,
  userId,
) async {
  final db = FirebaseFirestore.instance;

  // 1. Ambil data user
  final userDoc = await db.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw Exception('User tidak ditemukan');
  }

  final userData = userDoc.data()!;
  userData['id'] = userDoc.id;

  // 2. Ambil semua aggregates untuk user ini
  final aggregatesSnapshot = await db
      .collection('presensi_aggregates')
      .where('userId', isEqualTo: userId)
      .get();

  final aggregates = aggregatesSnapshot.docs.map((doc) => doc.data()).toList();

  // 3. Build model dari user + aggregates
  return SantriReportModel.fromUserAndAggregates(
    userData: userData,
    aggregates: aggregates,
  );
});

/// Provider untuk laporan santri dengan filter periode
final santriReportWithPeriodProvider =
    FutureProvider.family<SantriReportModel, SantriReportParams>((
      ref,
      params,
    ) async {
      final db = FirebaseFirestore.instance;

      // 1. Ambil data user
      final userDoc = await db.collection('users').doc(params.userId).get();

      if (!userDoc.exists) {
        throw Exception('User tidak ditemukan');
      }

      final userData = userDoc.data()!;
      userData['id'] = userDoc.id;

      // 2. Build query untuk aggregates dengan filter periode
      Query query = db
          .collection('presensi_aggregates')
          .where('userId', isEqualTo: params.userId);

      // Filter berdasarkan periode jika ada
      if (params.startDate != null && params.endDate != null) {
        query = query
            .where('startDate', isGreaterThanOrEqualTo: params.startDate)
            .where('endDate', isLessThanOrEqualTo: params.endDate);
      }

      // Filter berdasarkan tipe periode
      if (params.periodeType != null) {
        query = query.where('periode', isEqualTo: params.periodeType);
      }

      final aggregatesSnapshot = await query.get();

      final aggregates = aggregatesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // 3. Build model
      return SantriReportModel.fromUserAndAggregates(
        userData: userData,
        aggregates: aggregates,
      );
    });

/// Provider untuk mendapatkan statistik komparatif antar santri
final santriComparativeStatsProvider =
    FutureProvider<List<SantriComparativeStats>>((ref) async {
      final db = FirebaseFirestore.instance;

      // Ambil semua santri aktif
      final usersSnapshot = await db
          .collection('users')
          .where('role', isEqualTo: 'santri')
          .where('statusAktif', isEqualTo: true)
          .get();

      List<SantriComparativeStats> statsList = [];

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final nama = userDoc.data()['nama'] as String;

        // Ambil aggregates untuk bulan ini
        final now = DateTime.now();
        final periodeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';

        final aggregateSnapshot = await db
            .collection('presensi_aggregates')
            .where('userId', isEqualTo: userId)
            .where('periode', isEqualTo: 'monthly')
            .where('periodeKey', isEqualTo: periodeKey)
            .limit(1)
            .get();

        if (aggregateSnapshot.docs.isNotEmpty) {
          final data = aggregateSnapshot.docs.first.data();

          statsList.add(
            SantriComparativeStats(
              userId: userId,
              nama: nama,
              totalHadir: data['totalHadir'] as int? ?? 0,
              totalPresensi:
                  (data['totalHadir'] as int? ?? 0) +
                  (data['totalTerlambat'] as int? ?? 0) +
                  (data['totalIzin'] as int? ?? 0) +
                  (data['totalSakit'] as int? ?? 0) +
                  (data['totalAlpha'] as int? ?? 0),
              totalPoin: data['totalPoin'] as int? ?? 0,
            ),
          );
        }
      }

      // Sort by persentase kehadiran
      statsList.sort(
        (a, b) => b.persentaseKehadiran.compareTo(a.persentaseKehadiran),
      );

      return statsList;
    });

/// Model untuk info dasar santri
class SantriBasicInfo {
  final String userId;
  final String nama;
  final String? nim;
  final String? fotoProfil;

  SantriBasicInfo({
    required this.userId,
    required this.nama,
    this.nim,
    this.fotoProfil,
  });
}

/// Parameter untuk filter laporan santri
class SantriReportParams {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? periodeType; // 'daily', 'weekly', 'monthly', etc

  SantriReportParams({
    required this.userId,
    this.startDate,
    this.endDate,
    this.periodeType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SantriReportParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          periodeType == other.periodeType;

  @override
  int get hashCode =>
      userId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      periodeType.hashCode;
}

/// Model untuk statistik komparatif
class SantriComparativeStats {
  final String userId;
  final String nama;
  final int totalHadir;
  final int totalPresensi;
  final int totalPoin;

  SantriComparativeStats({
    required this.userId,
    required this.nama,
    required this.totalHadir,
    required this.totalPresensi,
    required this.totalPoin,
  });

  double get persentaseKehadiran {
    if (totalPresensi == 0) return 0;
    return (totalHadir / totalPresensi) * 100;
  }
}
