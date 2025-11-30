import 'package:flutter/material.dart';

import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/presensi_model.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

class DashboardStatsCards extends StatelessWidget {
  final UserModel? user;
  final PresensiModel? todayPresensi;

  const DashboardStatsCards({
    super.key,
    required this.user,
    required this.todayPresensi,
  });

  String getStatusLabel(StatusPresensi? status) {
    if (status == null) return 'Belum';

    switch (status) {
      case StatusPresensi.hadir:
        return 'Hadir';
      case StatusPresensi.izin:
        return 'Izin';
      case StatusPresensi.sakit:
        return 'Sakit';
      case StatusPresensi.alpha:
        return 'Alpha';
    }
  }

  Color getStatusColor(StatusPresensi? status) {
    if (status == null) return Colors.grey;

    switch (status) {
      case StatusPresensi.hadir:
        return Colors.green;
      case StatusPresensi.izin:
        return Colors.blue;
      case StatusPresensi.sakit:
        return Colors.orange;
      case StatusPresensi.alpha:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.today,
            title: 'Presensi Hari Ini',
            value: getStatusLabel(todayPresensi?.status),
            color: getStatusColor(todayPresensi?.status),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int>(
            future: user != null
                ? PresensiAggregateService.getAggregate(
                    userId: user!.id,
                    periode: 'yearly',
                    date: DateTime.now(),
                  ).then((agg) => agg?.totalPoin ?? 0)
                : Future.value(0),
            builder: (context, snapshot) {
              final poin = snapshot.data ?? 0;
              return _buildStatCard(
                icon: Icons.star,
                title: 'Total Poin',
                value: snapshot.connectionState == ConnectionState.waiting
                    ? '...'
                    : '$poin',
                color: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
