import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/features/admin/attendance_management/presentation/pages/attendance_report_page.dart';
import 'package:sisantri/features/santri/presensi/presentation/pages/presensi_page.dart';
import 'package:sisantri/shared/models/presensi_model.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/services/presensi_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:sisantri/features/shared/jadwal/presentation/jadwal_page.dart';
import 'package:sisantri/features/santri/presensi/presentation/pages/presensi_summary_page.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/leaderboard_page.dart';
import 'package:sisantri/features/santri/profile/presentation/pages/profile_page.dart';
import 'package:sisantri/features/dewan_guru/dashboard/presentation/pages/dewan_guru_dashboard_page.dart';

/// Provider untuk current tab index khusus dewan guru
final dewaGuruTabProvider = StateProvider<int>((ref) => 0);

/// Provider untuk mendapatkan data user dewan guru (one-time fetch)
final dewaGuruUserProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) {
    return null;
  }

  try {
    final userData = await AuthService.getUserData(currentUser.uid);

    // Validasi apakah user memiliki role dewan_guru
    if (userData != null && userData.isDewaGuru) {
      return userData;
    } else {
      return null;
    }
  } catch (e) {
    // Log error dan return null untuk fallback
    return null;
  }
});

/// Provider untuk auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// Provider untuk statistik dashboard dewan guru
final dewaGuruDashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final now = DateTime.now();

    // Get Daily Stats (Today)
    final dailyKey = PresensiAggregateService.getPeriodeKey('daily', now);
    final dailyStats = await PresensiAggregateService.getStatistics(
      periode: 'daily',
      periodeKey: dailyKey,
    );

    // Get Weekly Stats (This Week)
    final weeklyKey = PresensiAggregateService.getPeriodeKey('weekly', now);
    final weeklyStats = await PresensiAggregateService.getStatistics(
      periode: 'weekly',
      periodeKey: weeklyKey,
    );

    final santriList = await AuthService.getSantriList();
    final totalSantri = santriList.length;
    final activeSantri = santriList.where((s) => s.statusAktif).length;

    // Calculate present count from aggregates
    final presentCount =
        (dailyStats['totalHadir'] as int? ?? 0) +
        (dailyStats['totalTerlambat'] as int? ?? 0);

    final attendancePercentage =
        dailyStats['persentaseKehadiran'] as double? ?? 0.0;

    return {
      'summary': {'today': dailyStats, 'thisWeek': weeklyStats},
      'todayPresensi': <PresensiModel>[], // Empty list as we use aggregates
      'totalSantri': totalSantri,
      'activeSantri': activeSantri,
      'presentCount': presentCount,
      'attendancePercentage': attendancePercentage,
    };
  } catch (e) {
    throw Exception('Error loading dashboard stats: $e');
  }
});

/// Provider untuk presensi hari ini (one-time fetch)
final todayPresensiStreamProvider = FutureProvider<List<PresensiModel>>((
  ref,
) async {
  return await PresensiService.getPresensiToday();
});

/// Provider untuk notifikasi dewan guru
final dewaGuruNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    // Ambil aktivitas terbaru untuk notifikasi
    final recentActivities = await PresensiService.getRecentActivities(
      limit: 5,
    );
    final todayStats = await PresensiService.getPresensiSummary();

    List<Map<String, dynamic>> notifications = [];

    // Notifikasi berdasarkan aktivitas terbaru
    for (final activity in recentActivities) {
      if (activity['type'] == 'alpha') {
        notifications.add({
          'type': 'warning',
          'title': 'Santri Tidak Hadir',
          'message': activity['message'],
          'time': activity['time'],
          'icon': Icons.warning_amber,
          'color': Colors.orange,
        });
      }
    }

    // Notifikasi persentase kehadiran rendah
    final weeklyStats = todayStats['thisWeek'] as Map<String, dynamic>;
    final persentaseKehadiran = weeklyStats['persentaseKehadiran'] as double;

    if (persentaseKehadiran < 80) {
      notifications.add({
        'type': 'alert',
        'title': 'Persentase Kehadiran Rendah',
        'message':
            'Kehadiran minggu ini hanya ${persentaseKehadiran.toStringAsFixed(1)}%',
        'time': 'Hari ini',
        'icon': Icons.trending_down,
        'color': Colors.red,
      });
    }

    return notifications;
  } catch (e) {
    return [];
  }
});

/// Navigation khusus untuk Dewan Guru dengan integrasi Firestore
class DewaGuruNavigation extends ConsumerWidget {
  const DewaGuruNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(dewaGuruTabProvider);
    final userData = ref.watch(dewaGuruUserProvider);

    return userData.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data Dewan Guru...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Terjadi kesalahan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(dewaGuruUserProvider);
                },
                child: Text('Coba Lagi'),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  AuthService.signOut();
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        // Jika user null atau bukan dewan guru
        if (user == null || !user.isDewaGuru) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Akses Terbatas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Anda tidak memiliki akses sebagai Dewan Guru',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      AuthService.signOut();
                    },
                    child: Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        // Build navigation dengan user data yang valid
        return _buildNavigationWithUser(context, ref, user, currentTab);
      },
    );
  }

  Widget _buildNavigationWithUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    int currentTab,
  ) {
    final List<Widget> pages = [
      DewanGuruDashboardPage(user: user),
      const JadwalPage(),
      const AttendanceReportPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: pages),
      bottomNavigationBar: _buildBottomNavigationBar(ref, currentTab, user),
    );
  }

  Widget _buildBottomNavigationBar(
    WidgetRef ref,
    int currentTab,
    UserModel user,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) {
          ref.read(dewaGuruTabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.dashboard_outlined, 0, currentTab),
            activeIcon: _buildNavIcon(Icons.dashboard, 0, currentTab),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.schedule_outlined, 2, currentTab),
            activeIcon: _buildNavIcon(Icons.schedule, 2, currentTab),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.analytics_outlined, 4, currentTab),
            activeIcon: _buildNavIcon(Icons.analytics, 4, currentTab),
            label: 'Presensi',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, 5, currentTab),
            activeIcon: _buildNavIcon(Icons.person, 5, currentTab),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, int currentTab) {
    final isActive = index == currentTab;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: isActive
          ? BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Icon(icon),
    );
  }

  Widget _buildNotificationFAB(WidgetRef ref) {
    final notificationsAsync = ref.watch(dewaGuruNotificationsProvider);

    return notificationsAsync.when(
      loading: () => FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (notifications) {
        final hasNotifications = notifications.isNotEmpty;

        return FloatingActionButton(
          onPressed: () {
            _showNotificationsBottomSheet(ref, notifications);
          },
          backgroundColor: hasNotifications
              ? Colors.red
              : AppTheme.primaryColor,
          child: Stack(
            children: [
              const Icon(Icons.notifications),
              if (hasNotifications)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsBottomSheet(
    WidgetRef ref,
    List<Map<String, dynamic>> notifications,
  ) {
    // Implementasi bottom sheet notifikasi akan ditambahkan nanti
    // Untuk sekarang, tampilkan dialog sederhana
    if (notifications.isEmpty) {
      // Tidak ada notifikasi
      return;
    }

    // TODO: Implementasi bottom sheet untuk notifikasi
  }
}
