import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../providers/hafalan_provider.dart';
import '../widgets/konfirmasi_hafalan_dialog.dart';

class GuruKonfirmasiHafalanPage extends ConsumerWidget {
  const GuruKonfirmasiHafalanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingConfirmationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Hafalan'), elevation: 0),
      body: pendingAsync.when(
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
                onPressed: () => ref.refresh(pendingConfirmationsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (pendingList) {
          if (pendingList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada hafalan pending',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Semua hafalan sudah dikonfirmasi',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(pendingConfirmationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final item = pendingList[index];
                final progress = item['progress'] as HafalanProgress;
                final materi = item['materi'];
                final santriName = item['santriName'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _showKonfirmasiDialog(
                      context,
                      ref,
                      progress,
                      materi,
                      santriName,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan santri name dan status
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  santriName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      santriName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(
                                        progress.tanggalMulai ??
                                            progress.updatedAt,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
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
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Menunggu',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Materi info
                          Row(
                            children: [
                              Icon(
                                _getMateriIcon(materi.tipe),
                                color: _getMateriColor(materi.tipe),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      materi.judul,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (materi.tipe == 'alquran')
                                      Text(
                                        '${materi.suratName} ayat ${materi.ayatStart}-${materi.ayatEnd}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                    else if (materi.arabText != null)
                                      Text(
                                        materi.arabText!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: TextDirection.rtl,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showKonfirmasiDialog(
                                context,
                                ref,
                                progress,
                                materi,
                                santriName,
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Konfirmasi'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showKonfirmasiDialog(
    BuildContext context,
    WidgetRef ref,
    HafalanProgress progress,
    dynamic materi,
    String santriName,
  ) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => KonfirmasiHafalanDialog(
        progress: progress,
        materi: materi,
        santriName: santriName,
        guruId: user.uid,
        guruName: user.displayName ?? 'Guru',
      ),
    );
  }
}
