import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/admin/attendance_management/providers/santri_report_providers.dart';
import 'package:sisantri/features/admin/attendance_management/presentation/pages/santri_report_detail_page.dart';

class SantriReportListPage extends ConsumerStatefulWidget {
  const SantriReportListPage({super.key});

  @override
  ConsumerState<SantriReportListPage> createState() =>
      _SantriReportListPageState();
}

class _SantriReportListPageState extends ConsumerState<SantriReportListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final santriListAsync = ref.watch(santriListProvider);
    final comparativeStatsAsync = ref.watch(santriComparativeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Per Santri'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari santri...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Performers Section
          comparativeStatsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              if (stats.isEmpty) return const SizedBox.shrink();

              final topPerformers = stats.take(3).toList();

              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Top 3 Santri Bulan Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (topPerformers.length > 1)
                          Expanded(
                            child: _buildPodiumCard(
                              topPerformers[1],
                              2,
                              Colors.grey,
                              80,
                            ),
                          ),
                        if (topPerformers.isNotEmpty)
                          Expanded(
                            child: _buildPodiumCard(
                              topPerformers[0],
                              1,
                              Colors.amber,
                              100,
                            ),
                          ),
                        if (topPerformers.length > 2)
                          Expanded(
                            child: _buildPodiumCard(
                              topPerformers[2],
                              3,
                              Colors.brown,
                              60,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Santri List
          Expanded(
            child: santriListAsync.when(
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
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(santriListProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (santriList) {
                if (santriList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Belum ada data santri'),
                      ],
                    ),
                  );
                }

                // Filter by search query
                final filteredList = santriList.where((santri) {
                  return santri.nama.toLowerCase().contains(_searchQuery) ||
                      (santri.nim?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Tidak ada santri yang cocok'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final santri = filteredList[index];
                    return _buildSantriCard(context, santri);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
    SantriComparativeStats stats,
    int rank,
    Color color,
    double height,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SantriReportDetailPage(userId: stats.userId, nama: stats.nama),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: color),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stats.nama,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.persentaseKehadiran.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${stats.totalPoin} poin',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSantriCard(BuildContext context, SantriBasicInfo santri) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: santri.fotoProfil != null
              ? NetworkImage(santri.fotoProfil!)
              : null,
          child: santri.fotoProfil == null
              ? Text(
                  santri.nama[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Text(
          santri.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: santri.nim != null ? Text('NIM: ${santri.nim}') : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SantriReportDetailPage(
                userId: santri.userId,
                nama: santri.nama,
              ),
            ),
          );
        },
      ),
    );
  }
}
