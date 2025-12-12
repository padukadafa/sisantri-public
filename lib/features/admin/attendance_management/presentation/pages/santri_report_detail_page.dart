import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/models/santri_report_model.dart';
import 'package:sisantri/features/admin/attendance_management/providers/santri_report_providers.dart';
import 'package:fl_chart/fl_chart.dart';

class SantriReportDetailPage extends ConsumerWidget {
  final String userId;
  final String nama;

  const SantriReportDetailPage({
    super.key,
    required this.userId,
    required this.nama,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(santriReportProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text('Laporan Santri: $nama'), elevation: 0),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(santriReportProvider(userId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (report) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(context, report),
              const SizedBox(height: 16),
              _buildOverallStatsCard(report),
              const SizedBox(height: 16),
              _buildAttendanceBreakdownCard(report),
              const SizedBox(height: 16),
              _buildPerformanceCard(report),
              const SizedBox(height: 16),
              _buildMonthlyTrendCard(report),
              const SizedBox(height: 16),
              _buildDetailedStatsCard(report),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, SantriReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: report.fotoProfil != null
                  ? NetworkImage(report.fotoProfil!)
                  : null,
              child: report.fotoProfil == null
                  ? Text(
                      report.nama[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.nama,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (report.nim != null) ...[
                    const SizedBox(height: 4),
                    Text('NIM: ${report.nim}'),
                  ],
                  if (report.fakultas != null) ...[
                    const SizedBox(height: 4),
                    Text(report.fakultas!),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge('Level ${report.level}', Colors.purple),
                      const SizedBox(width: 8),
                      _buildBadge('${report.totalPoin} Poin', Colors.orange),
                      if (report.streakHarian > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge('🔥 ${report.streakHarian}', Colors.red),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard(SantriReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Keseluruhan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Persentase Kehadiran',
                    '${report.persentaseKehadiran.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Presensi',
                    '${report.totalPresensi}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tingkat Kedisiplinan',
                    '${report.tingkatKedisiplinan.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Kategori',
                    report.kategoriFrekuensi,
                    Icons.emoji_events,
                    _getKategoriColor(report.kategoriFrekuensi),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBreakdownCard(SantriReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breakdown Presensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(report),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          'Hadir',
                          report.totalHadir,
                          Colors.green,
                        ),
                        _buildLegendItem(
                          'Terlambat',
                          report.totalTerlambat,
                          Colors.orange,
                        ),
                        _buildLegendItem('Izin', report.totalIzin, Colors.blue),
                        _buildLegendItem(
                          'Sakit',
                          report.totalSakit,
                          Colors.purple,
                        ),
                        _buildLegendItem(
                          'Alpha',
                          report.totalAlpha,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(SantriReportModel report) {
    return [
      PieChartSectionData(
        value: report.totalHadir.toDouble(),
        title: '${report.totalHadir}',
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: report.totalTerlambat.toDouble(),
        title: '${report.totalTerlambat}',
        color: Colors.orange,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: report.totalIzin.toDouble(),
        title: '${report.totalIzin}',
        color: Colors.blue,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: report.totalSakit.toDouble(),
        title: '${report.totalSakit}',
        color: Colors.purple,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: report.totalAlpha.toDouble(),
        title: '${report.totalAlpha}',
        color: Colors.red,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: $value', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(SantriReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performa & Pencapaian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              'Level Progress',
              report.exp % 100,
              100,
              Colors.purple,
              '${report.exp % 100}/100 EXP',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'Streak Saat Ini',
                    '${report.streakHarian} hari',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'Max Streak',
                    '${report.maxStreak} hari',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    int current,
    int max,
    Color color,
    String valueText,
  ) {
    final percentage = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              valueText,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendCard(SantriReportModel report) {
    if (report.statsBulan == null || report.statsBulan!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ambil 6 bulan terakhir
    final entries = report.statsBulan!.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final recentMonths = entries.take(6).toList().reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tren Bulanan (6 Bulan Terakhir)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValueFromMonths(recentMonths) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < recentMonths.length) {
                            final periodeKey = recentMonths[value.toInt()].key;
                            final parts = periodeKey.split('-');
                            return Text(
                              '${parts[1]}/${parts[0].substring(2)}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(recentMonths),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('Hadir', Colors.green),
                const SizedBox(width: 16),
                _buildChartLegend('Terlambat', Colors.orange),
                const SizedBox(width: 16),
                _buildChartLegend('Alpha', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<MapEntry<String, PeriodeStats>> months,
  ) {
    return List.generate(months.length, (index) {
      final stats = months[index].value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stats.totalHadir.toDouble(),
            color: Colors.green,
            width: 8,
          ),
          BarChartRodData(
            toY: stats.totalTerlambat.toDouble(),
            color: Colors.orange,
            width: 8,
          ),
          BarChartRodData(
            toY: stats.totalAlpha.toDouble(),
            color: Colors.red,
            width: 8,
          ),
        ],
      );
    });
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getMaxValueFromMonths(List<MapEntry<String, PeriodeStats>> months) {
    double max = 0;
    for (var entry in months) {
      final stats = entry.value;
      final values = [
        stats.totalHadir.toDouble(),
        stats.totalTerlambat.toDouble(),
        stats.totalAlpha.toDouble(),
      ];
      final monthMax = values.reduce((a, b) => a > b ? a : b);
      if (monthMax > max) max = monthMax;
    }
    return max > 0 ? max : 10;
  }

  Widget _buildDetailedStatsCard(SantriReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Detail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Total Hadir',
              '${report.totalHadir}',
              Colors.green,
            ),
            _buildDetailRow(
              'Total Terlambat',
              '${report.totalTerlambat}',
              Colors.orange,
            ),
            _buildDetailRow('Total Izin', '${report.totalIzin}', Colors.blue),
            _buildDetailRow(
              'Total Sakit',
              '${report.totalSakit}',
              Colors.purple,
            ),
            _buildDetailRow('Total Alpha', '${report.totalAlpha}', Colors.red),
            const Divider(height: 24),
            _buildDetailRow(
              'Total Kehadiran',
              '${report.totalKehadiran}',
              Colors.teal,
              bold: true,
            ),
            _buildDetailRow(
              'Total Presensi',
              '${report.totalPresensi}',
              Colors.indigo,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'Sangat Baik':
        return Colors.green;
      case 'Baik':
        return Colors.lightGreen;
      case 'Cukup':
        return Colors.orange;
      case 'Kurang':
        return Colors.deepOrange;
      case 'Sangat Kurang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
