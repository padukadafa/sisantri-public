import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/presensi_model.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/services/presensi_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

/// Filter untuk laporan presensi
class AttendanceReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final String? status;

  const AttendanceReportFilter({
    this.startDate,
    this.endDate,
    this.userId,
    this.status,
  });

  AttendanceReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? status,
  }) {
    return AttendanceReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      status: status ?? this.status,
    );
  }
}

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
          // Default: bulan ini
          periode = 'monthly';
          periodeKey = PeriodeKeyHelper.monthly(DateTime.now());
        }

        // Ambil data aggregate
        final aggregateQuery = firestore
            .collection('presensi_aggregates')
            .where('periode', isEqualTo: periode)
            .where('periodeKey', isEqualTo: periodeKey);

        final aggregateSnapshot = await aggregateQuery.get();

        final aggregates = aggregateSnapshot.docs
            .map(
              (doc) => PresensiAggregateModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }),
            )
            .toList();

        // Filter by userId if specified
        var filteredAggregates = aggregates;
        if (filter.userId != null) {
          filteredAggregates = aggregates
              .where((agg) => agg.userId == filter.userId)
              .toList();
        }

        // Hitung statistik global dari aggregate
        int presentCount = 0;
        int absentCount = 0;
        int sickCount = 0;
        int excusedCount = 0;

        for (final agg in filteredAggregates) {
          presentCount += agg.totalHadir;
          absentCount += agg.totalAlpha;
          sickCount += agg.totalSakit;
          excusedCount += agg.totalIzin;
        }

        final totalRecords =
            presentCount + absentCount + sickCount + excusedCount;
        final rawAttendanceRate = totalRecords > 0
            ? (presentCount / totalRecords * 100)
            : 0.0;
        final attendanceRate = rawAttendanceRate.clamp(0.0, 100.0);

        // Buat summary per user dari aggregate
        final userAttendanceSummary = <String, Map<String, dynamic>>{};

        for (final user in users) {
          final userAggregate = filteredAggregates
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

          userAttendanceSummary[user.id] = {
            'user': user,
            'totalRecords': userTotal,
            'presentCount': userPresent,
            'absentCount': userAbsent,
            'sickCount': userSick,
            'excusedCount': userExcused,
            'attendanceRate': userAttendanceRate,
          };
        }

        // Untuk backward compatibility, jika perlu detail records
        // tetap ambil dari PresensiService (optional)
        List<PresensiModel> attendanceRecords = [];
        if (filter.startDate != null && filter.endDate != null) {
          attendanceRecords = await PresensiService.getPresensiByPeriod(
            startDate: filter.startDate!,
            endDate: filter.endDate!,
            userId: filter.userId,
          );

          if (filter.status != null) {
            attendanceRecords = attendanceRecords
                .where((record) => record.status.name == filter.status)
                .toList();
          }
        }

        return {
          'attendanceRecords': attendanceRecords,
          'aggregates': filteredAggregates,
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
          },
          'userSummary': userAttendanceSummary,
        };
      } catch (e) {
        throw Exception('Error loading attendance report: $e');
      }
    });

/// State provider untuk filter
final attendanceFilterProvider = StateProvider<AttendanceReportFilter>((ref) {
  return const AttendanceReportFilter();
});
