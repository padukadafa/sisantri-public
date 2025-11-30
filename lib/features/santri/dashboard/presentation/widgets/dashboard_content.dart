import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';

import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/widgets/presensi_aggregate_stats_widget.dart';

import '../providers/dashboard_providers.dart';
import '../providers/stats_providers.dart';
import '../providers/notification_providers.dart';
import 'dashboard_notifications_section.dart';
import 'dashboard_stats_cards.dart';
import 'dashboard_additional_stats.dart';
import 'dashboard_recent_pengumuman.dart';

class DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final WidgetRef ref;

  const DashboardContent({super.key, required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = data['user'] as UserModel?;
    final todayPresensi = data['todayPresensi'];
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
            DashboardStatsCards(user: user, todayPresensi: todayPresensi),
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
