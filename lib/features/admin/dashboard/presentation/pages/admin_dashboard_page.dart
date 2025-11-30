import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/features/admin/materi_management/presentation/pages/materi_management_page.dart';

import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/presensi_model.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/features/admin/user_management/presentation/pages/user_management_page.dart';
import 'package:sisantri/features/admin/attendance_management/presentation/pages/attendance_report_page.dart';
import 'package:sisantri/features/admin/statistics/presentation/pages/admin_statistics_page.dart';
import 'package:sisantri/shared/services/presensi_service.dart';

enum PeriodFilter {
  day('Hari', 1),
  week('Minggu', 7),
  month('Bulan', 30),
  year('Tahun', 365);

  final String label;
  final int days;

  const PeriodFilter(this.label, this.days);
}

final selectedPeriodProvider = StateProvider<PeriodFilter>(
  (ref) => PeriodFilter.day,
);

final adminStatsProvider =
    FutureProvider.family<Map<String, dynamic>, PeriodFilter>((
      ref,
      period,
    ) async {
      try {
        final firestore = FirebaseFirestore.instance;

        final usersSnapshot = await firestore.collection('users').get();
        final users = usersSnapshot.docs
            .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList();

        final santriCount = users.where((u) => u.isSantri).length;
        final guruCount = users.where((u) => u.isDewaGuru).length;
        final adminCount = users.where((u) => u.isAdmin).length;

        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final todayAttendance = await PresensiService.getPresensiByPeriod(
          startDate: startOfDay,
          endDate: endOfDay,
        );

        int presentCount = 0;
        for (var presensi in todayAttendance) {
          if (presensi.status == StatusPresensi.hadir) {
            presentCount++;
          }
        }

        final periodStartDate = today.subtract(Duration(days: period.days - 1));
        final periodStart = DateTime(
          periodStartDate.year,
          periodStartDate.month,
          periodStartDate.day,
        );

        final periodAttendance = await PresensiService.getPresensiByPeriod(
          startDate: periodStart,
          endDate: endOfDay,
        );

        final periodHadirCount = periodAttendance
            .where((p) => p.status == StatusPresensi.hadir)
            .length;

        final attendanceRate = periodAttendance.isNotEmpty
            ? (periodHadirCount / periodAttendance.length * 100)
            : 0.0;

        final activitiesSnapshot = await firestore
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        final recentActivities = activitiesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        return {
          'totalSantri': santriCount,
          'totalGuru': guruCount,
          'totalAdmin': adminCount,
          'totalUsers': users.length,
          'todayAttendance': todayAttendance.length,
          'presentCount': presentCount,
          'attendanceRate': attendanceRate,
          'recentActivities': recentActivities,
          'period': period,
        };
      } catch (e) {
        throw Exception('Error loading admin stats: $e');
      }
    });

/// Admin Dashboard Page dengan fitur lengkap
class AdminDashboardPage extends ConsumerWidget {
  final UserModel admin;

  const AdminDashboardPage({super.key, required this.admin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final statsAsync = ref.watch(adminStatsProvider(selectedPeriod));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
                data: (stats) => Column(
                  children: [
                    _buildPeriodFilter(context, ref),
                    const SizedBox(height: 16),
                    _buildStatsCards(stats),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildManagementSection(context),
                    const SizedBox(height: 16),
                    _buildRecentActivities(stats['recentActivities'] as List),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

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
                Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Periode',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PeriodFilter.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(selectedPeriodProvider.notifier).state =
                              period;
                        }
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      elevation: isSelected ? 2 : 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    final presentCount = stats['presentCount'] ?? 0;
    final totalSantri = stats['totalSantri'] ?? 0;
    final todayAttendance = stats['todayAttendance'] ?? 0;
    final period = stats['period'] as PeriodFilter;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Total Santri',
          totalSantri.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Dewan Guru',
          stats['totalGuru'].toString(),
          Icons.person_outline,
          Colors.green,
        ),
        _buildStatCard(
          'Kehadiran Hari Ini',
          '$presentCount / $todayAttendance',
          Icons.check_circle_outline,
          Colors.orange,
        ),
        _buildStatCard(
          'Tingkat Kehadiran (${period.label})',
          '${stats['attendanceRate'].toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
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
                Icon(Icons.settings, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Manajemen Sistem',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildManagementTile(
              'Manajemen Materi',
              'Atur capaian materi santri',
              Icons.book,
              Colors.blueGrey,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MateriManagementPage()),
                );
              },
            ),
            const Divider(),
            _buildManagementTile(
              'Laporan Presensi',
              'Lihat dan export laporan kehadiran',
              Icons.analytics,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceReportPage(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildManagementTile(
              'Manajemen User',
              'Kelola akun santri dan dewan guru',
              Icons.people_alt,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildRecentActivities(List activities) {
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
                Icon(Icons.history, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada aktivitas terbaru',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...activities
                  .take(5)
                  .map((activity) => _buildActivityTile(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Aktivitas',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  activity['description'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(activity['timestamp']),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading data: $error'),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is String) {
      time = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
    if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
    return '${diff.inDays}h yang lalu';
  }
}
