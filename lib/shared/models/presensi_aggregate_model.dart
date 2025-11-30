import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data agregasi presensi
class PresensiAggregateModel {
  final String id;
  final String userId;
  final String periode; // 'daily', 'weekly', 'monthly', 'semester', 'yearly'
  final String
  periodeKey; // Format: YYYY-MM-DD, YYYY-Www, YYYY-MM, YYYY-S1/S2, YYYY
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpha;
  final int totalPoin;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime lastUpdated;
  final Map<String, int>? detailPerJadwal; // Optional: breakdown per jadwal

  PresensiAggregateModel({
    required this.id,
    required this.userId,
    required this.periode,
    required this.periodeKey,
    required this.totalHadir,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpha,
    required this.totalPoin,
    required this.startDate,
    required this.endDate,
    required this.lastUpdated,
    this.detailPerJadwal,
  });

  int get totalPresensi => totalHadir + totalIzin + totalSakit + totalAlpha;

  double get persentaseKehadiran {
    if (totalPresensi == 0) return 0;
    return (totalHadir / totalPresensi) * 100;
  }

  factory PresensiAggregateModel.fromJson(Map<String, dynamic> json) {
    return PresensiAggregateModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      periode: json['periode'] as String,
      periodeKey: json['periodeKey'] as String,
      totalHadir: json['totalHadir'] as int? ?? 0,
      totalIzin: json['totalIzin'] as int? ?? 0,
      totalSakit: json['totalSakit'] as int? ?? 0,
      totalAlpha: json['totalAlpha'] as int? ?? 0,
      totalPoin: json['totalPoin'] as int? ?? 0,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      detailPerJadwal: json['detailPerJadwal'] != null
          ? Map<String, int>.from(json['detailPerJadwal'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'periode': periode,
      'periodeKey': periodeKey,
      'totalHadir': totalHadir,
      'totalIzin': totalIzin,
      'totalSakit': totalSakit,
      'totalAlpha': totalAlpha,
      'totalPoin': totalPoin,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      if (detailPerJadwal != null) 'detailPerJadwal': detailPerJadwal,
    };
  }

  PresensiAggregateModel copyWith({
    String? id,
    String? userId,
    String? periode,
    String? periodeKey,
    int? totalHadir,
    int? totalIzin,
    int? totalSakit,
    int? totalAlpha,
    int? totalPoin,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastUpdated,
    Map<String, int>? detailPerJadwal,
  }) {
    return PresensiAggregateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      periode: periode ?? this.periode,
      periodeKey: periodeKey ?? this.periodeKey,
      totalHadir: totalHadir ?? this.totalHadir,
      totalIzin: totalIzin ?? this.totalIzin,
      totalSakit: totalSakit ?? this.totalSakit,
      totalAlpha: totalAlpha ?? this.totalAlpha,
      totalPoin: totalPoin ?? this.totalPoin,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      detailPerJadwal: detailPerJadwal ?? this.detailPerJadwal,
    );
  }
}

/// Helper untuk generate periode key
class PeriodeKeyHelper {
  /// Format: YYYY-MM-DD
  static String daily(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format: YYYY-Www (ISO week number)
  static String weekly(DateTime date) {
    final weekNumber = _getISOWeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Format: YYYY-MM
  static String monthly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Format: YYYY-S1 atau YYYY-S2
  /// Semester 1: Jan-Jun, Semester 2: Jul-Des
  static String semester(DateTime date) {
    final semesterNum = date.month <= 6 ? 1 : 2;
    return '${date.year}-S$semesterNum';
  }

  /// Format: YYYY
  static String yearly(DateTime date) {
    return '${date.year}';
  }

  /// Get start date for periode
  static DateTime getStartDate(String periode, DateTime date) {
    switch (periode) {
      case 'daily':
        return DateTime(date.year, date.month, date.day);
      case 'weekly':
        return _getWeekStart(date);
      case 'monthly':
        return DateTime(date.year, date.month, 1);
      case 'semester':
        return date.month <= 6
            ? DateTime(date.year, 1, 1)
            : DateTime(date.year, 7, 1);
      case 'yearly':
        return DateTime(date.year, 1, 1);
      default:
        return date;
    }
  }

  /// Get end date for periode
  static DateTime getEndDate(String periode, DateTime date) {
    switch (periode) {
      case 'daily':
        return DateTime(date.year, date.month, date.day, 23, 59, 59);
      case 'weekly':
        return _getWeekStart(date).add(const Duration(days: 7));
      case 'monthly':
        return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      case 'semester':
        return date.month <= 6
            ? DateTime(date.year, 6, 30, 23, 59, 59)
            : DateTime(date.year, 12, 31, 23, 59, 59);
      case 'yearly':
        return DateTime(date.year, 12, 31, 23, 59, 59);
      default:
        return date;
    }
  }

  static int _getISOWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
