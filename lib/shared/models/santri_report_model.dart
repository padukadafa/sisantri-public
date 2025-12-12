/// Model untuk laporan detail per santri menggunakan aggregates
class SantriReportModel {
  final String userId;
  final String nama;
  final String? nim;
  final String? fakultas;
  final String? fotoProfil;
  final bool statusAktif;

  // Data dari users collection
  final int totalPoin;
  final int level;
  final int exp;
  final int streakHarian;
  final int maxStreak;

  // Data agregasi dari aggregates collection
  final int totalHadir;
  final int totalTerlambat;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpha;
  final double persentaseKehadiran;

  // Data per periode
  final Map<String, PeriodeStats>? statsBulan; // Monthly stats
  final Map<String, PeriodeStats>? statsMingguan; // Weekly stats

  SantriReportModel({
    required this.userId,
    required this.nama,
    this.nim,
    this.fakultas,
    this.fotoProfil,
    required this.statusAktif,
    required this.totalPoin,
    required this.level,
    required this.exp,
    required this.streakHarian,
    required this.maxStreak,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpha,
    required this.persentaseKehadiran,
    this.statsBulan,
    this.statsMingguan,
  });

  int get totalKehadiran =>
      totalHadir + totalTerlambat + totalIzin + totalSakit;
  int get totalPresensi =>
      totalHadir + totalTerlambat + totalIzin + totalSakit + totalAlpha;

  double get tingkatKedisiplinan {
    if (totalPresensi == 0) return 0;
    // Hadir penuh = 100%, terlambat = 80%, izin/sakit = 60%, alpha = 0%
    final score =
        (totalHadir * 100) +
        (totalTerlambat * 80) +
        (totalIzin * 60) +
        (totalSakit * 60);
    return (score / (totalPresensi * 100)) * 100;
  }

  String get kategoriFrekuensi {
    if (persentaseKehadiran >= 90) return 'Sangat Baik';
    if (persentaseKehadiran >= 80) return 'Baik';
    if (persentaseKehadiran >= 70) return 'Cukup';
    if (persentaseKehadiran >= 60) return 'Kurang';
    return 'Sangat Kurang';
  }

  factory SantriReportModel.fromUserAndAggregates({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> aggregates,
  }) {
    // Hitung total dari semua aggregates
    int totalHadir = 0;
    int totalTerlambat = 0;
    int totalIzin = 0;
    int totalSakit = 0;
    int totalAlpha = 0;

    Map<String, PeriodeStats> statsBulan = {};
    Map<String, PeriodeStats> statsMingguan = {};

    for (var agg in aggregates) {
      totalHadir += (agg['totalHadir'] as int? ?? 0);
      totalTerlambat += (agg['totalTerlambat'] as int? ?? 0);
      totalIzin += (agg['totalIzin'] as int? ?? 0);
      totalSakit += (agg['totalSakit'] as int? ?? 0);
      totalAlpha += (agg['totalAlpha'] as int? ?? 0);

      final periode = agg['periode'] as String;
      final periodeKey = agg['periodeKey'] as String;

      final stats = PeriodeStats(
        periodeKey: periodeKey,
        totalHadir: agg['totalHadir'] as int? ?? 0,
        totalTerlambat: agg['totalTerlambat'] as int? ?? 0,
        totalIzin: agg['totalIzin'] as int? ?? 0,
        totalSakit: agg['totalSakit'] as int? ?? 0,
        totalAlpha: agg['totalAlpha'] as int? ?? 0,
        totalPoin: agg['totalPoin'] as int? ?? 0,
      );

      if (periode == 'monthly') {
        statsBulan[periodeKey] = stats;
      } else if (periode == 'weekly') {
        statsMingguan[periodeKey] = stats;
      }
    }

    final totalPresensi =
        totalHadir + totalTerlambat + totalIzin + totalSakit + totalAlpha;
    final persentaseKehadiran = totalPresensi > 0
        ? ((totalHadir + totalTerlambat) / totalPresensi) * 100
        : 0.0;

    return SantriReportModel(
      userId: userData['id'] as String,
      nama: userData['nama'] as String,
      nim: userData['nim'] as String?,
      fakultas: userData['fakultas'] as String?,
      fotoProfil: userData['fotoProfil'] as String?,
      statusAktif: userData['statusAktif'] as bool? ?? true,
      totalPoin: userData['poin'] as int? ?? 0,
      level: userData['level'] as int? ?? 1,
      exp: userData['exp'] as int? ?? 0,
      streakHarian: userData['streakHarian'] as int? ?? 0,
      maxStreak: userData['maxStreak'] as int? ?? 0,
      totalHadir: totalHadir,
      totalTerlambat: totalTerlambat,
      totalIzin: totalIzin,
      totalSakit: totalSakit,
      totalAlpha: totalAlpha,
      persentaseKehadiran: persentaseKehadiran,
      statsBulan: statsBulan,
      statsMingguan: statsMingguan,
    );
  }
}

/// Model untuk statistik per periode
class PeriodeStats {
  final String periodeKey;
  final int totalHadir;
  final int totalTerlambat;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpha;
  final int totalPoin;

  PeriodeStats({
    required this.periodeKey,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpha,
    required this.totalPoin,
  });

  int get totalKehadiran =>
      totalHadir + totalTerlambat + totalIzin + totalSakit;
  int get totalPresensi =>
      totalHadir + totalTerlambat + totalIzin + totalSakit + totalAlpha;

  double get persentaseKehadiran {
    if (totalPresensi == 0) return 0;
    return ((totalHadir + totalTerlambat) / totalPresensi) * 100;
  }
}
