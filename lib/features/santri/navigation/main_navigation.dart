import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/aggregate_leaderboard_page.dart';
import 'package:sisantri/features/santri/presensi/presentation/pages/presensi_page.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/features/santri/dashboard/presentation/pages/santri_dashboard_page.dart';
import 'package:sisantri/features/santri/leaderboard/presentation/leaderboard_page.dart';
import 'package:sisantri/features/santri/profile/presentation/pages/profile_page.dart';
import 'package:sisantri/features/shared/jadwal/presentation/jadwal_page.dart';

/// Provider untuk current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Main Navigation dengan Bottom Navigation Bar
class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    final List<Widget> pages = [
      const SantriDashboardPage(),
      const JadwalPage(),
      const PresensiPage(),
      const AggregateLeaderboardPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: 'Presensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
