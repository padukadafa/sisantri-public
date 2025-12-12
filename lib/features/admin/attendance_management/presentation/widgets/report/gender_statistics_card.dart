import 'package:flutter/material.dart';

/// Widget untuk menampilkan statistik gender
class GenderStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> genderStats;

  const GenderStatisticsCard({super.key, required this.genderStats});

  @override
  Widget build(BuildContext context) {
    final maleStats = genderStats['male'] as Map<String, dynamic>;
    final femaleStats = genderStats['female'] as Map<String, dynamic>;

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
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analisis Gender',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    gender: 'Laki-laki',
                    icon: Icons.male,
                    color: Colors.blue,
                    stats: maleStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCard(
                    gender: 'Perempuan',
                    icon: Icons.female,
                    color: Colors.pink,
                    stats: femaleStats,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ComparisonBar(maleStats: maleStats, femaleStats: femaleStats),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String gender;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> stats;

  const _GenderCard({
    required this.gender,
    required this.icon,
    required this.color,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final count = stats['count'] as int;
    final totalRecords = stats['totalRecords'] as int;
    final attendanceRate = stats['attendanceRate'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            gender,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count Santri',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalRecords Presensi',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${attendanceRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final Map<String, dynamic> maleStats;
  final Map<String, dynamic> femaleStats;

  const _ComparisonBar({required this.maleStats, required this.femaleStats});

  @override
  Widget build(BuildContext context) {
    final maleRate = maleStats['attendanceRate'] as double;
    final femaleRate = femaleStats['attendanceRate'] as double;
    final difference = (maleRate - femaleRate).abs();
    final better = maleRate > femaleRate ? 'Laki-laki' : 'Perempuan';
    final betterColor = maleRate > femaleRate ? Colors.blue : Colors.pink;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kehadiran Lebih Baik:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                better,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: betterColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: betterColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${difference.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: betterColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
