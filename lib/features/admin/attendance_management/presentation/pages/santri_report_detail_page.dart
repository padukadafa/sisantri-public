import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';

// Provider sederhana untuk detail santri
final santriDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();

  // Generate periodeKey untuk bulan ini (sama seperti di attendance_report_provider)
  final periode = 'monthly';
  final periodeKey = PeriodeKeyHelper.monthly(now);

  print('Fetching data for userId: $userId');
  print('Periode: $periode, PeriodeKey: $periodeKey');

  // Query aggregate dengan periode dan periodeKey (sama seperti attendance report)
  final aggregatesSnapshot = await firestore
      .collection('presensi_aggregates')
      .where('userId', isEqualTo: userId)
      .where('periode', isEqualTo: periode)
      .where('periodeKey', isEqualTo: periodeKey)
      .limit(1) // PENTING: Hanya ambil 1 dokumen
      .get();

  print('Found ${aggregatesSnapshot.docs.length} aggregates');

  // Debug: Cek semua aggregates untuk user ini (tanpa filter periodeKey)
  final allUserAggregates = await firestore
      .collection('presensi_aggregates')
      .where('userId', isEqualTo: userId)
      .where('periode', isEqualTo: periode)
      .get();
  print(
    'Total aggregates for this user in monthly periode: ${allUserAggregates.docs.length}',
  );
  for (var doc in allUserAggregates.docs) {
    print(
      '  - Doc ${doc.id}: periodeKey=${doc.data()['periodeKey']}, totalHadir=${doc.data()['totalHadir']}, totalAlpha=${doc.data()['totalAlpha']}',
    );
  }

  // Jika ada multiple aggregates, ambil yang pertama saja (seharusnya cuma 1)
  if (aggregatesSnapshot.docs.isEmpty) {
    print('No aggregates found for this user in this period');
    return {
      'totalRecords': 0,
      'presentCount': 0,
      'lateCount': 0,
      'absentCount': 0,
      'sickCount': 0,
      'excusedCount': 0,
      'attendanceRate': 0.0,
    };
  }

  // Gunakan aggregate pertama (seharusnya hanya 1 per periode+user)
  final doc = aggregatesSnapshot.docs.first;
  final data = doc.data();
  print('Using aggregate doc ${doc.id}');
  print('Raw doc data: $data');

  final agg = PresensiAggregateModel.fromJson({'id': doc.id, ...data});

  print(
    'Aggregate: totalPresensi=${agg.totalPresensi}, hadir=${agg.totalHadir}, terlambat=${agg.totalTerlambat}, alpha=${agg.totalAlpha}, sakit=${agg.totalSakit}, izin=${agg.totalIzin}',
  );

  final presentCount = agg.totalHadir;
  final lateCount = agg.totalTerlambat;
  final absentCount = agg.totalAlpha;
  final sickCount = agg.totalSakit;
  final excusedCount = agg.totalIzin;

  // Gunakan totalPresensi dari aggregate, bukan hitung ulang
  final totalRecords = agg.totalPresensi;

  print('Using totalPresensi from aggregate: $totalRecords');
  print(
    'Breakdown: hadir=$presentCount, terlambat=$lateCount, alpha=$absentCount, sakit=$sickCount, izin=$excusedCount',
  );

  final attendanceRate = totalRecords > 0
      ? (presentCount / totalRecords) * 100
      : 0.0;

  return {
    'totalRecords': totalRecords,
    'presentCount': presentCount,
    'lateCount': lateCount,
    'absentCount': absentCount,
    'sickCount': sickCount,
    'excusedCount': excusedCount,
    'attendanceRate': attendanceRate,
  };
});

class SantriReportDetailPage extends ConsumerWidget {
  const SantriReportDetailPage({
    super.key,
    required this.userId,
    required this.nama,
  });

  final String nama;
  final String userId;

  Widget _buildOverallStatsCard(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final attendanceRate = summary['attendanceRate'] as double;
    final totalRecords = summary['totalRecords'] as int;

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
                    'Persentase\nKehadiran',
                    '${attendanceRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    _getAttendanceColor(attendanceRate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Total\nPresensi',
                    '$totalRecords',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBreakdownCard(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final totalRecords = summary['totalRecords'] as int;
    final presentCount = summary['presentCount'] as int;
    final lateCount = summary['lateCount'] as int? ?? 0;
    final sickCount = summary['sickCount'] as int;
    final excusedCount = summary['excusedCount'] as int;
    final absentCount = summary['absentCount'] as int;

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
            if (totalRecords > 0) ...[
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(
                            presentCount,
                            lateCount,
                            sickCount,
                            excusedCount,
                            absentCount,
                          ),
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Hadir', presentCount, Colors.green),
                          _buildLegendItem(
                            'Terlambat',
                            lateCount,
                            Colors.orange,
                          ),
                          _buildLegendItem('Sakit', sickCount, Colors.purple),
                          _buildLegendItem('Izin', excusedCount, Colors.blue),
                          _buildLegendItem('Alpha', absentCount, Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada data presensi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    int present,
    int late,
    int sick,
    int excused,
    int absent,
  ) {
    final total = present + late + sick + excused + absent;

    if (total == 0) return [];

    return [
      if (present > 0)
        PieChartSectionData(
          value: present.toDouble(),
          color: Colors.green,
          title: '${(present / total * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (late > 0)
        PieChartSectionData(
          value: late.toDouble(),
          color: Colors.orange,
          title: '${(late / total * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (sick > 0)
        PieChartSectionData(
          value: sick.toDouble(),
          color: Colors.purple,
          title: '${(sick / total * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (excused > 0)
        PieChartSectionData(
          value: excused.toDouble(),
          color: Colors.blue,
          title: '${(excused / total * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (absent > 0)
        PieChartSectionData(
          value: absent.toDouble(),
          color: Colors.red,
          title: '${(absent / total * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsCard(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final totalRecords = summary['totalRecords'] as int;
    final presentCount = summary['presentCount'] as int;
    final lateCount = summary['lateCount'] as int? ?? 0;
    final sickCount = summary['sickCount'] as int;
    final excusedCount = summary['excusedCount'] as int;
    final absentCount = summary['absentCount'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Status Presensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Hadir', presentCount, totalRecords, Colors.green),
            _buildDetailRow(
              'Terlambat',
              lateCount,
              totalRecords,
              Colors.orange,
            ),
            _buildDetailRow('Sakit', sickCount, totalRecords, Colors.purple),
            _buildDetailRow('Izin', excusedCount, totalRecords, Colors.blue),
            _buildDetailRow('Alpha', absentCount, totalRecords, Colors.red),
            const Divider(height: 24),
            _buildDetailRow(
              'Total',
              totalRecords,
              totalRecords,
              Colors.grey.shade700,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    int count,
    int total,
    Color color, {
    bool isBold = false,
  }) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$count kali',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '(${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Building santri detail for userId: $userId, nama: $nama');

    final reportAsync = ref.watch(santriDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text('Detail: $nama'), elevation: 0),
      body: reportAsync.when(
        loading: () {
          print('Loading data...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('Error loading santri report: $error');
          print('Stack: $stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(santriDetailProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (summary) {
          print('Data loaded: $summary');

          final totalRecords = summary['totalRecords'] as int;
          final presentCount = summary['presentCount'] as int;
          final absentCount = summary['absentCount'] as int;

          print(
            'Checking: totalRecords=$totalRecords, presentCount=$presentCount, absentCount=$absentCount',
          );

          // Check if there's any data at all
          if (totalRecords == 0 && presentCount == 0 && absentCount == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada data presensi bulan ini'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(santriDetailProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallStatsCard(context, summary),
                  const SizedBox(height: 16),
                  _buildAttendanceBreakdownCard(context, summary),
                  const SizedBox(height: 16),
                  _buildDetailedStatsCard(context, summary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
