import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/services/auth_service.dart';

/// Provider untuk periode filter leaderboard
final leaderboardPeriodeProvider = StateProvider<String>((ref) => 'monthly');

/// Provider untuk leaderboard params (cached to prevent unnecessary rebuilds)
final leaderboardParamsProvider = Provider<Map<String, String>>((ref) {
  final periode = ref.watch(leaderboardPeriodeProvider);
  final now = DateTime.now();

  final periodeKey = switch (periode) {
    'monthly' => PeriodeKeyHelper.monthly(now),
    'semester' => PeriodeKeyHelper.semester(now),
    'yearly' => PeriodeKeyHelper.yearly(now),
    _ => PeriodeKeyHelper.monthly(now),
  };

  // Return the same Map instance as long as values don't change
  return {'periode': periode, 'periodeKey': periodeKey};
});

/// Provider untuk leaderboard data dari aggregates
final aggregateLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String>>((
      ref,
      params,
    ) async {
      try {
        final periode = params['periode'] ?? 'monthly';
        final periodeKey =
            params['periodeKey'] ?? PeriodeKeyHelper.monthly(DateTime.now());

        debugPrint('🔍 Loading leaderboard: periode=$periode, key=$periodeKey');

        final leaderboard =
            await PresensiAggregateService.getLeaderboard(
              periode: periode,
              periodeKey: periodeKey,
              limit: 10,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⏱️ Leaderboard query timeout!');
                return [];
              },
            );

        debugPrint('📊 Got ${leaderboard.length} aggregate entries');

        if (leaderboard.isEmpty) {
          debugPrint('⚠️ No aggregate data found');
          return [];
        }

        // Get user details dengan parallel queries untuk performa lebih baik
        final result = <Map<String, dynamic>>[];
        final userFutures = leaderboard.map((entry) async {
          final userId = entry['userId'] as String;
          final userData = await AuthService.getUserData(userId);
          return {'userData': userData, 'entry': entry};
        }).toList();

        final userResults = await Future.wait(userFutures).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('⏱️ User data fetch timeout!');
            return [];
          },
        );

        debugPrint('👥 Got ${userResults.length} user data');

        for (final item in userResults) {
          final userData = item['userData'] as UserModel?;
          final entry = item['entry'] as Map<String, dynamic>;

          if (userData != null) {
            result.add({
              'user': userData,
              'totalPoin': entry['totalPoin'],
              'totalHadir': entry['totalHadir'],
              'totalIzin': entry['totalIzin'],
              'totalSakit': entry['totalSakit'],
              'totalAlpha': entry['totalAlpha'],
            });
          }
        }

        debugPrint('✅ Leaderboard loaded: ${result.length} entries');
        return result;
      } catch (e) {
        debugPrint('❌ Leaderboard error: $e');
        // Return empty list on error or timeout
        return [];
      }
    });

/// Halaman Leaderboard menggunakan agregasi
class AggregateLeaderboardPage extends ConsumerWidget {
  const AggregateLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(leaderboardParamsProvider);
    final periode = params['periode']!;

    // Use cached params to prevent unnecessary provider rebuilds
    final leaderboardAsync = ref.watch(aggregateLeaderboardProvider(params));

    final currentUserAsync = ref.watch(
      FutureProvider<UserModel?>((ref) async {
        final user = AuthService.currentUser;
        if (user == null) return null;
        return await AuthService.getUserData(user.uid);
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Santri'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: periode,
            onSelected: (value) {
              ref.read(leaderboardPeriodeProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'monthly', child: Text('Bulan Ini')),
              const PopupMenuItem(
                value: 'semester',
                child: Text('Semester Ini'),
              ),
              const PopupMenuItem(value: 'yearly', child: Text('Tahun Ini')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(aggregateLeaderboardProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Leaderboard content
          Expanded(
            child: leaderboardAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data ranking...'),
                    SizedBox(height: 8),
                    Text(
                      'Jika loading terlalu lama, coba refresh',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
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
                        ref.invalidate(aggregateLeaderboardProvider);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (leaderboard) {
                if (leaderboard.isEmpty) {
                  return const Center(child: Text('Belum ada data ranking'));
                }

                // Filter untuk santri role (top 10 only)
                final filteredList = currentUserAsync.when(
                  data: (currentUser) {
                    if (currentUser?.role == 'santri') {
                      return leaderboard.take(10).toList();
                    }
                    return leaderboard;
                  },
                  loading: () => leaderboard,
                  error: (_, __) => leaderboard,
                );

                // Get top 3 untuk podium
                final top3 = filteredList.take(3).toList();
                final rest = filteredList.skip(3).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(aggregateLeaderboardProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      if (top3.isNotEmpty) _buildPodium(top3),
                      const SizedBox(height: 16),
                      ...rest.asMap().entries.map((entry) {
                        final index =
                            entry.key + 3; // +3 karena top 3 di podium
                        final item = entry.value;
                        return _buildLeaderboardTile(context, index + 1, item);
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2
          if (top3.length > 1)
            Expanded(child: _buildPodiumItem(2, top3[1], 120, Colors.grey)),
          // Rank 1
          if (top3.isNotEmpty)
            Expanded(child: _buildPodiumItem(1, top3[0], 150, Colors.amber)),
          // Rank 3
          if (top3.length > 2)
            Expanded(child: _buildPodiumItem(3, top3[2], 100, Colors.brown)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    int rank,
    Map<String, dynamic> data,
    double height,
    Color color,
  ) {
    final user = data['user'] as UserModel;
    final poin = data['totalPoin'] as int;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar dengan badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: user.fotoProfil != null
                    ? NetworkImage(user.fotoProfil!)
                    : null,
                child: user.fotoProfil == null
                    ? Text(
                        user.nama.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Nama
        SizedBox(
          width: 90,
          child: Text(
            user.nama,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // Poin
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                '$poin',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Podium stand
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    int rank,
    Map<String, dynamic> data,
  ) {
    final user = data['user'] as UserModel;
    final poin = data['totalPoin'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(rank),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$poin',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.amber;
    if (rank <= 10) return AppTheme.primaryColor;
    return Colors.grey;
  }
}
