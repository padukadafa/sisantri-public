import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'package:sisantri/features/shared/jadwal/presentation/jadwal_detail_page.dart';

/// Provider untuk jadwal dari Firestore
final jadwalProvider = StreamProvider<List<JadwalModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  return firestore
      .collection('jadwal')
      .where('isAktif', isEqualTo: true)
      .where(
        'tanggal',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
      )
      .orderBy('tanggal')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return JadwalModel.fromJson({'id': doc.id, ...data});
        }).toList();
      });
});

/// Provider untuk filter kategori
final kategoriFilterProvider = StateProvider<TipeJadwal?>((ref) => null);

/// Provider untuk jadwal yang sudah difilter
final filteredJadwalProvider = Provider<AsyncValue<List<JadwalModel>>>((ref) {
  final jadwalAsync = ref.watch(jadwalProvider);
  final kategoriFilter = ref.watch(kategoriFilterProvider);

  return jadwalAsync.when(
    data: (jadwalList) {
      if (kategoriFilter == null) {
        return AsyncValue.data(jadwalList);
      }

      final filtered = jadwalList.where((jadwal) {
        return jadwal.kategori == kategoriFilter;
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Halaman Jadwal
class JadwalPage extends ConsumerWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredJadwalAsync = ref.watch(filteredJadwalProvider);
    final kategoriFilter = ref.watch(kategoriFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Kategori:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (kategoriFilter != null)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(kategoriFilterProvider.notifier).state =
                              null;
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Reset'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        ref: ref,
                        label: 'Semua',
                        kategori: null,
                        icon: Icons.all_inclusive,
                        isSelected: kategoriFilter == null,
                      ),
                      const SizedBox(width: 8),
                      ...TipeJadwal.values.map((kategori) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            ref: ref,
                            label: _getKategoriLabel(kategori),
                            kategori: kategori,
                            icon: _getKategoriIcon(kategori),
                            isSelected: kategoriFilter == kategori,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: filteredJadwalAsync.when(
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
                        ref.invalidate(jadwalProvider);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (jadwalList) {
                if (jadwalList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          kategoriFilter == null
                              ? 'Belum ada jadwal'
                              : 'Tidak ada jadwal ${_getKategoriLabel(kategoriFilter)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(jadwalProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwalList[index];
                      return _buildJadwalCard(context, jadwal);
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

  Widget _buildFilterChip({
    required WidgetRef ref,
    required String label,
    required TipeJadwal? kategori,
    required IconData icon,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(kategoriFilterProvider.notifier).state = selected
            ? kategori
            : null;
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildJadwalCard(BuildContext context, JadwalModel jadwal) {
    final color = _getKategoriColor(jadwal.kategori);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showJadwalDetail(context, jadwal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      jadwal.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (jadwal.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'HARI INI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (jadwal.isTomorrow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BESOK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              if (jadwal.deskripsi != null && jadwal.deskripsi!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    jadwal.deskripsi!,
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Time and Location
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    jadwal.formattedWaktuRange,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      jadwal.tempat ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Kategori and Status Chips
              Row(
                children: [
                  // Kategori Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getKategoriLabel(jadwal.kategori).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: jadwal.isAktif
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jadwal.isAktif ? 'AKTIF' : 'NONAKTIF',
                      style: TextStyle(
                        color: jadwal.isAktif ? Colors.green : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJadwalDetail(BuildContext context, JadwalModel jadwal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JadwalDetailPage(jadwalId: jadwal.id),
      ),
    );
  }

  String _getKategoriLabel(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.kegiatan:
        return 'Kegiatan';
      case TipeJadwal.pengajian:
        return 'Pengajian';
      case TipeJadwal.tahfidz:
        return 'Tahfidz';
      case TipeJadwal.bacaan:
        return 'Bacaan';
      case TipeJadwal.olahraga:
        return 'Olahraga';
    }
  }

  IconData _getKategoriIcon(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.kegiatan:
        return Icons.event;
      case TipeJadwal.pengajian:
        return Icons.mosque;
      case TipeJadwal.tahfidz:
        return Icons.auto_stories;
      case TipeJadwal.bacaan:
        return Icons.book;
      case TipeJadwal.olahraga:
        return Icons.sports;
    }
  }

  Color _getKategoriColor(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.kegiatan:
        return Colors.blue;
      case TipeJadwal.pengajian:
        return Colors.green;
      case TipeJadwal.tahfidz:
        return Colors.teal;
      case TipeJadwal.bacaan:
        return Colors.orange;
      case TipeJadwal.olahraga:
        return Colors.red;
    }
  }
}
