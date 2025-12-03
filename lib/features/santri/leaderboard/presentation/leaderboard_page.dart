import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/models/leaderboard_model.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/level_model.dart';
import 'package:sisantri/shared/widgets/level_badge_widget.dart';

/// Provider untuk current user
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) return null;
  return await AuthService.getUserData(currentUser.uid);
});

/// Provider untuk leaderboard
final leaderboardProvider = StreamProvider<List<LeaderboardModel>>((ref) {
  return FirestoreService.getLeaderboard();
});

/// Provider untuk filter leaderboard
final leaderboardFilterProvider = StateProvider<String>((ref) => 'all');

/// Halaman Leaderboard
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardStream = ref.watch(leaderboardProvider);
    final currentFilter = ref.watch(leaderboardFilterProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Santri'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              ref.read(leaderboardFilterProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Semua Waktu')),
              const PopupMenuItem(value: 'weekly', child: Text('Mingguan')),
              const PopupMenuItem(value: 'monthly', child: Text('Bulanan')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              'Filter: ${_getFilterLabel(currentFilter)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Leaderboard Content
          Expanded(
            child: leaderboardStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(leaderboardProvider);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (leaderboardList) {
                if (leaderboardList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data ranking',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Filter leaderboard: hanya 10 besar untuk santri
                final filteredList = currentUserAsync.when(
                  data: (user) {
                    if (user != null && user.isSantri) {
                      return leaderboardList.take(10).toList();
                    }
                    return leaderboardList;
                  },
                  loading: () => leaderboardList,
                  error: (_, __) => leaderboardList,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(leaderboardProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Top 3 Podium
                        if (filteredList.length >= 3)
                          _buildPodium(filteredList.take(3).toList()),

                        const SizedBox(height: 20),

                        // Rest of the leaderboard
                        _buildLeaderboardList(filteredList),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'weekly':
        return 'Mingguan';
      case 'monthly':
        return 'Bulanan';
      default:
        return 'Semua Waktu';
    }
  }

  Widget _buildPodium(List<LeaderboardModel> topThree) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (topThree.length > 1) _buildPodiumItem(topThree[1], 2, 120),

          // 1st Place
          _buildPodiumItem(topThree[0], 1, 140),

          // 3rd Place
          if (topThree.length > 2) _buildPodiumItem(topThree[2], 3, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardModel user, int position, double height) {
    Color podiumColor;
    switch (position) {
      case 1:
        podiumColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        podiumColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        podiumColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        podiumColor = Colors.grey;
    }

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          // User Info
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: podiumColor.withOpacity(0.2),
                backgroundImage: user.fotoProfil != null
                    ? NetworkImage(user.fotoProfil!)
                    : null,
                child: user.fotoProfil == null
                    ? Icon(Icons.person, size: 30, color: podiumColor)
                    : null,
              ),
              Positioned(
                bottom: -2,
                child: LevelBadgeWidget(
                  totalPoin: user.poin,
                  size: 22,
                  showTitle: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.nama,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${user.poin} poin',
            style: TextStyle(
              color: podiumColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Podium
          Container(
            width: 60,
            height: height,
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user.medalEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  '#$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardModel> leaderboardList) {
    // Skip top 3 if showing podium
    final listToShow = leaderboardList.length > 3
        ? leaderboardList.skip(3).toList()
        : leaderboardList;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: listToShow.length,
      itemBuilder: (context, index) {
        final user = listToShow[index];
        return _buildLeaderboardItem(user);
      },
    );
  }

  Widget _buildLeaderboardItem(LeaderboardModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ranking
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: user.isTopThree
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${user.ranking}',
                  style: TextStyle(
                    color: user.isTopThree ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Profile Picture with Level Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: user.fotoProfil != null
                      ? NetworkImage(user.fotoProfil!)
                      : null,
                  child: user.fotoProfil == null
                      ? const Icon(Icons.person, color: AppTheme.primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: LevelBadgeWidget(
                    totalPoin: user.poin,
                    size: 18,
                    showTitle: false,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        LevelModel.fromPoin(user.poin).title,
                        style: TextStyle(
                          color: Color(
                            int.parse(
                              LevelModel.fromPoin(
                                user.poin,
                              ).color.replaceFirst('#', '0xFF'),
                            ),
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' • Santri Al-Awwabin',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.poin}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'poin',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            // Medal for top 3
            if (user.isTopThree) ...[
              const SizedBox(width: 8),
              Text(user.medalEmoji, style: const TextStyle(fontSize: 20)),
            ],
          ],
        ),
      ),
    );
  }
}
