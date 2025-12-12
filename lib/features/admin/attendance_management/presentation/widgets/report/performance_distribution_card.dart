import 'package:flutter/material.dart';

/// Widget untuk menampilkan distribusi performa santri
class PerformanceDistributionCard extends StatelessWidget {
  final Map<String, dynamic> performanceStats;

  const PerformanceDistributionCard({
    super.key,
    required this.performanceStats,
  });

  @override
  Widget build(BuildContext context) {
    final excellent = performanceStats['excellent'] as int;
    final good = performanceStats['good'] as int;
    final fair = performanceStats['fair'] as int;
    final poor = performanceStats['poor'] as int;
    final critical = performanceStats['critical'] as int;

    final total = excellent + good + fair + poor + critical;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Distribusi Performa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PerformanceBar(
              label: 'Excellent',
              emoji: '⭐',
              count: excellent,
              total: total,
              color: Colors.green,
              range: '≥ 90%',
            ),
            const SizedBox(height: 8),
            _PerformanceBar(
              label: 'Baik',
              emoji: '✓',
              count: good,
              total: total,
              color: Colors.lightGreen,
              range: '80-89%',
            ),
            const SizedBox(height: 8),
            _PerformanceBar(
              label: 'Cukup',
              emoji: '○',
              count: fair,
              total: total,
              color: Colors.blue,
              range: '70-79%',
            ),
            const SizedBox(height: 8),
            _PerformanceBar(
              label: 'Kurang',
              emoji: '△',
              count: poor,
              total: total,
              color: Colors.orange,
              range: '60-69%',
            ),
            const SizedBox(height: 8),
            _PerformanceBar(
              label: 'Perlu Perhatian',
              emoji: '✗',
              count: critical,
              total: total,
              color: Colors.red,
              range: '< 60%',
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final String emoji;
  final int count;
  final int total;
  final Color color;
  final String range;

  const _PerformanceBar({
    required this.label,
    required this.emoji,
    required this.count,
    required this.total,
    required this.color,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  range,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
