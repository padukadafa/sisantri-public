import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/aggregate_leaderboard_page.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'package:sisantri/features/shared/announcement/presentation/announcement_page.dart';
import 'package:sisantri/features/shared/jadwal/presentation/jadwal_page.dart';
import 'package:sisantri/features/dewan_guru/navigation/dewan_guru_navigation.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';
import 'package:sisantri/shared/services/announcement_service.dart';
import 'package:sisantri/features/hafalan/presentation/pages/guru_konfirmasi_hafalan_page.dart';

/// Provider untuk pengumuman terbaru (3 pengumuman)
final recentAnnouncementsProvider = StreamProvider<List<AnnouncementModel>>((
  ref,
) {
  return AnnouncementService.getRecentPengumuman(limit: 3);
});

/// Provider untuk jadwal terdekat (3 jadwal terdekat)
final jadwalTerdekatProvider = StreamProvider<List<JadwalModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  return firestore
      .collection('jadwal')
      .where('isAktif', isEqualTo: true)
      .where(
        'tanggal',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
      )
      .orderBy('tanggal')
      .limit(3)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return JadwalModel.fromJson({'id': doc.id, ...data});
        }).toList();
      });
});

class DewanGuruDashboardPage extends ConsumerWidget {
  final UserModel user;

  const DewanGuruDashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dewaGuruDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dewan Guru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dewaGuruDashboardStatsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading dashboard',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStats(stats),
                const SizedBox(height: 24),
                _buildMenuGrid(context),
                const SizedBox(height: 24),
                _buildJadwalTerdekat(ref),
                const SizedBox(height: 24),
                _buildAnnouncements(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final summary = (stats['summary'] as Map<String, dynamic>?) ?? {};
    final todayStats = (summary['today'] as Map<String, dynamic>?) ?? {};
    final weeklyStats = (summary['thisWeek'] as Map<String, dynamic>?) ?? {};

    final totalSantri = stats['totalSantri'] ?? 0;
    final activeSantri = stats['activeSantri'] ?? 0;

    final todayAttendancePercentage =
        (todayStats['persentaseKehadiran'] as double? ?? 0.0).toStringAsFixed(
          1,
        );
    final weeklyAttendancePercentage =
        (weeklyStats['persentaseKehadiran'] as double? ?? 0.0).toStringAsFixed(
          1,
        );

    final todayPresensiTotal = todayStats['totalPresensi'] ?? 0;
    final weeklyPresensiTotal = weeklyStats['totalPresensi'] ?? 0;

    final cards = [
      _buildStatCard(
        title: 'Santri Aktif',
        value: activeSantri.toString(),
        subtitle: '$totalSantri terdaftar',
        icon: Icons.people,
        color: Colors.blue,
      ),
      _buildStatCard(
        title: 'Tingkat Kehadiran (Hari Ini)',
        value: '$todayAttendancePercentage%',
        subtitle: '$todayPresensiTotal total presensi',
        icon: Icons.today,
        color: Colors.orange,
      ),
      _buildStatCard(
        title: 'Kehadiran Minggu Ini',
        value: '$weeklyAttendancePercentage%',
        subtitle: '$weeklyPresensiTotal total presensi',
        icon: Icons.trending_up,
        color: Colors.purple,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: cards,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
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
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      {
        'title': 'Konfirmasi Hafalan',
        'subtitle': 'Periksa hafalan santri',
        'icon': Icons.auto_stories,
        'color': Colors.purple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GuruKonfirmasiHafalanPage(),
          ),
        ),
      },
      {
        'title': 'Ranking Santri',
        'subtitle': 'Leaderboard poin santri',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AggregateLeaderboardPage(),
          ),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1, // Adjusted to prevent overflow
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuCard(
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              icon: item['icon'] as IconData,
              color: item['color'] as Color,
              onTap: item['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalTerdekat(WidgetRef ref) {
    final jadwalAsync = ref.watch(jadwalTerdekatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Jadwal Terdekat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  ref.context,
                  MaterialPageRoute(builder: (context) => const JadwalPage()),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        jadwalAsync.when(
          data: (jadwalList) {
            if (jadwalList.isEmpty) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada jadwal mendatang',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: jadwalList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final jadwal = entry.value;
                  final kategoriColor = _getKategoriColor(jadwal.kategori);
                  final kategoriIcon = _getKategoriIcon(jadwal.kategori);

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            kategoriIcon,
                            color: kategoriColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          jadwal.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat(
                                    'EEEE, d MMM yyyy',
                                    'id_ID',
                                  ).format(jadwal.tanggal),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (jadwal.waktuMulai != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${jadwal.waktuMulai}${jadwal.waktuSelesai != null ? ' - ${jadwal.waktuSelesai}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (jadwal.tempat != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      jadwal.tempat!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            jadwal.kategori.value.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kategoriColor,
                            ),
                          ),
                        ),
                      ),
                      if (index < jadwalList.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loading: () => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat jadwal',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getKategoriColor(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.kegiatan:
        return Colors.blue;
      case TipeJadwal.pengajian:
        return Colors.green;
      case TipeJadwal.tahfidz:
        return Colors.purple;
      case TipeJadwal.bacaan:
        return Colors.orange;
      case TipeJadwal.olahraga:
        return Colors.red;
    }
  }

  IconData _getKategoriIcon(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.kegiatan:
        return Icons.event;
      case TipeJadwal.pengajian:
        return Icons.menu_book;
      case TipeJadwal.tahfidz:
        return Icons.auto_stories;
      case TipeJadwal.bacaan:
        return Icons.book;
      case TipeJadwal.olahraga:
        return Icons.sports_soccer;
    }
  }

  Widget _buildAnnouncements(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(recentAnnouncementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengumuman',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnnouncementPage(),
                  ),
                );
              },
              child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        announcementsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gagal memuat pengumuman',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (announcements) {
            if (announcements.isEmpty) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.announcement,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada pengumuman',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: announcements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final announcement = entry.value;

                  // Tentukan icon dan warna berdasarkan kategori
                  IconData icon;
                  Color color;

                  switch (announcement.kategori.toLowerCase()) {
                    case 'akademik':
                      icon = Icons.school;
                      color = Colors.blue;
                      break;
                    case 'kegiatan':
                      icon = Icons.event;
                      color = Colors.green;
                      break;
                    case 'penting':
                      icon = Icons.priority_high;
                      color = Colors.red;
                      break;
                    case 'umum':
                    default:
                      icon = Icons.campaign;
                      color = Colors.orange;
                      break;
                  }

                  // Hitung waktu relatif
                  final now = DateTime.now();
                  final diff = now.difference(announcement.createdAt);
                  String timeAgo;

                  if (diff.inDays > 0) {
                    timeAgo = '${diff.inDays} hari lalu';
                  } else if (diff.inHours > 0) {
                    timeAgo = '${diff.inHours} jam lalu';
                  } else if (diff.inMinutes > 0) {
                    timeAgo = '${diff.inMinutes} menit lalu';
                  } else {
                    timeAgo = 'Baru saja';
                  }

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement.judul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (announcement.isPinned)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PENTING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              announcement.konten,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < announcements.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
