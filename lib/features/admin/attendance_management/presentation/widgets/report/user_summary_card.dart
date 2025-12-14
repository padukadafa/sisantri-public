import 'package:flutter/material.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/features/admin/attendance_management/presentation/pages/santri_report_detail_page.dart';

/// Widget untuk menampilkan ringkasan presensi per santri
class UserSummaryCard extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> summary;

  const UserSummaryCard({super.key, required this.user, required this.summary});

  @override
  State<UserSummaryCard> createState() => _UserSummaryCardState();
}

class _UserSummaryCardState extends State<UserSummaryCard> {
  bool _isExpanded = false;

  Color _getAttendanceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRate = widget.summary['attendanceRate'] as double;
    final totalRecords = widget.summary['totalRecords'] as int;
    final presentCount = widget.summary['presentCount'] as int;
    final lateCount = widget.summary['lateCount'] as int? ?? 0;
    final absentCount = widget.summary['absentCount'] as int;
    final sickCount = widget.summary['sickCount'] as int;
    final excusedCount = widget.summary['excusedCount'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getAttendanceColor(attendanceRate),
                    child: Text(
                      widget.user.nama[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalRecords presensi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getAttendanceColor(attendanceRate),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${attendanceRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SantriReportDetailPage(
                            userId: widget.user.id,
                            nama: widget.user.nama,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Lihat Detail',
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Status Presensi:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _StatusItem(
                    label: 'Hadir',
                    count: presentCount,
                    total: totalRecords,
                    color: Colors.green,
                  ),
                  _StatusItem(
                    label: 'Terlambat',
                    count: lateCount,
                    total: totalRecords,
                    color: Colors.orange,
                  ),
                  _StatusItem(
                    label: 'Sakit',
                    count: sickCount,
                    total: totalRecords,
                    color: Colors.purple,
                  ),
                  _StatusItem(
                    label: 'Izin',
                    count: excusedCount,
                    total: totalRecords,
                    color: Colors.blue,
                  ),
                  _StatusItem(
                    label: 'Alpha',
                    count: absentCount,
                    total: totalRecords,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Item status presensi
class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            '$count kali',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
