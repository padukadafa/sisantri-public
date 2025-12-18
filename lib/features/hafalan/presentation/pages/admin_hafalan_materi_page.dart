import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/hafalan/domain/entities/hafalan_materi.dart';
import '../providers/hafalan_provider.dart';
import '../widgets/materi_form_dialog.dart';

class AdminHafalanMateriPage extends ConsumerWidget {
  const AdminHafalanMateriPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMateriAsync = ref.watch(allMateriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Materi Hafalan'), elevation: 0),
      body: allMateriAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allMateriProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (materiList) {
          if (materiList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada materi hafalan',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan materi doa atau tambahan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by type
          final alquran = materiList.where((m) => m.tipe == 'alquran').toList();
          final doa = materiList.where((m) => m.tipe == 'doa').toList();
          final tambahan = materiList
              .where((m) => m.tipe == 'tambahan')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Al-Quran Section (Read-only, auto-generated)
              _buildSection(
                context,
                ref,
                title: 'Al-Quran',
                subtitle: 'Materi otomatis',
                items: alquran,
                canAdd: false,
                icon: Icons.book,
                color: Colors.green,
                isQuran: true,
              ),
              const SizedBox(height: 24),

              // Doa Section
              _buildSection(
                context,
                ref,
                title: 'Doa-Doa',
                subtitle: 'Kelola doa harian',
                items: doa,
                canAdd: true,
                tipe: 'doa',
                icon: Icons.mosque,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // Tambahan Section
              _buildSection(
                context,
                ref,
                title: 'Materi Tambahan',
                subtitle: 'Hadist, surat pendek, dll',
                items: tambahan,
                canAdd: true,
                tipe: 'tambahan',
                icon: Icons.library_books,
                color: Colors.orange,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, 'doa'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Materi'),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required List<HafalanMateri> items,
    required bool canAdd,
    required IconData icon,
    required Color color,
    String? tipe,
    bool isQuran = false,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canAdd && tipe != null)
                  IconButton(
                    onPressed: () => _showAddDialog(context, tipe),
                    icon: const Icon(Icons.add_circle_outline),
                    color: color,
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Belum ada materi',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else if (isQuran)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar surah Al-Quran (114) disembunyikan untuk menjaga kerapian layar. Tekan tombol di bawah untuk melihat seluruh daftar.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showQuranList(context, items, color),
                    icon: const Icon(Icons.list),
                    label: const Text('Lihat Daftar Surah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final materi = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    materi.nama,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: materi.link != null
                      ? Row(
                          children: [
                            const Icon(Icons.link, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                materi.link!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: canAdd
                      ? PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context, materi);
                            } else if (value == 'delete') {
                              _confirmDelete(
                                context,
                                ref,
                                materi.id,
                                materi.nama,
                              );
                            }
                          },
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  void _showQuranList(
    BuildContext context,
    List<HafalanMateri> items,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Column(
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.book, color: color),
                    const SizedBox(width: 8),
                    const Text(
                      'Daftar Surah Al-Quran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text('${items.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final materi = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: color),
                        ),
                      ),
                      title: Text(materi.nama),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text("Total poin: ${materi.poin}")],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, String tipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MateriFormDialog(initialTipe: tipe),
    );
  }

  void _showEditDialog(BuildContext context, materi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MateriFormDialog(materi: materi),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String nama,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(materiNotifierProvider.notifier).deleteMateri(id);
              ref.invalidate(allMateriProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Materi berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
