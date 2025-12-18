import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/hafalan_materi.dart';
import '../providers/hafalan_provider.dart';

class MateriFormDialog extends ConsumerStatefulWidget {
  final HafalanMateri? materi;

  const MateriFormDialog({super.key, this.materi});

  @override
  ConsumerState<MateriFormDialog> createState() => _MateriFormDialogState();
}

class _MateriFormDialogState extends ConsumerState<MateriFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _arabTextController;
  late TextEditingController _latinTextController;
  late TextEditingController _translationController;
  late String _selectedTipe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.materi?.judul ?? '');
    _arabTextController = TextEditingController(
      text: widget.materi?.arabText ?? '',
    );
    _latinTextController = TextEditingController(
      text: widget.materi?.latinText ?? '',
    );
    _translationController = TextEditingController(
      text: widget.materi?.translation ?? '',
    );
    _selectedTipe = widget.materi?.tipe ?? 'doa';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _arabTextController.dispose();
    _latinTextController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.materi == null ? 'Tambah Materi' : 'Edit Materi'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipe dropdown
              DropdownButtonFormField<String>(
                value: _selectedTipe,
                decoration: const InputDecoration(
                  labelText: 'Tipe Materi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'doa', child: Text('Doa')),
                  DropdownMenuItem(value: 'tambahan', child: Text('Tambahan')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTipe = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Judul
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Contoh: Doa Sebelum Makan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Arab Text
              TextFormField(
                controller: _arabTextController,
                decoration: const InputDecoration(
                  labelText: 'Teks Arab',
                  hintText: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 18),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Teks Arab tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Latin Text
              TextFormField(
                controller: _latinTextController,
                decoration: const InputDecoration(
                  labelText: 'Teks Latin (opsional)',
                  hintText: 'Bismillahirrahmanirrahim',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Translation
              TextFormField(
                controller: _translationController,
                decoration: const InputDecoration(
                  labelText: 'Terjemahan',
                  hintText: 'Dengan menyebut nama Allah...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Terjemahan tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
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

      final materi =
          widget.materi?.copyWith(
            judul: _judulController.text.trim(),
            tipe: _selectedTipe,
            arabText: _arabTextController.text.trim(),
            latinText: _latinTextController.text.trim().isEmpty
                ? null
                : _latinTextController.text.trim(),
            translation: _translationController.text.trim(),
          ) ??
          HafalanMateri(
            id: '',
            judul: _judulController.text.trim(),
            tipe: _selectedTipe,
            arabText: _arabTextController.text.trim(),
            latinText: _latinTextController.text.trim().isEmpty
                ? null
                : _latinTextController.text.trim(),
            translation: _translationController.text.trim(),
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
      ref.refresh(allMateriProvider);

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
