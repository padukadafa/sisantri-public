import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/widgets/rfid_scan_dialog.dart';

/// Dialog untuk mengelola RFID card user
class RfidManagementDialog extends StatefulWidget {
  final UserModel user;

  const RfidManagementDialog({super.key, required this.user});

  @override
  RfidManagementDialogState createState() => RfidManagementDialogState();
}

class RfidManagementDialogState extends State<RfidManagementDialog> {
  final _cardIdController = TextEditingController();

  bool _isLoading = false;
  String? _scannedCardId;

  @override
  void initState() {
    super.initState();
    _cardIdController.text = widget.user.rfidCardId ?? '';
  }

  @override
  void dispose() {
    _cardIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Kelola RFID - ${widget.user.nama}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current RFID Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.user.hasRfidSetup
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.user.hasRfidSetup
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.user.hasRfidSetup ? Icons.nfc : Icons.nfc_outlined,
                      color: widget.user.hasRfidSetup
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status RFID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.user.hasRfidSetup
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          Text(
                            widget.user.hasRfidSetup
                                ? 'Kartu: ${widget.user.rfidCardId}'
                                : 'Belum ada kartu yang di-assign',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info Scanner Eksternal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gunakan scanner RFID eksternal untuk scan kartu, atau masukkan ID kartu secara manual.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual Input
              TextField(
                controller: _cardIdController,
                decoration: InputDecoration(
                  labelText: 'ID Kartu RFID',
                  hintText: 'Masukkan ID kartu atau scan kartu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _cardIdController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _cardIdController.clear();
                            setState(() {
                              _scannedCardId = null;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // RFID Scanner Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startRfidScan,
                  icon: const Icon(Icons.contactless),
                  label: const Text('Scan Kartu RFID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),

              if (_scannedCardId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kartu berhasil discan: $_scannedCardId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'Catatan: Pastikan ID kartu benar sebelum menyimpan. ID kartu yang salah dapat menyebabkan masalah pada sistem presensi.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
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
        if (widget.user.hasRfidSetup)
          TextButton(
            onPressed: _isLoading ? null : _removeRfidCard,
            child: const Text(
              'Hapus Kartu',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ElevatedButton(
          onPressed: _isLoading || _cardIdController.text.trim().isEmpty
              ? null
              : _saveRfidCard,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.user.hasRfidSetup ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _startRfidScan() async {
    await showRfidScanDialog(
      context: context,
      userId: widget.user.id,
      userName: widget.user.nama,
      onSuccess: (rfidCardId) {
        if (mounted) {
          setState(() {
            _cardIdController.text = rfidCardId;
            _scannedCardId = rfidCardId;
          });
        }
      },
    );
  }

  Future<void> _saveRfidCard() async {
    final cardId = _cardIdController.text.trim().toUpperCase();

    if (cardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID kartu tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi panjang minimal ID kartu
    if (cardId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID kartu terlalu pendek (minimal 4 karakter)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if card is already assigned to another user
      final existingCard = await FirebaseFirestore.instance
          .collection('users')
          .where('rfidCardId', isEqualTo: cardId)
          .get();

      if (existingCard.docs.isNotEmpty) {
        final existingUser = existingCard.docs.first.data();
        if (existingUser['id'] != widget.user.id) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Kartu sudah di-assign ke user: ${existingUser['nama']}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Update user with RFID card
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
            'rfidCardId': cardId,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Log activity
      await FirebaseFirestore.instance.collection('activities').add({
        'type': 'rfid_assigned',
        'title': 'RFID Card Assigned',
        'description':
            'Kartu RFID $cardId berhasil di-assign ke ${widget.user.nama}',
        'timestamp': FieldValue.serverTimestamp(),
        'recordedBy': 'Admin',
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kartu RFID berhasil ${widget.user.hasRfidSetup ? 'diupdate' : 'disimpan'} untuk ${widget.user.nama}',
            ),
            backgroundColor: Colors.green,
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

  Future<void> _removeRfidCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kartu RFID'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kartu RFID dari user "${widget.user.nama}"?\n\nUser tidak akan bisa melakukan presensi otomatis sampai kartu di-assign ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .update({
              'rfidCardId': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Log activity
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'rfid_removed',
          'title': 'RFID Card Removed',
          'description': 'Kartu RFID dihapus dari user ${widget.user.nama}',
          'timestamp': FieldValue.serverTimestamp(),
          'recordedBy': 'Admin',
        });

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kartu RFID berhasil dihapus dari ${widget.user.nama}',
              ),
              backgroundColor: Colors.green,
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
}
