import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/user_model.dart';

/// Provider untuk mendapatkan daftar dewan guru
final dewanGuruProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'dewan_guru')
      .where('statusAktif', isEqualTo: true)
      .orderBy('nama')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromJson({...doc.data(), 'id': doc.id});
        }).toList();
      });
});

/// Widget untuk memilih pemateri dari daftar dewan guru
class PemateriSelector extends ConsumerWidget {
  final String? selectedPemateriId;
  final String? selectedPemateriNama;
  final Function(String? id, String? nama) onPemateriChanged;

  const PemateriSelector({
    super.key,
    this.selectedPemateriId,
    this.selectedPemateriNama,
    required this.onPemateriChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dewanGuruAsync = ref.watch(dewanGuruProvider);

    return dewanGuruAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Text(
        'Error loading guru: $error',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
      data: (dewanGuruList) {
        if (dewanGuruList.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Belum ada data dewan guru. Silakan tambahkan user dengan role "Dewan Guru" terlebih dahulu.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          );
        }

        // Deduplikasi: ambil hanya guru dengan ID unik
        final uniqueGuru = <String, dynamic>{};
        for (final guru in dewanGuruList) {
          if (!uniqueGuru.containsKey(guru.id)) {
            uniqueGuru[guru.id] = guru;
          }
        }
        final uniqueDewanGuru = uniqueGuru.values.toList();

        // Validasi: cek apakah selectedPemateriId ada dalam list
        final validatedValue =
            selectedPemateriId != null &&
                uniqueDewanGuru.any((g) => g.id == selectedPemateriId)
            ? selectedPemateriId
            : null;

        return DropdownButtonFormField<String>(
          value: validatedValue,
          decoration: const InputDecoration(
            labelText: 'Pilih Pemateri/Ustadz',
            hintText: 'Pilih dari daftar dewan guru',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),

          items: [
            const DropdownMenuItem<String>(
              value: null,

              child: Text('-- Tidak ada pemateri --'),
            ),
            ...uniqueDewanGuru.map((guru) {
              return DropdownMenuItem<String>(
                value: guru.id,

                child: Text(
                  guru.nama,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (String? value) {
            if (value == null) {
              onPemateriChanged(null, null);
            } else {
              final selectedGuru = uniqueDewanGuru.firstWhere(
                (guru) => guru.id == value,
              );
              onPemateriChanged(value, selectedGuru.nama);
            }
          },
          isExpanded: true,
        );
      },
    );
  }
}
