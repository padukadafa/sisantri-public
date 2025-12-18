import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/presensi_model.dart';

class PresensiStatsModel {
  final int totalHadir;
  final int totalTerlambat;
  final int totalAlpha;
  final double persentaseKehadiran;
  final String userId;
  final String userName;

  const PresensiStatsModel({
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalAlpha,
    required this.persentaseKehadiran,
    required this.userId,
    required this.userName,
  });

  int get totalPresensi => totalHadir + totalTerlambat + totalAlpha;
}

class PresensiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<PresensiModel>> getPresensiByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final jadwalSnapshot = await _firestore
          .collection('jadwal')
          .where(
            'tanggal',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('isAktif', isEqualTo: true)
          .get();

      final jadwalIds = jadwalSnapshot.docs.map((doc) => doc.id).toList();
      Query presensiQuery = _firestore
          .collection('presensi')
          .where('jadwalId', whereIn: jadwalIds.isNotEmpty ? jadwalIds : ['']);
      if (userId != null) {
        presensiQuery = presensiQuery.where('userId', isEqualTo: userId);
      }
      final presensiSnapshots = await presensiQuery.get();

      return presensiSnapshots.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PresensiModel.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('Error mengambil data presensi: $e');
    }
  }

  /// Get statistik presensi per santri
  static Future<List<PresensiStatsModel>> getPresensiStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final presensiList = await getPresensiByPeriod(
        startDate: startDate,
        endDate: endDate,
      );

      // Group by userId
      final Map<String, List<PresensiModel>> groupedPresensi = {};
      for (final presensi in presensiList) {
        if (!groupedPresensi.containsKey(presensi.userId)) {
          groupedPresensi[presensi.userId] = [];
        }
        groupedPresensi[presensi.userId]!.add(presensi);
      }

      // Calculate stats for each user
      final List<PresensiStatsModel> statsList = [];
      for (final entry in groupedPresensi.entries) {
        final userId = entry.key;
        final userPresensi = entry.value;

        final totalHadir = userPresensi
            .where((p) => p.status == StatusPresensi.hadir)
            .length;
        final totalTerlambat = userPresensi
            .where(
              (p) => p.status == StatusPresensi.izin,
            ) // Assuming 'terlambat' maps to 'izin' or similar, checking enum
            .length;
        final totalAlpha = userPresensi
            .where((p) => p.status == StatusPresensi.alpha)
            .length;
        final totalKegiatan = totalHadir + totalTerlambat + totalAlpha;
        final persentaseKehadiran = totalKegiatan > 0
            ? ((totalHadir + totalTerlambat) / totalKegiatan) * 100
            : 0.0;

        statsList.add(
          PresensiStatsModel(
            userId: userId,
            userName: userPresensi.first.userName,
            totalHadir: totalHadir,
            totalTerlambat: totalTerlambat,
            totalAlpha: totalAlpha,
            persentaseKehadiran: persentaseKehadiran,
          ),
        );
      }

      statsList.sort(
        (a, b) => b.persentaseKehadiran.compareTo(a.persentaseKehadiran),
      );

      return statsList;
    } catch (e) {
      throw Exception('Error menghitung statistik presensi: $e');
    }
  }

  static Future<List<PresensiModel>> getPresensiToday({String? userId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getPresensiByPeriod(
      startDate: startOfDay,
      endDate: endOfDay,
      userId: userId,
    );
  }

  static Future<PresensiModel?> getCurrentPresensi(String userId) async {
    final startDate = DateTime.now();
    final endDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      23,
      59,
      59,
    );

    final jadwalSnapshot = await _firestore
        .collection('jadwal')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('isAktif', isEqualTo: true)
        .get();

    if (jadwalSnapshot.docs.isEmpty) {
      return null;
    }

    jadwalSnapshot.docs.sort((a, b) {
      final dataA = a.data();
      final dataB = b.data();
      final timeA = dataA['waktuMulai'] as String;
      final timeB = dataB['waktuMulai'] as String;
      return timeA.compareTo(timeB);
    });

    final jadwalId = jadwalSnapshot.docs.first.id;

    final presensiSnapshot = await _firestore
        .collection('presensi')
        .where('jadwalId', isEqualTo: jadwalId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (presensiSnapshot.docs.isEmpty) {
      return null;
    }

    final doc = presensiSnapshot.docs.first;
    final data = doc.data();
    return PresensiModel.fromJson({'id': doc.id, ...data});
  }

  static Future<List<PresensiModel>> getPresensiThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getPresensiByPeriod(startDate: startDate, endDate: endDate);
  }

  /// Get presensi bulan ini
  static Future<List<PresensiModel>> getPresensiThisMonth() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getPresensiByPeriod(startDate: startDate, endDate: endDate);
  }

  /// Get ringkasan presensi untuk dashboard
  static Future<Map<String, dynamic>> getPresensiSummary() async {
    try {
      final today = await getPresensiToday();
      final thisWeek = await getPresensiThisWeek();

      final todayStats = _calculateDailyStats(today);
      final weeklyStats = _calculateDailyStats(thisWeek);

      return {
        'today': todayStats,
        'thisWeek': weeklyStats,
        'totalSantri': await _getTotalSantriCount(),
      };
    } catch (e) {
      throw Exception('Error mengambil ringkasan presensi: $e');
    }
  }

  /// Calculate daily stats
  static Map<String, dynamic> _calculateDailyStats(
    List<PresensiModel> presensiList,
  ) {
    final totalHadir = presensiList
        .where((p) => p.status == StatusPresensi.hadir)
        .length;
    final totalTerlambat = presensiList
        .where((p) => p.status == StatusPresensi.izin)
        .length;
    final totalAlpha = presensiList
        .where((p) => p.status == StatusPresensi.alpha)
        .length;
    final totalPresensi = totalHadir + totalTerlambat + totalAlpha;
    final persentaseKehadiran = totalPresensi > 0
        ? ((totalHadir + totalTerlambat) / totalPresensi) * 100
        : 0.0;

    return {
      'totalHadir': totalHadir,
      'totalTerlambat': totalTerlambat,
      'totalAlpha': totalAlpha,
      'totalPresensi': totalPresensi,
      'persentaseKehadiran': persentaseKehadiran,
    };
  }

  /// Get total santri count
  static Future<int> _getTotalSantriCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['santri', 'dewan_guru'])
          .where('statusAktif', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get aktivitas terbaru untuk dashboard
  static Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('presensi')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final presensi = PresensiModel.fromJson({'id': doc.id, ...data});

        return {
          'type': presensi.status,
          'message': _getActivityMessage(presensi),
          'time': _getTimeAgo(presensi.createdAt),
          'icon': _getActivityIcon(presensi.status.name),
          'color': _getActivityColor(presensi.status.name),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error mengambil aktivitas terbaru: $e');
    }
  }

  static String _getActivityMessage(PresensiModel presensi) {
    switch (presensi.status) {
      case StatusPresensi.hadir:
        return '${presensi.userName} melakukan presensi ${presensi.jadwalId}';
      case StatusPresensi.izin:
        return '${presensi.userName} izin ${presensi.jadwalId}';
      case StatusPresensi.alpha:
        return '${presensi.userName} tidak hadir ${presensi.jadwalId}';
      case StatusPresensi.sakit:
        return '${presensi.userName} sakit ${presensi.jadwalId}';
    }
  }

  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  static String _getActivityIcon(String status) {
    switch (status) {
      case 'hadir':
        return 'check_circle';
      case 'terlambat':
        return 'schedule';
      case 'alpha':
        return 'cancel';
      default:
        return 'info';
    }
  }

  static String _getActivityColor(String status) {
    switch (status) {
      case 'hadir':
        return 'green';
      case 'terlambat':
        return 'orange';
      case 'alpha':
        return 'red';
      default:
        return 'grey';
    }
  }
}
