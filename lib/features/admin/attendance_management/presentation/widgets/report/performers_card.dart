import 'package:flutter/material.dart';

/// Widget untuk menampilkan top performers
class TopPerformersCard extends StatelessWidget {
  final List<Map<String, dynamic>> topPerformers;

  const TopPerformersCard({super.key, required this.topPerformers});

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Top 5 Santri Terbaik',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topPerformers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tidak ada data'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topPerformers.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final performer = topPerformers[index];
                  return _PerformerTile(
                    rank: index + 1,
                    name: performer['name'] as String,
                    attendanceRate: performer['attendanceRate'] as double,
                    totalPoin: performer['totalPoin'] as int,
                    isTop: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan bottom performers
class BottomPerformersCard extends StatelessWidget {
  final List<Map<String, dynamic>> bottomPerformers;

  const BottomPerformersCard({super.key, required this.bottomPerformers});

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Santri Perlu Perhatian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bottomPerformers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tidak ada data'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bottomPerformers.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final performer = bottomPerformers[index];
                  return _PerformerTile(
                    rank: index + 1,
                    name: performer['name'] as String,
                    attendanceRate: performer['attendanceRate'] as double,
                    totalPoin: performer['totalPoin'] as int,
                    isTop: false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PerformerTile extends StatelessWidget {
  final int rank;
  final String name;
  final double attendanceRate;
  final int totalPoin;
  final bool isTop;

  const _PerformerTile({
    required this.rank,
    required this.name,
    required this.attendanceRate,
    required this.totalPoin,
    required this.isTop,
  });

  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _getRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.lightGreen;
    if (rate >= 70) return Colors.blue;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTop
                ? Colors.amber.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              isTop && rank <= 3 ? _getMedalEmoji(rank) : '#$rank',
              style: TextStyle(
                fontSize: isTop && rank <= 3 ? 20 : 14,
                fontWeight: FontWeight.bold,
                color: isTop ? Colors.amber[800] : Colors.red[800],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPoin poin',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRateColor(attendanceRate).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${attendanceRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getRateColor(attendanceRate),
            ),
          ),
        ),
      ],
    );
  }
}
