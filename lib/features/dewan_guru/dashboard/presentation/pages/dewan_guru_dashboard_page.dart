import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/aggregate_leaderboard_page.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'package:sisantri/features/santri/presensi/presentation/pages/presensi_summary_page.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/leaderboard_page.dart';
import 'package:sisantri/features/shared/announcement/presentation/announcement_page.dart';
import 'package:sisantri/features/shared/jadwal/presentation/jadwal_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dewan Guru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            const SizedBox(height: 24),
            // _buildMenuGrid(context),
            const SizedBox(height: 24),
            _buildJadwalTerdekat(ref),
            const SizedBox(height: 24),
            _buildRecentUpdates(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.notifications_active,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat datang, ${user.nama}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dewan Guru',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pantau perkembangan santri dan kegiatan pondok pesantren',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Santri',
            value: '45',
            subtitle: 'Santri Aktif',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Kehadiran Hari Ini',
            value: '92%',
            subtitle: '41 dari 45 santri',
            icon: Icons.how_to_reg,
            color: Colors.green,
          ),
        ),
      ],
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
        'title': 'Rangkuman Presensi',
        'subtitle': 'Lihat data kehadiran santri',
        'icon': Icons.analytics,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PresensiSummaryPage()),
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
      {
        'title': 'Pengumuman',
        'subtitle': 'Lihat pengumuman terbaru',
        'icon': Icons.campaign,
        'color': Colors.orange,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnouncementPage()),
        ),
      },
      {
        'title': 'Jadwal Kegiatan',
        'subtitle': 'Jadwal harian & mingguan',
        'icon': Icons.schedule,
        'color': Colors.green,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JadwalPage()),
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
            childAspectRatio: 1.2,
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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

  Widget _buildRecentUpdates() {
    final updates = [
      {
        'title': 'Pengumuman Baru',
        'description': 'Jadwal ujian semester telah diperbarui',
        'time': '2 jam lalu',
        'icon': Icons.campaign,
        'color': Colors.orange,
      },
      {
        'title': 'Presensi Kajian Tafsir',
        'description': '42 dari 45 santri telah melakukan presensi',
        'time': '3 jam lalu',
        'icon': Icons.menu_book,
        'color': Colors.blue,
      },
      {
        'title': 'Ranking Diperbarui',
        'description': 'Ahmad Rizki naik ke posisi #1 leaderboard',
        'time': '5 jam lalu',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Terbaru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: updates.asMap().entries.map((entry) {
              final index = entry.key;
              final update = entry.value;

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
                        color: (update['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        update['icon'] as IconData,
                        color: update['color'] as Color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      update['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          update['description'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          update['time'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < updates.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
