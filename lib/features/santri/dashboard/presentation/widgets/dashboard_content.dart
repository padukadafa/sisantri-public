import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';

import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/widgets/presensi_aggregate_stats_widget.dart';
import 'package:sisantri/shared/widgets/level_progress_card.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:sisantri/features/hafalan/presentation/pages/santri_hafalan_page.dart';

import '../providers/dashboard_providers.dart';
import '../providers/stats_providers.dart';
import '../providers/notification_providers.dart';
import 'dashboard_notifications_section.dart';
import 'dashboard_additional_stats.dart';
import 'dashboard_recent_pengumuman.dart';
import 'prayer_times_widget.dart';

class DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final WidgetRef ref;

  const DashboardContent({super.key, required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = data['user'] as UserModel?;
    final recentPengumuman =
        data['recentPengumuman'] as List<AnnouncementModel>? ?? [];

    return RefreshIndicator(
      onRefresh: () => _refreshAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardNotificationsSection(),
            const SizedBox(height: 20),

            // Level Progress Card
            if (user?.id != null)
              FutureBuilder<int>(
                future: PresensiAggregateService.getAggregate(
                  userId: user!.id,
                  periode: 'yearly',
                  date: DateTime.now(),
                ).then((agg) => agg?.totalPoin ?? 0),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final poin = snapshot.data ?? 0;
                  return Column(
                    children: [
                      LevelProgressCard(totalPoin: poin),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            const PrayerTimesCard(),
            const SizedBox(height: 20),
            // Quick Actions - Hafalan
            _buildQuickActionsCard(context),
            const SizedBox(height: 20),
            const DashboardAdditionalStats(),
            const SizedBox(height: 24),
            // Aggregate Stats Section
            if (user?.id != null) ...[
              _buildSectionHeader('Statistik Presensi'),
              const SizedBox(height: 12),
              PeriodeComparisonWidget(userId: user!.id),
              const SizedBox(height: 24),
            ],
            DashboardRecentPengumuman(pengumuman: recentPengumuman),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.bar_chart, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SantriHafalanPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hafalan Saya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lihat progress hafalan Al-Quran & doa',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAllData() async {
    ref.invalidate(dashboardUserProvider);
    ref.invalidate(todayPresensiProvider);
    ref.invalidate(upcomingKegiatanProvider);
    ref.invalidate(recentPengumumanProvider);
    ref.invalidate(userStatsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(userRankProvider);

    await Future.delayed(const Duration(milliseconds: 500));
  }
}
