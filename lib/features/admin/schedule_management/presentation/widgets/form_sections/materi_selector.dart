import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/models/materi_model.dart';
import 'package:sisantri/shared/providers/materi_provider.dart';

/// Widget dropdown untuk memilih materi kajian dari Firebase
class MateriSelector extends ConsumerWidget {
  final String? selectedMateriId;
  final String? selectedMateriNama;
  final Function(String? id, String? nama, String? jenis) onMateriChanged;
  final JenisMateri? filterJenis; // Optional filter berdasarkan jenis

  const MateriSelector({
    super.key,
    this.selectedMateriId,
    this.selectedMateriNama,
    required this.onMateriChanged,
    this.filterJenis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gunakan provider yang sesuai dengan filter
    final materiAsync = filterJenis != null
        ? ref.watch(materiByJenisProvider(filterJenis!))
        : ref.watch(materiProvider);

    return materiAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gagal memuat materi: ${error.toString()}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      data: (materiList) {
        // Filter hanya materi aktif dan deduplikasi berdasarkan ID
        final activeMateri = materiList.where((m) => m.isAktif).toList();

        // Deduplikasi: ambil hanya materi dengan ID unik
        final uniqueMateri = <String, dynamic>{};
        for (final materi in activeMateri) {
          if (!uniqueMateri.containsKey(materi.id)) {
            uniqueMateri[materi.id] = materi;
          }
        }
        final uniqueActiveMateri = uniqueMateri.values.toList();

        if (uniqueActiveMateri.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada materi tersedia',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  filterJenis != null
                      ? 'Tambahkan materi ${_getJenisName(filterJenis!)} terlebih dahulu'
                      : 'Tambahkan materi kajian terlebih dahulu',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Validasi: cek apakah selectedMateriId ada dalam list
        final validatedValue =
            selectedMateriId != null &&
                uniqueActiveMateri.any((m) => m.id == selectedMateriId)
            ? selectedMateriId
            : null;

        return DropdownButtonFormField<String>(
          value: validatedValue,
          decoration: InputDecoration(
            labelText: 'Pilih Materi Kajian',
            hintText: 'Pilih materi dari daftar',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.book),
            suffixIcon: selectedMateriId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onMateriChanged(null, null, null),
                    tooltip: 'Hapus pilihan',
                  )
                : null,
          ),
          isExpanded: true,
          items: [
            // Option untuk tidak memilih materi
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Tidak ada materi spesifik',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            // Daftar materi
            ...uniqueActiveMateri.map((materi) {
              return DropdownMenuItem<String>(
                value: materi.id,
                child: Row(
                  children: [
                    // Icon berdasarkan jenis
                    Icon(
                      _getJenisIcon(materi.jenis),
                      size: 16,
                      color: _getJenisColor(materi.jenis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        materi.nama,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Badge jenis materi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getJenisColor(materi.jenis).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        materi.jenisDisplayName,
                        style: TextStyle(
                          fontSize: 9,
                          color: _getJenisColor(materi.jenis),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (String? materiId) {
            if (materiId == null) {
              onMateriChanged(null, null, null);
            } else {
              final selectedMateri = uniqueActiveMateri.firstWhere(
                (m) => m.id == materiId,
              );
              onMateriChanged(
                selectedMateri.id,
                selectedMateri.nama,
                selectedMateri.jenis.value,
              );
            }
          },
          validator: (value) {
            // Optional validation jika diperlukan
            return null;
          },
        );
      },
    );
  }

  String _getJenisName(JenisMateri jenis) {
    switch (jenis) {
      case JenisMateri.quran:
        return 'Al-Quran';
      case JenisMateri.hadist:
        return 'Hadist';
      case JenisMateri.lainnya:
        return 'Lainnya';
    }
  }

  IconData _getJenisIcon(JenisMateri jenis) {
    switch (jenis) {
      case JenisMateri.quran:
        return Icons.menu_book;
      case JenisMateri.hadist:
        return Icons.format_quote;
      case JenisMateri.lainnya:
        return Icons.library_books;
    }
  }

  Color _getJenisColor(JenisMateri jenis) {
    switch (jenis) {
      case JenisMateri.quran:
        return Colors.green;
      case JenisMateri.hadist:
        return Colors.blue;
      case JenisMateri.lainnya:
        return Colors.grey;
    }
  }
}
