import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Provider untuk statistics data
final statisticsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String>>((
      ref,
      params,
    ) async {
      final periode = params['periode'] ?? 'monthly';
      final periodeKey =
          params['periodeKey'] ?? PeriodeKeyHelper.monthly(DateTime.now());

      try {
        return await PresensiAggregateService.getStatistics(
          periode: periode,
          periodeKey: periodeKey,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Return empty data on timeout
            return {
              'totalUsers': 0,
              'totalHadir': 0,
              'totalIzin': 0,
              'totalSakit': 0,
              'totalAlpha': 0,
              'totalPoin': 0,
              'totalPresensi': 0,
              'persentaseKehadiran': 0.0,
            };
          },
        );
      } catch (e) {
        // Return empty data on error
        return {
          'totalUsers': 0,
          'totalHadir': 0,
          'totalIzin': 0,
          'totalSakit': 0,
          'totalAlpha': 0,
          'totalPoin': 0,
          'totalPresensi': 0,
          'persentaseKehadiran': 0.0,
        };
      }
    });

/// Halaman Admin Statistics Dashboard
class AdminStatisticsPage extends ConsumerStatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  ConsumerState<AdminStatisticsPage> createState() =>
      _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends ConsumerState<AdminStatisticsPage> {
  String _selectedPeriode = 'monthly';

  @override
  Widget build(BuildContext context) {
    final periodeKey = _getPeriodeKey(_selectedPeriode);
    final statisticsAsync = ref.watch(
      statisticsProvider({
        'periode': _selectedPeriode,
        'periodeKey': periodeKey,
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Presensi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedPeriode,
            onSelected: (value) {
              setState(() {
                _selectedPeriode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'daily', child: Text('Hari Ini')),
              const PopupMenuItem(value: 'weekly', child: Text('Minggu Ini')),
              const PopupMenuItem(value: 'monthly', child: Text('Bulan Ini')),
              const PopupMenuItem(
                value: 'semester',
                child: Text('Semester Ini'),
              ),
              const PopupMenuItem(value: 'yearly', child: Text('Tahun Ini')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(statisticsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(statisticsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(statisticsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getPeriodeLabel(_selectedPeriode),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        periodeKey,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Users',
                        '${stats['totalUsers']}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Poin',
                        '${stats['totalPoin']}',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Presensi',
                        '${stats['totalPresensi']}',
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Kehadiran',
                        '${stats['persentaseKehadiran'].toStringAsFixed(1)}%',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Status breakdown
                _buildStatusBreakdown(stats),

                const SizedBox(height: 24),

                // Pie Chart
                _buildPieChart(stats),

                const SizedBox(height: 24),

                // Bar Chart
                _buildBarChart(stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Status Presensi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Hadir',
            stats['totalHadir'],
            Colors.green,
            Icons.check_circle,
          ),
          const Divider(height: 24),
          _buildStatusRow(
            'Izin',
            stats['totalIzin'],
            Colors.orange,
            Icons.info,
          ),
          const Divider(height: 24),
          _buildStatusRow(
            'Sakit',
            stats['totalSakit'],
            Colors.blue,
            Icons.local_hospital,
          ),
          const Divider(height: 24),
          _buildStatusRow(
            'Alpha',
            stats['totalAlpha'],
            Colors.red,
            Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, dynamic> stats) {
    final totalHadir = stats['totalHadir'] as int;
    final totalIzin = stats['totalIzin'] as int;
    final totalSakit = stats['totalSakit'] as int;
    final totalAlpha = stats['totalAlpha'] as int;

    final total = totalHadir + totalIzin + totalSakit + totalAlpha;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalHadir.toDouble(),
                    title: '${(totalHadir / total * 100).toStringAsFixed(1)}%',
                    color: Colors.green,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: totalIzin.toDouble(),
                    title: '${(totalIzin / total * 100).toStringAsFixed(1)}%',
                    color: Colors.orange,
                    radius: 75,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: totalSakit.toDouble(),
                    title: '${(totalSakit / total * 100).toStringAsFixed(1)}%',
                    color: Colors.blue,
                    radius: 75,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: totalAlpha.toDouble(),
                    title: '${(totalAlpha / total * 100).toStringAsFixed(1)}%',
                    color: Colors.red,
                    radius: 75,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('Hadir', Colors.green),
              _buildLegend('Izin', Colors.orange),
              _buildLegend('Sakit', Colors.blue),
              _buildLegend('Alpha', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> stats) {
    final totalHadir = stats['totalHadir'] as int;
    final totalIzin = stats['totalIzin'] as int;
    final totalSakit = stats['totalSakit'] as int;
    final totalAlpha = stats['totalAlpha'] as int;

    final maxValue = [
      totalHadir,
      totalIzin,
      totalSakit,
      totalAlpha,
    ].reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perbandingan Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxValue > 0 ? maxValue * 1.2 : 10,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalHadir.toDouble(),
                        color: Colors.green,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalIzin.toDouble(),
                        color: Colors.orange,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: totalSakit.toDouble(),
                        color: Colors.blue,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: totalAlpha.toDouble(),
                        color: Colors.red,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Hadir', 'Izin', 'Sakit', 'Alpha'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 5 : 2,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  String _getPeriodeLabel(String periode) {
    switch (periode) {
      case 'daily':
        return 'Statistik Hari Ini';
      case 'weekly':
        return 'Statistik Minggu Ini';
      case 'monthly':
        return 'Statistik Bulan Ini';
      case 'semester':
        return 'Statistik Semester Ini';
      case 'yearly':
        return 'Statistik Tahun Ini';
      default:
        return 'Statistik';
    }
  }

  String _getPeriodeKey(String periode) {
    final now = DateTime.now();
    switch (periode) {
      case 'daily':
        return PeriodeKeyHelper.daily(now);
      case 'weekly':
        return PeriodeKeyHelper.weekly(now);
      case 'monthly':
        return PeriodeKeyHelper.monthly(now);
      case 'semester':
        return PeriodeKeyHelper.semester(now);
      case 'yearly':
        return PeriodeKeyHelper.yearly(now);
      default:
        return PeriodeKeyHelper.monthly(now);
    }
  }
}
