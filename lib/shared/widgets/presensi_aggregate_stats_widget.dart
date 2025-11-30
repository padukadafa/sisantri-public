import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

/// Provider untuk aggregate summary
final aggregateSummaryProvider =
    FutureProvider.family<Map<String, PresensiAggregateModel?>, String>((
      ref,
      userId,
    ) async {
      return await PresensiAggregateService.getAggregateSummary(userId: userId);
    });

/// Widget untuk menampilkan statistik presensi dari agregasi
class PresensiAggregateStatsWidget extends ConsumerWidget {
  final String userId;
  final String periode; // 'daily', 'weekly', 'monthly', 'semester', 'yearly'

  const PresensiAggregateStatsWidget({
    super.key,
    required this.userId,
    this.periode = 'monthly',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(aggregateSummaryProvider(userId));

    return aggregateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (summary) {
        final aggregate = summary[periode];

        if (aggregate == null) {
          return const Center(child: Text('Belum ada data presensi'));
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPeriodeLabel(periode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDate(aggregate.startDate)} - ${_formatDate(aggregate.endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _buildStatItem(
                      'Hadir',
                      aggregate.totalHadir,
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      'Izin',
                      aggregate.totalIzin,
                      Colors.orange,
                      Icons.info,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatItem(
                      'Sakit',
                      aggregate.totalSakit,
                      Colors.blue,
                      Icons.local_hospital,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      'Alpha',
                      aggregate.totalAlpha,
                      Colors.red,
                      Icons.cancel,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Poin',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${aggregate.totalPoin}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Kehadiran',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${aggregate.persentaseKehadiran.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getPercentageColor(
                              aggregate.persentaseKehadiran,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  String _getPeriodeLabel(String periode) {
    switch (periode) {
      case 'daily':
        return 'Hari Ini';
      case 'weekly':
        return 'Minggu Ini';
      case 'monthly':
        return 'Bulan Ini';
      case 'semester':
        return 'Semester Ini';
      case 'yearly':
        return 'Tahun Ini';
      default:
        return periode;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Widget untuk perbandingan periode
class PeriodeComparisonWidget extends ConsumerWidget {
  final String userId;

  const PeriodeComparisonWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(aggregateSummaryProvider(userId));

    return aggregateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (summary) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPeriodeCard('Minggu', summary['weekly'], Colors.blue),
              const SizedBox(width: 12),
              _buildPeriodeCard('Bulan', summary['monthly'], Colors.green),
              const SizedBox(width: 12),
              _buildPeriodeCard('Semester', summary['semester'], Colors.orange),
              const SizedBox(width: 12),
              _buildPeriodeCard('Tahun', summary['yearly'], Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodeCard(
    String label,
    PresensiAggregateModel? aggregate,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (aggregate != null) ...[
            _buildMiniStat('Hadir', aggregate.totalHadir, Colors.green),
            const SizedBox(height: 4),
            _buildMiniStat('Izin', aggregate.totalIzin, Colors.orange),
            const SizedBox(height: 4),
            _buildMiniStat('Sakit', aggregate.totalSakit, Colors.blue),
            const SizedBox(height: 4),
            _buildMiniStat('Alpha', aggregate.totalAlpha, Colors.red),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Poin:',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  '${aggregate.totalPoin}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                'Tidak ada data',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
