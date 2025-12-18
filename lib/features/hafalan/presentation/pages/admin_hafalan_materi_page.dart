import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hafalan_provider.dart';
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
                onPressed: () => ref.refresh(allMateriProvider),
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
        onPressed: () => _showAddDialog(context),
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
    required List items,
    required bool canAdd,
    required IconData icon,
    required Color color,
    String? tipe,
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
                    materi.judul,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: materi.tipe == 'alquran'
                      ? Text(
                          '${materi.suratName} ayat ${materi.ayatStart}-${materi.ayatEnd}',
                        )
                      : Text(materi.arabText ?? materi.konten ?? ''),
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
                                materi.judul,
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

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MateriFormDialog(),
    );
  }

  void _showEditDialog(BuildContext context, materi) {
    showDialog(
      context: context,
      builder: (context) => MateriFormDialog(materi: materi),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String judul,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "$judul"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(materiNotifierProvider.notifier).deleteMateri(id);
              ref.refresh(allMateriProvider);
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
