import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/features/admin/attendance_management/data/attendance_report_filter.dart';

/// Provider untuk data laporan presensi menggunakan Aggregate
final attendanceReportProvider =
    FutureProvider.family<Map<String, dynamic>, AttendanceReportFilter>((
      ref,
      filter,
    ) async {
      try {
        final firestore = FirebaseFirestore.instance;

        // Get users data
        final usersSnapshot = await firestore.collection('users').get();
        final users = usersSnapshot.docs
            .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
            .where((user) => user.isSantri)
            .toList();

        // Tentukan periode berdasarkan filter
        String periode;
        String periodeKey;

        if (filter.startDate != null && filter.endDate != null) {
          final diff = filter.endDate!.difference(filter.startDate!).inDays;

          if (diff <= 1) {
            periode = 'daily';
            periodeKey = PeriodeKeyHelper.daily(filter.startDate!);
          } else if (diff <= 7) {
            periode = 'weekly';
            periodeKey = PeriodeKeyHelper.weekly(filter.startDate!);
          } else if (diff <= 31) {
            periode = 'monthly';
            periodeKey = PeriodeKeyHelper.monthly(filter.startDate!);
          } else if (diff <= 180) {
            periode = 'semester';
            periodeKey = PeriodeKeyHelper.semester(filter.startDate!);
          } else {
            periode = 'yearly';
            periodeKey = PeriodeKeyHelper.yearly(filter.startDate!);
          }
        } else {
          periode = 'monthly';
          periodeKey = PeriodeKeyHelper.monthly(DateTime.now());
        }

        // Build aggregate query
        Query aggregateQuery = firestore
            .collection('presensi_aggregates')
            .where('periode', isEqualTo: periode)
            .where('periodeKey', isEqualTo: periodeKey);

        // Apply user filter
        if (filter.userId != null) {
          aggregateQuery = aggregateQuery.where(
            'userId',
            isEqualTo: filter.userId,
          );
        }

        final aggregateSnapshot = await aggregateQuery.get();

        // Parse to PresensiAggregateModel
        final aggregates = aggregateSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PresensiAggregateModel.fromJson({'id': doc.id, ...data});
        }).toList();

        return _calculateAttendanceStatisticsFromAggregates(
          aggregates,
          users,
          periode,
          periodeKey,
        );
      } catch (e) {
        throw Exception('Failed to fetch attendance report: $e');
      }
    });

/// State provider untuk filter
final attendanceFilterProvider = StateProvider<AttendanceReportFilter>((ref) {
  return const AttendanceReportFilter();
});

Map<String, dynamic> _calculateAttendanceStatisticsFromAggregates(
  List<PresensiAggregateModel> aggregates,
  List<UserModel> users,
  String periode,
  String periodeKey,
) {
  // Calculate statistics from aggregates
  int presentCount = 0;
  int absentCount = 0;
  int sickCount = 0;
  int excusedCount = 0;

  for (final agg in aggregates) {
    presentCount += agg.totalHadir;
    absentCount += agg.totalAlpha;
    sickCount += agg.totalSakit;
    excusedCount += agg.totalIzin;
  }

  final totalRecords = presentCount + absentCount + sickCount + excusedCount;
  final rawAttendanceRate = totalRecords > 0
      ? (presentCount / totalRecords * 100)
      : 0.0;
  final attendanceRate = rawAttendanceRate.clamp(0.0, 100.0);

  // Statistik berdasarkan gender
  int malePresentCount = 0;
  int maleAbsentCount = 0;
  int maleSickCount = 0;
  int maleExcusedCount = 0;

  int femalePresentCount = 0;
  int femaleAbsentCount = 0;
  int femaleSickCount = 0;
  int femaleExcusedCount = 0;

  // Group by user for summary
  final userAttendanceSummary = <String, Map<String, dynamic>>{};

  for (final user in users) {
    final userAggregate = aggregates
        .where((agg) => agg.userId == user.id)
        .firstOrNull;

    final userPresent = userAggregate?.totalHadir ?? 0;
    final userAbsent = userAggregate?.totalAlpha ?? 0;
    final userSick = userAggregate?.totalSakit ?? 0;
    final userExcused = userAggregate?.totalIzin ?? 0;

    final userTotal = userPresent + userAbsent + userSick + userExcused;
    final rawUserAttendanceRate = userTotal > 0
        ? (userPresent / userTotal * 100)
        : 0.0;
    final userAttendanceRate = rawUserAttendanceRate.clamp(0.0, 100.0);

    // Hitung berdasarkan gender
    final isMale =
        user.jenisKelamin?.toLowerCase() == 'laki-laki' ||
        user.jenisKelamin?.toLowerCase() == 'l' ||
        user.jenisKelamin?.toLowerCase() == 'male';

    if (isMale) {
      malePresentCount += userPresent;
      maleAbsentCount += userAbsent;
      maleSickCount += userSick;
      maleExcusedCount += userExcused;
    } else if (user.jenisKelamin != null) {
      femalePresentCount += userPresent;
      femaleAbsentCount += userAbsent;
      femaleSickCount += userSick;
      femaleExcusedCount += userExcused;
    }

    userAttendanceSummary[user.id] = {
      'user': user,
      'presentCount': userPresent,
      'absentCount': userAbsent,
      'sickCount': userSick,
      'excusedCount': userExcused,
      'totalRecords': userTotal,
      'attendanceRate': userAttendanceRate,
      'persentaseKehadiran': userAggregate?.persentaseKehadiran ?? 0.0,
      'totalPoin': userAggregate?.totalPoin ?? 0,
    };
  }

  // Hitung statistik gender
  final maleTotal =
      malePresentCount + maleAbsentCount + maleSickCount + maleExcusedCount;
  final femaleTotal =
      femalePresentCount +
      femaleAbsentCount +
      femaleSickCount +
      femaleExcusedCount;

  final maleAttendanceRate = maleTotal > 0
      ? (malePresentCount / maleTotal * 100)
      : 0.0;
  final femaleAttendanceRate = femaleTotal > 0
      ? (femalePresentCount / femaleTotal * 100)
      : 0.0;

  // Statistik performa
  final excellentCount = userAttendanceSummary.values
      .where((s) => (s['attendanceRate'] as double) >= 90)
      .length;
  final goodCount = userAttendanceSummary.values.where((s) {
    final rate = s['attendanceRate'] as double;
    return rate >= 80 && rate < 90;
  }).length;
  final fairCount = userAttendanceSummary.values.where((s) {
    final rate = s['attendanceRate'] as double;
    return rate >= 70 && rate < 80;
  }).length;
  final poorCount = userAttendanceSummary.values.where((s) {
    final rate = s['attendanceRate'] as double;
    return rate >= 60 && rate < 70;
  }).length;
  final criticalCount = userAttendanceSummary.values
      .where((s) => (s['attendanceRate'] as double) < 60)
      .length;

  // Top performers
  final sortedByRate = userAttendanceSummary.entries.toList()
    ..sort(
      (a, b) => (b.value['attendanceRate'] as double).compareTo(
        a.value['attendanceRate'] as double,
      ),
    );

  final topPerformers = sortedByRate
      .take(5)
      .map(
        (e) => {
          'user': e.value['user'],
          'attendanceRate': e.value['attendanceRate'],
          'totalRecords': e.value['totalRecords'],
        },
      )
      .toList();

  // Bottom performers
  final bottomPerformers = sortedByRate.reversed
      .take(5)
      .map(
        (e) => {
          'user': e.value['user'],
          'attendanceRate': e.value['attendanceRate'],
          'totalRecords': e.value['totalRecords'],
        },
      )
      .toList();

  return {
    'aggregates': aggregates,
    'users': users,
    'periode': periode,
    'periodeKey': periodeKey,
    'statistics': {
      'totalRecords': totalRecords,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'sickCount': sickCount,
      'excusedCount': excusedCount,
      'attendanceRate': attendanceRate,
      'totalSantri': users.length,
      'totalPoin': aggregates.fold<int>(0, (sum, agg) => sum + agg.totalPoin),
    },
    'genderStatistics': {
      'male': {
        'totalRecords': maleTotal,
        'presentCount': malePresentCount,
        'absentCount': maleAbsentCount,
        'sickCount': maleSickCount,
        'excusedCount': maleExcusedCount,
        'attendanceRate': maleAttendanceRate.clamp(0.0, 100.0),
        'count': users
            .where(
              (u) =>
                  u.jenisKelamin?.toLowerCase() == 'laki-laki' ||
                  u.jenisKelamin?.toLowerCase() == 'l' ||
                  u.jenisKelamin?.toLowerCase() == 'male',
            )
            .length,
      },
      'female': {
        'totalRecords': femaleTotal,
        'presentCount': femalePresentCount,
        'absentCount': femaleAbsentCount,
        'sickCount': femaleSickCount,
        'excusedCount': femaleExcusedCount,
        'attendanceRate': femaleAttendanceRate.clamp(0.0, 100.0),
        'count': users
            .where(
              (u) =>
                  u.jenisKelamin != null &&
                  u.jenisKelamin?.toLowerCase() != 'laki-laki' &&
                  u.jenisKelamin?.toLowerCase() != 'l' &&
                  u.jenisKelamin?.toLowerCase() != 'male',
            )
            .length,
      },
    },
    'performanceStatistics': {
      'excellent': excellentCount, // >= 90%
      'good': goodCount, // 80-89%
      'fair': fairCount, // 70-79%
      'poor': poorCount, // 60-69%
      'critical': criticalCount, // < 60%
    },
    'topPerformers': topPerformers,
    'bottomPerformers': bottomPerformers,
    'userSummary': userAttendanceSummary,
  };
}
