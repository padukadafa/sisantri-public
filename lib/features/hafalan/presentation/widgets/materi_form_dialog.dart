import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dewan_guru/navigation/dewan_guru_navigation.dart';
import '../../domain/entities/hafalan_materi.dart';
import '../providers/hafalan_provider.dart';

class MateriFormDialog extends ConsumerStatefulWidget {
  final HafalanMateri? materi;
  final String? initialTipe;

  const MateriFormDialog({super.key, this.materi, this.initialTipe});

  @override
  ConsumerState<MateriFormDialog> createState() => _MateriFormDialogState();
}

class _MateriFormDialogState extends ConsumerState<MateriFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _linkController;
  late TextEditingController _poinController;
  late String _selectedTipe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.materi?.nama ?? '');
    _linkController = TextEditingController(text: widget.materi?.link ?? '');
    _poinController = TextEditingController(
      text: (widget.materi?.poin ?? 1).toString(),
    );
    _selectedTipe = widget.materi?.tipe ?? widget.initialTipe ?? 'Surat Pendek';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _linkController.dispose();
    _poinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.materi == null ? 'Tambah Materi' : 'Edit Materi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTipe,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Hafalan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'doa', child: Text('Doa Harian')),
                    DropdownMenuItem(
                      value: 'tambahan',
                      child: Text('Materi Tambahan'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTipe = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Materi',
                    hintText: 'Contoh: An-Nas, Doa Makan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama materi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link (opsional)',
                    hintText: 'https://example.com/resource',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _poinController,
                  decoration: const InputDecoration(
                    labelText: 'Poin Hafalan',
                    hintText: 'Contoh: 10',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Poin tidak boleh kosong';
                    }
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed < 0) {
                      return 'Masukkan angka >= 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMateri,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.materi == null ? 'Tambah' : 'Simpan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _saveMateri() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).value;
      final userId = user?.uid ?? '';
      final poinValue = int.tryParse(_poinController.text.trim()) ?? 10;

      final materi =
          widget.materi?.copyWith(
            nama: _namaController.text.trim(),
            tipe: _selectedTipe,
            link: _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
            poin: poinValue,
          ) ??
          HafalanMateri(
            id: '',
            nama: _namaController.text.trim(),
            tipe: _selectedTipe,
            link: _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
            poin: poinValue,
            createdAt: DateTime.now(),
            createdBy: userId,
            isActive: true,
            urutan: 0,
          );

      if (widget.materi == null) {
        await ref.read(materiNotifierProvider.notifier).createMateri(materi);
      } else {
        await ref.read(materiNotifierProvider.notifier).updateMateri(materi);
      }

      // Refresh data
      ref.invalidate(allMateriProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.materi == null
                  ? 'Materi berhasil ditambahkan'
                  : 'Materi berhasil diupdate',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
