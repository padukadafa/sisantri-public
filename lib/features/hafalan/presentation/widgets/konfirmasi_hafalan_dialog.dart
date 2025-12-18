import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../providers/hafalan_provider.dart';

class KonfirmasiHafalanDialog extends ConsumerStatefulWidget {
  final HafalanProgress progress;
  final dynamic materi;
  final String santriName;
  final String guruId;
  final String guruName;

  const KonfirmasiHafalanDialog({
    super.key,
    required this.progress,
    required this.materi,
    required this.santriName,
    required this.guruId,
    required this.guruName,
  });

  @override
  ConsumerState<KonfirmasiHafalanDialog> createState() =>
      _KonfirmasiHafalanDialogState();
}

class _KonfirmasiHafalanDialogState
    extends ConsumerState<KonfirmasiHafalanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  int _nilai = 80;
  String _status = 'selesai';
  bool _isLoading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Hafalan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info santri dan materi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.santriName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.book, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.materi.judul,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status dropdown
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'selesai',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Lulus'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'proses',
                    child: Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Perlu Perbaikan'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Nilai slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nilai', style: TextStyle(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getNilaiColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_nilai',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _nilai.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: _nilai.toString(),
                    onChanged: (value) {
                      setState(() {
                        _nilai = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0', style: TextStyle(color: Colors.grey[600])),
                      Text('50', style: TextStyle(color: Colors.grey[600])),
                      Text('100', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Masukkan catatan untuk santri',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
          onPressed: _isLoading ? null : _saveKonfirmasi,
          style: ElevatedButton.styleFrom(
            backgroundColor: _status == 'selesai'
                ? Colors.green
                : Colors.orange,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Konfirmasi'),
        ),
      ],
    );
  }

  Color _getNilaiColor() {
    if (_nilai >= 80) return Colors.green;
    if (_nilai >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveKonfirmasi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(progressNotifierProvider.notifier)
          .konfirmasiHafalan(
            progressId: widget.progress.id,
            santriId: widget.progress.santriId,
            materiId: widget.progress.materiId,
            guruId: widget.guruId,
            guruName: widget.guruName,
            nilai: _nilai,
            status: _status,
            catatan: _catatanController.text.trim().isEmpty
                ? null
                : _catatanController.text.trim(),
          );

      // Refresh data
      ref.refresh(pendingConfirmationsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _status == 'selesai'
                  ? 'Hafalan berhasil dikonfirmasi sebagai lulus'
                  : 'Hafalan dikembalikan untuk perbaikan',
            ),
            backgroundColor: _status == 'selesai'
                ? Colors.green
                : Colors.orange,
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
