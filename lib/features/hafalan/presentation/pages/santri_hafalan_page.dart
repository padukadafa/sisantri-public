import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../providers/hafalan_provider.dart';
import '../widgets/hafalan_detail_dialog.dart';

class SantriHafalanPage extends ConsumerWidget {
  const SantriHafalanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final progressWithMateriAsync = ref.watch(
      progressWithMateriProvider(user.uid),
    );
    final statsAsync = ref.watch(statisticsBySantriProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Hafalan Saya'), elevation: 0),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (stats) => Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Progress Hafalan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total',
                        stats['total'] ?? 0,
                        Icons.library_books,
                        Colors.white,
                      ),
                      _buildStatItem(
                        'Selesai',
                        stats['selesai'] ?? 0,
                        Icons.check_circle,
                        Colors.greenAccent,
                      ),
                      _buildStatItem(
                        'Proses',
                        stats['proses'] ?? 0,
                        Icons.pending,
                        Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (stats['total'] ?? 0) > 0
                          ? (stats['selesai'] ?? 0) / (stats['total'] ?? 1)
                          : 0,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((stats['total'] ?? 0) > 0 ? ((stats['selesai'] ?? 0) / (stats['total'] ?? 1) * 100).toStringAsFixed(1) : 0)}% Complete',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // List of hafalan
          Expanded(
            child: progressWithMateriAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(progressWithMateriProvider(user.uid)),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada materi hafalan',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(progressWithMateriProvider(user.uid));
                    ref.refresh(statisticsBySantriProvider(user.uid));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final materi = item['materi'];
                      final progress = item['progress'] as HafalanProgress;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showDetailDialog(
                            context,
                            ref,
                            materi,
                            progress,
                            user.uid,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getMateriColor(
                                        materi.tipe,
                                      ).withOpacity(0.2),
                                      child: Icon(
                                        _getMateriIcon(materi.tipe),
                                        color: _getMateriColor(materi.tipe),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            materi.judul,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            _getMateriTipeLabel(materi.tipe),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusBadge(progress.status),
                                  ],
                                ),

                                if (progress.status == 'selesai' &&
                                    progress.nilai != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.school,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            progress.guruPengujiName ?? 'Guru',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getNilaiColor(
                                            progress.nilai!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Nilai: ${progress.nilai}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        icon = Icons.check_circle;
        break;
      case 'proses':
        color = Colors.orange;
        label = 'Proses';
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        label = 'Belum';
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMateriIcon(String tipe) {
    switch (tipe) {
      case 'alquran':
        return Icons.book;
      case 'doa':
        return Icons.mosque;
      case 'tambahan':
        return Icons.library_books;
      default:
        return Icons.article;
    }
  }

  Color _getMateriColor(String tipe) {
    switch (tipe) {
      case 'alquran':
        return Colors.green;
      case 'doa':
        return Colors.blue;
      case 'tambahan':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getMateriTipeLabel(String tipe) {
    switch (tipe) {
      case 'alquran':
        return 'Al-Quran';
      case 'doa':
        return 'Doa';
      case 'tambahan':
        return 'Materi Tambahan';
      default:
        return tipe;
    }
  }

  Color _getNilaiColor(int nilai) {
    if (nilai >= 80) return Colors.green;
    if (nilai >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showDetailDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic materi,
    HafalanProgress progress,
    String santriId,
  ) {
    showDialog(
      context: context,
      builder: (context) => HafalanDetailDialog(
        materi: materi,
        progress: progress,
        santriId: santriId,
      ),
    );
  }
}
