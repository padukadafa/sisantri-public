import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dewan_guru/navigation/dewan_guru_navigation.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../providers/hafalan_provider.dart';
import '../widgets/hafalan_detail_dialog.dart';

class SantriHafalanPage extends ConsumerStatefulWidget {
  const SantriHafalanPage({super.key});

  @override
  ConsumerState<SantriHafalanPage> createState() => _SantriHafalanPageState();
}

class _SantriHafalanPageState extends ConsumerState<SantriHafalanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                // Filter & search
                final filtered = items.where((item) {
                  final materi = item['materi'];
                  final progress = item['progress'] as HafalanProgress;

                  if (_selectedFilter != 'semua' &&
                      progress.status != _selectedFilter) {
                    return false;
                  }

                  final q = _searchController.text.trim().toLowerCase();
                  if (q.isEmpty) return true;
                  final name = (materi.nama as String).toLowerCase();
                  return name.contains(q);
                }).toList();

                // Group by tipe for readability
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final item in filtered) {
                  final tipe = item['materi'].tipe as String;
                  grouped.putIfAbsent(tipe, () => []).add(item);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(progressWithMateriProvider(user.uid));
                    ref.invalidate(statisticsBySantriProvider(user.uid));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Search & filter bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Cari materi...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'semua',
                                  label: Text('Semua'),
                                ),
                                ButtonSegment(
                                  value: 'proses',
                                  label: Text('Proses'),
                                ),
                                ButtonSegment(
                                  value: 'selesai',
                                  label: Text('Selesai'),
                                ),
                                ButtonSegment(
                                  value: 'belum',
                                  label: Text('Belum'),
                                ),
                              ],
                              selected: {_selectedFilter},
                              onSelectionChanged: (v) {
                                setState(() {
                                  _selectedFilter = v.first;
                                });
                              },
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text('Tidak ada materi yang cocok'),
                            ],
                          ),
                        )
                      else
                        ...grouped.entries.map((entry) {
                          final tipe = entry.key;
                          final list = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getMateriIcon(tipe),
                                      color: _getMateriColor(tipe),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getMateriTipeLabel(tipe),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getMateriColor(
                                          tipe,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('${list.length} materi'),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  final materi = item['materi'];
                                  final progress =
                                      item['progress'] as HafalanProgress;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 1,
                                    child: InkWell(
                                      onTap: () => _showDetailDialog(
                                        context,
                                        ref,
                                        materi,
                                        progress,
                                        user.uid,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      _getMateriColor(
                                                        materi.tipe,
                                                      ).withOpacity(0.15),
                                                  child: Icon(
                                                    _getMateriIcon(materi.tipe),
                                                    color: _getMateriColor(
                                                      materi.tipe,
                                                    ),
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        materi.nama,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        _getMateriTipeLabel(
                                                          materi.tipe,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _buildStatusBadge(
                                                  progress.status,
                                                ),
                                              ],
                                            ),

                                            if (progress.status == 'selesai' &&
                                                progress.nilai != null) ...[
                                              const SizedBox(height: 10),
                                              const Divider(height: 1),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                        progress.guruPengujiName ??
                                                            'Guru',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getNilaiColor(
                                                        progress.nilai!,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Nilai: ${progress.nilai}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                            ],
                          );
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
        santriName:
            (ref.read(authStateProvider).value?.displayName ?? '').isNotEmpty
            ? ref.read(authStateProvider).value!.displayName!
            : 'Santri',
      ),
    );
  }
}
