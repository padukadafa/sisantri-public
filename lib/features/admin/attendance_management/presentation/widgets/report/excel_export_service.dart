import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'attendance_report_provider.dart';

/// Service untuk export laporan presensi ke Excel dengan format yang informatif dan rapi
class ExcelExportService {
  /// Generate nama file Excel
  static String _generateFileName(AttendanceReportFilter filter) {
    final dateFormat = DateFormat('yyyyMMdd');
    final now = DateTime.now();

    String periodStr = 'all';
    if (filter.startDate != null && filter.endDate != null) {
      periodStr =
          '${dateFormat.format(filter.startDate!)}_${dateFormat.format(filter.endDate!)}';
    }

    return 'laporan_presensi_${periodStr}_${dateFormat.format(now)}.xlsx';
  }

  /// Export laporan presensi ke Excel
  static Future<String> exportToExcel({
    required Map<String, dynamic> reportData,
    required AttendanceReportFilter filter,
  }) async {
    // Request storage permission untuk Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          throw Exception('Storage permission not granted');
        }
      }
    }

    // Buat Excel file
    final excel = excel_lib.Excel.createExcel();

    final statistics = reportData['statistics'] as Map<String, dynamic>;
    final aggregates = reportData['aggregates'] as List<PresensiAggregateModel>;
    final users = reportData['users'] as List<UserModel>;
    final userSummary =
        reportData['userSummary'] as Map<String, Map<String, dynamic>>;
    final periode = reportData['periode'] as String;
    final periodeKey = reportData['periodeKey'] as String;
    final genderStats = reportData['genderStatistics'] as Map<String, dynamic>?;
    final performanceStats =
        reportData['performanceStatistics'] as Map<String, dynamic>?;
    final topPerformers = reportData['topPerformers'] as List<dynamic>?;
    final bottomPerformers = reportData['bottomPerformers'] as List<dynamic>?;

    // Buat sheets
    final summarySheet = excel['Ringkasan'];
    final aggregateSheet = excel['Data Agregat'];
    final santriSheet = excel['Per Santri'];

    _createSummarySheet(summarySheet, statistics, filter, periode, periodeKey);

    // Buat gender sheet jika ada data
    if (genderStats != null) {
      final genderSheet = excel['Analisis Gender'];
      _createGenderAnalysisSheet(genderSheet, genderStats, statistics);
    }

    // Buat performance sheet jika ada data
    if (performanceStats != null) {
      final performanceSheet = excel['Analisis Performa'];
      _createPerformanceAnalysisSheet(
        performanceSheet,
        performanceStats,
        topPerformers ?? [],
        bottomPerformers ?? [],
      );
    }

    _createAggregateSheet(aggregateSheet, aggregates, users);
    _createSantriSummarySheet(santriSheet, userSummary);

    // Tentukan directory untuk menyimpan file
    Directory? directory;

    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        directory = publicDownloads;
      } else {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Downloads');
        }
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final fileName = _generateFileName(filter);
    final filePath = directory != null
        ? '${directory.path}/$fileName'
        : fileName;

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);

      // Pastikan directory exists
      await file.parent.create(recursive: true);

      // Tulis file
      await file.writeAsBytes(fileBytes);

      // Verify file created
      if (await file.exists()) {
        await file.length();
      } else {
        throw Exception('File was not created after writing');
      }
    } else {
      throw Exception('Failed to generate Excel file bytes');
    }

    return filePath;
  }

  /// Buka file Excel yang sudah di-export
  static Future<void> openExportedFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      throw Exception('Failed to open file: $e');
    }
  }

  /// Buat sheet ringkasan dengan statistik lengkap
  static void _createSummarySheet(
    excel_lib.Sheet sheet,
    Map<String, dynamic> stats,
    AttendanceReportFilter filter,
    String periode,
    String periodeKey,
  ) {
    int row = 0;

    // === HEADER ===
    _setCell(sheet, row, 0, 'LAPORAN RINGKASAN PRESENSI SANTRI', bold: true);
    row++;
    _setCell(
      sheet,
      row,
      0,
      'Tanggal Cetak: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}',
    );
    row += 2;

    // === INFORMASI PERIODE ===
    _setCell(sheet, row, 0, 'INFORMASI PERIODE', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Periode:', bold: true);
    if (filter.startDate != null && filter.endDate != null) {
      _setCell(
        sheet,
        row,
        1,
        '${DateFormat('dd MMMM yyyy', 'id_ID').format(filter.startDate!)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(filter.endDate!)}',
      );
    } else {
      _setCell(sheet, row, 1, 'Semua Data');
    }
    row++;

    _setCell(sheet, row, 0, 'Tipe Periode:', bold: true);
    _setCell(sheet, row, 1, periode);
    row++;

    _setCell(sheet, row, 0, 'Periode Key:', bold: true);
    _setCell(sheet, row, 1, periodeKey);
    row++;

    if (filter.status != null) {
      _setCell(sheet, row, 0, 'Filter Status:', bold: true);
      _setCell(sheet, row, 1, filter.status!);
      row++;
    }
    row++;

    // === STATISTIK KESELURUHAN ===
    _setCell(sheet, row, 0, 'STATISTIK KESELURUHAN', bold: true);
    row++;

    // Header tabel
    _setCell(sheet, row, 0, 'Keterangan', bold: true);
    _setCell(sheet, row, 1, 'Jumlah', bold: true);
    _setCell(sheet, row, 2, 'Persentase', bold: true);
    row++;

    // Data statistik
    final totalRecords = stats['totalRecords'] as int;
    final presentCount = stats['presentCount'] as int;
    final sickCount = stats['sickCount'] as int;
    final excusedCount = stats['excusedCount'] as int;
    final absentCount = stats['absentCount'] as int;

    _setCell(sheet, row, 0, 'Total Presensi', bold: true);
    _setCell(sheet, row, 1, totalRecords.toString());
    _setCell(sheet, row, 2, '100.0%');
    row++;

    _setCell(sheet, row, 0, '✓ Hadir');
    _setCell(sheet, row, 1, presentCount.toString());
    _setCell(
      sheet,
      row,
      2,
      totalRecords > 0
          ? '${(presentCount / totalRecords * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '⚕ Sakit');
    _setCell(sheet, row, 1, sickCount.toString());
    _setCell(
      sheet,
      row,
      2,
      totalRecords > 0
          ? '${(sickCount / totalRecords * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, 'ℹ Izin');
    _setCell(sheet, row, 1, excusedCount.toString());
    _setCell(
      sheet,
      row,
      2,
      totalRecords > 0
          ? '${(excusedCount / totalRecords * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '✗ Alpha');
    _setCell(sheet, row, 1, absentCount.toString());
    _setCell(
      sheet,
      row,
      2,
      totalRecords > 0
          ? '${(absentCount / totalRecords * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row += 2;

    // Tingkat kehadiran
    _setCell(sheet, row, 0, 'TINGKAT KEHADIRAN:', bold: true);
    _setCell(
      sheet,
      row,
      1,
      '${stats['attendanceRate'].toStringAsFixed(1)}%',
      bold: true,
    );
    row += 2;

    // Informasi tambahan
    _setCell(sheet, row, 0, 'Total Santri:', bold: true);
    _setCell(sheet, row, 1, stats['totalSantri'].toString());
    row++;

    _setCell(sheet, row, 0, 'Total Poin:', bold: true);
    _setCell(sheet, row, 1, stats['totalPoin'].toString());

    // Set column widths
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
  }

  /// Buat sheet analisis gender
  static void _createGenderAnalysisSheet(
    excel_lib.Sheet sheet,
    Map<String, dynamic> genderStats,
    Map<String, dynamic> overallStats,
  ) {
    int row = 0;

    // === HEADER ===
    _setCell(sheet, row, 0, 'ANALISIS PRESENSI BERDASARKAN GENDER', bold: true);
    row += 2;

    final maleStats = genderStats['male'] as Map<String, dynamic>;
    final femaleStats = genderStats['female'] as Map<String, dynamic>;

    // === RINGKASAN ===
    _setCell(sheet, row, 0, 'RINGKASAN GENDER', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Gender', bold: true);
    _setCell(sheet, row, 1, 'Jumlah Santri', bold: true);
    _setCell(sheet, row, 2, 'Total Presensi', bold: true);
    _setCell(sheet, row, 3, 'Tingkat Kehadiran', bold: true);
    row++;

    // Laki-laki
    _setCell(sheet, row, 0, '👨 Laki-laki');
    _setCell(sheet, row, 1, maleStats['count'].toString());
    _setCell(sheet, row, 2, maleStats['totalRecords'].toString());
    _setCell(
      sheet,
      row,
      3,
      '${maleStats['attendanceRate'].toStringAsFixed(1)}%',
      bold: true,
    );
    row++;

    // Perempuan
    _setCell(sheet, row, 0, '👩 Perempuan');
    _setCell(sheet, row, 1, femaleStats['count'].toString());
    _setCell(sheet, row, 2, femaleStats['totalRecords'].toString());
    _setCell(
      sheet,
      row,
      3,
      '${femaleStats['attendanceRate'].toStringAsFixed(1)}%',
      bold: true,
    );
    row += 2;

    // === DETAIL LAKI-LAKI ===
    _setCell(sheet, row, 0, 'DETAIL LAKI-LAKI', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Status', bold: true);
    _setCell(sheet, row, 1, 'Jumlah', bold: true);
    _setCell(sheet, row, 2, 'Persentase', bold: true);
    row++;

    final maleTotal = maleStats['totalRecords'] as int;

    _setCell(sheet, row, 0, '✓ Hadir');
    _setCell(sheet, row, 1, maleStats['presentCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      maleTotal > 0
          ? '${(maleStats['presentCount'] / maleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '⚕ Sakit');
    _setCell(sheet, row, 1, maleStats['sickCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      maleTotal > 0
          ? '${(maleStats['sickCount'] / maleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, 'ℹ Izin');
    _setCell(sheet, row, 1, maleStats['excusedCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      maleTotal > 0
          ? '${(maleStats['excusedCount'] / maleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '✗ Alpha');
    _setCell(sheet, row, 1, maleStats['absentCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      maleTotal > 0
          ? '${(maleStats['absentCount'] / maleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row += 2;

    // === DETAIL PEREMPUAN ===
    _setCell(sheet, row, 0, 'DETAIL PEREMPUAN', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Status', bold: true);
    _setCell(sheet, row, 1, 'Jumlah', bold: true);
    _setCell(sheet, row, 2, 'Persentase', bold: true);
    row++;

    final femaleTotal = femaleStats['totalRecords'] as int;

    _setCell(sheet, row, 0, '✓ Hadir');
    _setCell(sheet, row, 1, femaleStats['presentCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      femaleTotal > 0
          ? '${(femaleStats['presentCount'] / femaleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '⚕ Sakit');
    _setCell(sheet, row, 1, femaleStats['sickCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      femaleTotal > 0
          ? '${(femaleStats['sickCount'] / femaleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, 'ℹ Izin');
    _setCell(sheet, row, 1, femaleStats['excusedCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      femaleTotal > 0
          ? '${(femaleStats['excusedCount'] / femaleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    _setCell(sheet, row, 0, '✗ Alpha');
    _setCell(sheet, row, 1, femaleStats['absentCount'].toString());
    _setCell(
      sheet,
      row,
      2,
      femaleTotal > 0
          ? '${(femaleStats['absentCount'] / femaleTotal * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row += 2;

    // === PERBANDINGAN ===
    _setCell(sheet, row, 0, 'PERBANDINGAN', bold: true);
    row++;

    final maleRate = maleStats['attendanceRate'] as double;
    final femaleRate = femaleStats['attendanceRate'] as double;
    final difference = (maleRate - femaleRate).abs();
    final better = maleRate > femaleRate ? 'Laki-laki' : 'Perempuan';

    _setCell(sheet, row, 0, 'Selisih Kehadiran:');
    _setCell(sheet, row, 1, '${difference.toStringAsFixed(1)}%');
    row++;

    _setCell(sheet, row, 0, 'Kehadiran Lebih Baik:');
    _setCell(sheet, row, 1, better, bold: true);

    // Set column widths
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
  }

  /// Buat sheet analisis performa
  static void _createPerformanceAnalysisSheet(
    excel_lib.Sheet sheet,
    Map<String, dynamic> performanceStats,
    List<dynamic> topPerformers,
    List<dynamic> bottomPerformers,
  ) {
    int row = 0;

    // === HEADER ===
    _setCell(sheet, row, 0, 'ANALISIS PERFORMA SANTRI', bold: true);
    row += 2;

    // === DISTRIBUSI PERFORMA ===
    _setCell(sheet, row, 0, 'DISTRIBUSI PERFORMA', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Kategori', bold: true);
    _setCell(sheet, row, 1, 'Range', bold: true);
    _setCell(sheet, row, 2, 'Jumlah Santri', bold: true);
    _setCell(sheet, row, 3, 'Persentase', bold: true);
    row++;

    final totalSantri = performanceStats.values.fold<int>(
      0,
      (sum, val) => sum + (val as int),
    );

    // Excellent
    _setCell(sheet, row, 0, '⭐ Excellent');
    _setCell(sheet, row, 1, '≥ 90%');
    _setCell(sheet, row, 2, performanceStats['excellent'].toString());
    _setCell(
      sheet,
      row,
      3,
      totalSantri > 0
          ? '${(performanceStats['excellent'] / totalSantri * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    // Good
    _setCell(sheet, row, 0, '✓ Baik');
    _setCell(sheet, row, 1, '80-89%');
    _setCell(sheet, row, 2, performanceStats['good'].toString());
    _setCell(
      sheet,
      row,
      3,
      totalSantri > 0
          ? '${(performanceStats['good'] / totalSantri * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    // Fair
    _setCell(sheet, row, 0, '○ Cukup');
    _setCell(sheet, row, 1, '70-79%');
    _setCell(sheet, row, 2, performanceStats['fair'].toString());
    _setCell(
      sheet,
      row,
      3,
      totalSantri > 0
          ? '${(performanceStats['fair'] / totalSantri * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    // Poor
    _setCell(sheet, row, 0, '△ Kurang');
    _setCell(sheet, row, 1, '60-69%');
    _setCell(sheet, row, 2, performanceStats['poor'].toString());
    _setCell(
      sheet,
      row,
      3,
      totalSantri > 0
          ? '${(performanceStats['poor'] / totalSantri * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row++;

    // Critical
    _setCell(sheet, row, 0, '✗ Perlu Perhatian');
    _setCell(sheet, row, 1, '< 60%');
    _setCell(sheet, row, 2, performanceStats['critical'].toString());
    _setCell(
      sheet,
      row,
      3,
      totalSantri > 0
          ? '${(performanceStats['critical'] / totalSantri * 100).toStringAsFixed(1)}%'
          : '0.0%',
    );
    row += 2;

    // === TOP 5 PERFORMERS ===
    _setCell(sheet, row, 0, 'TOP 5 SANTRI TERBAIK', bold: true);
    row++;

    _setCell(sheet, row, 0, 'Peringkat', bold: true);
    _setCell(sheet, row, 1, 'Nama', bold: true);
    _setCell(sheet, row, 2, 'Tingkat Kehadiran', bold: true);
    _setCell(sheet, row, 3, 'Total Presensi', bold: true);
    row++;

    for (int i = 0; i < topPerformers.length; i++) {
      final performer = topPerformers[i] as Map<String, dynamic>;
      final user = performer['user'] as UserModel;

      _setCell(sheet, row, 0, '${i + 1}');
      _setCell(sheet, row, 1, user.nama);
      _setCell(
        sheet,
        row,
        2,
        '${(performer['attendanceRate'] as double).toStringAsFixed(1)}%',
      );
      _setCell(sheet, row, 3, performer['totalRecords'].toString());
      row++;
    }
    row++;

    // === BOTTOM 5 PERFORMERS ===
    _setCell(sheet, row, 0, 'SANTRI YANG PERLU PERHATIAN', bold: true);
    row++;

    _setCell(sheet, row, 0, 'No', bold: true);
    _setCell(sheet, row, 1, 'Nama', bold: true);
    _setCell(sheet, row, 2, 'Tingkat Kehadiran', bold: true);
    _setCell(sheet, row, 3, 'Total Presensi', bold: true);
    row++;

    for (int i = 0; i < bottomPerformers.length; i++) {
      final performer = bottomPerformers[i] as Map<String, dynamic>;
      final user = performer['user'] as UserModel;

      _setCell(sheet, row, 0, '${i + 1}');
      _setCell(sheet, row, 1, user.nama);
      _setCell(
        sheet,
        row,
        2,
        '${(performer['attendanceRate'] as double).toStringAsFixed(1)}%',
      );
      _setCell(sheet, row, 3, performer['totalRecords'].toString());
      row++;
    }

    // Set column widths
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 15);
  }

  /// Buat sheet data agregat presensi
  static void _createAggregateSheet(
    excel_lib.Sheet sheet,
    List<PresensiAggregateModel> aggregates,
    List<UserModel> users,
  ) {
    int row = 0;

    // === HEADER ===
    _setCell(sheet, row, 0, 'DATA AGREGAT PRESENSI', bold: true);
    row++;
    _setCell(sheet, row, 0, 'Total ${aggregates.length} data agregat');
    row += 2;

    // === TABLE HEADERS ===
    _setCell(sheet, row, 0, 'No', bold: true);
    _setCell(sheet, row, 1, 'Nama Santri', bold: true);
    _setCell(sheet, row, 2, 'Periode', bold: true);
    _setCell(sheet, row, 3, 'Hadir', bold: true);
    _setCell(sheet, row, 4, 'Izin', bold: true);
    _setCell(sheet, row, 5, 'Sakit', bold: true);
    _setCell(sheet, row, 6, 'Alpha', bold: true);
    _setCell(sheet, row, 7, 'Total', bold: true);
    _setCell(sheet, row, 8, 'Kehadiran %', bold: true);
    _setCell(sheet, row, 9, 'Total Poin', bold: true);
    row++;

    // === DATA ROWS ===
    for (int i = 0; i < aggregates.length; i++) {
      final agg = aggregates[i];
      final user = users.firstWhere(
        (u) => u.id == agg.userId,
        orElse: () =>
            UserModel(id: '', nama: 'Unknown', email: '', role: 'santri'),
      );

      final total =
          agg.totalHadir + agg.totalIzin + agg.totalSakit + agg.totalAlpha;

      _setCell(sheet, row, 0, (i + 1).toString());
      _setCell(sheet, row, 1, user.nama);
      _setCell(sheet, row, 2, '${agg.periode} - ${agg.periodeKey}');
      _setCell(sheet, row, 3, agg.totalHadir.toString());
      _setCell(sheet, row, 4, agg.totalIzin.toString());
      _setCell(sheet, row, 5, agg.totalSakit.toString());
      _setCell(sheet, row, 6, agg.totalAlpha.toString());
      _setCell(sheet, row, 7, total.toString());
      _setCell(sheet, row, 8, '${agg.persentaseKehadiran.toStringAsFixed(1)}%');
      _setCell(sheet, row, 9, agg.totalPoin.toString());

      row++;
    }

    // Set column widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 10);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 10);
    sheet.setColumnWidth(7, 10);
    sheet.setColumnWidth(8, 12);
    sheet.setColumnWidth(9, 12);
  }

  /// Buat sheet ringkasan per santri
  static void _createSantriSummarySheet(
    excel_lib.Sheet sheet,
    Map<String, Map<String, dynamic>> userSummary,
  ) {
    int row = 0;

    // === HEADER ===
    _setCell(sheet, row, 0, 'RINGKASAN PER SANTRI', bold: true);
    row++;
    _setCell(sheet, row, 0, 'Total ${userSummary.length} santri');
    row += 2;

    // === TABLE HEADERS ===
    _setCell(sheet, row, 0, 'No', bold: true);
    _setCell(sheet, row, 1, 'Nama Santri', bold: true);
    _setCell(sheet, row, 2, 'Hadir', bold: true);
    _setCell(sheet, row, 3, 'Izin', bold: true);
    _setCell(sheet, row, 4, 'Sakit', bold: true);
    _setCell(sheet, row, 5, 'Alpha', bold: true);
    _setCell(sheet, row, 6, 'Total', bold: true);
    _setCell(sheet, row, 7, 'Tingkat Kehadiran', bold: true);
    row++;

    // === DATA ROWS ===
    int no = 1;
    for (final entry in userSummary.entries) {
      final summary = entry.value;
      final user = summary['user'] as UserModel;

      _setCell(sheet, row, 0, no.toString());
      _setCell(sheet, row, 1, user.nama);
      _setCell(sheet, row, 2, summary['presentCount'].toString());
      _setCell(sheet, row, 3, summary['excusedCount'].toString());
      _setCell(sheet, row, 4, summary['sickCount'].toString());
      _setCell(sheet, row, 5, summary['absentCount'].toString());
      _setCell(sheet, row, 6, summary['totalRecords'].toString());
      _setCell(
        sheet,
        row,
        7,
        '${summary['attendanceRate'].toStringAsFixed(1)}%',
      );

      row++;
      no++;
    }

    // Set column widths
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 10);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 10);
    sheet.setColumnWidth(7, 16);
  }

  /// Helper method untuk set cell value dengan styling sederhana
  static void _setCell(
    excel_lib.Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
  }) {
    final cell = sheet.cell(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = excel_lib.TextCellValue(value);

    if (bold) {
      cell.cellStyle = excel_lib.CellStyle(bold: true);
    }
  }
}
