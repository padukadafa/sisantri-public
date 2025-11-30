import 'package:flutter/material.dart';

import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

class DashboardWelcomeCard extends StatelessWidget {
  final UserModel? user;

  const DashboardWelcomeCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: user?.fotoProfil != null
                    ? ClipOval(
                        child: Image.network(
                          user!.fotoProfil!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assalamu\'alaikum',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.nama ?? 'User',
                      style: const TextStyle(
                        color: Color(0xFF2E2E2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withAlpha(50),
                width: 1,
              ),
            ),
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
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? '... Poin'
                          : '$poin Poin',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
