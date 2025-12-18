import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../providers/hafalan_provider.dart';

class HafalanDetailDialog extends ConsumerWidget {
  final dynamic materi;
  final HafalanProgress progress;
  final String santriId;

  const HafalanDetailDialog({
    super.key,
    required this.materi,
    required this.progress,
    required this.santriId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getMateriColor().withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getMateriIcon(), color: _getMateriColor(), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          materi.nama,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getMateriColor(),
                          ),
                        ),
                        Text(
                          _getMateriTipeLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Link
                    if (materi.link != null) ...[
                      const Text(
                        'Link Resource',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                materi.link!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Progress info
                    if (progress.status != 'belum') ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Status Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildProgressInfo(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButton(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    if (progress.tanggalMulai != null)
                      Text(
                        'Dimulai: ${_formatDate(progress.tanggalMulai!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (progress.nilai != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getNilaiColor(progress.nilai!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progress.nilai}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (progress.guruPengujiName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Diuji oleh: ${progress.guruPengujiName}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],

          if (progress.catatan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.note, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Catatan Guru:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(progress.catatan!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    if (progress.status == 'belum') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _mulaiHafalan(context, ref),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Mulai Hafalan'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else if (progress.status == 'proses') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.pending, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Menunggu konfirmasi dari guru',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hafalan telah selesai dan dikonfirmasi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _mulaiHafalan(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(progressNotifierProvider.notifier)
          .mulaiHafalan(santriId, materi.id);

      ref.invalidate(progressWithMateriProvider(santriId));
      ref.invalidate(statisticsBySantriProvider(santriId));

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hafalan dimulai! Silakan hubungi guru untuk mengaji',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  IconData _getMateriIcon() {
    switch (materi.tipe) {
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

  Color _getMateriColor() {
    switch (materi.tipe) {
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

  String _getMateriTipeLabel() {
    switch (materi.tipe) {
      case 'alquran':
        return 'Al-Quran';
      case 'doa':
        return 'Doa';
      case 'tambahan':
        return 'Materi Tambahan';
      default:
        return materi.tipe;
    }
  }

  IconData _getStatusIcon() {
    switch (progress.status) {
      case 'selesai':
        return Icons.check_circle;
      case 'proses':
        return Icons.pending;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getStatusColor() {
    switch (progress.status) {
      case 'selesai':
        return Colors.green;
      case 'proses':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (progress.status) {
      case 'selesai':
        return 'Selesai';
      case 'proses':
        return 'Dalam Proses';
      default:
        return 'Belum Dimulai';
    }
  }

  Color _getNilaiColor(int nilai) {
    if (nilai >= 80) return Colors.green;
    if (nilai >= 60) return Colors.orange;
    return Colors.red;
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
}
