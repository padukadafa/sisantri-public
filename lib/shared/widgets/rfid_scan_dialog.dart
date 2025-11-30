import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/rfid_scan_config_model.dart';
import 'package:sisantri/shared/services/rfid_scan_service.dart';
import 'dart:async';

/// Provider untuk scan request ID
final scanRequestIdProvider = StateProvider<String?>((ref) => null);

/// Dialog untuk scan RFID menggunakan external scanner
class RfidScanDialog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final Function(String rfidCardId) onSuccess;

  const RfidScanDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.onSuccess,
  });

  @override
  ConsumerState<RfidScanDialog> createState() => _RfidScanDialogState();
}

class _RfidScanDialogState extends ConsumerState<RfidScanDialog> {
  String? _requestId;
  StreamSubscription? _scanSubscription;
  bool _isCreatingRequest = false;

  @override
  void initState() {
    super.initState();
    _createScanRequest();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // Cancel request jika dialog ditutup
    if (_requestId != null) {
      RfidScanService.cancelScanRequest(_requestId!);
    }
    super.dispose();
  }

  Future<void> _createScanRequest() async {
    setState(() {
      _isCreatingRequest = true;
    });

    try {
      final requestId = await RfidScanService.createScanRequest(
        userId: widget.userId,
        userName: widget.userName,
      );

      setState(() {
        _requestId = requestId;
        _isCreatingRequest = false;
      });

      // Listen ke perubahan status
      _scanSubscription = RfidScanService.watchScanRequest(requestId).listen(
        (config) {
          if (config == null) return;

          if (config.status == RfidScanStatus.success &&
              config.rfidCardId != null) {
            widget.onSuccess(config.rfidCardId!);
            Navigator.of(context).pop();
          } else if (config.status == RfidScanStatus.failed) {
            _showError(config.errorMessage ?? 'Scan gagal');
          } else if (config.status == RfidScanStatus.cancelled) {
            _showError('Scan dibatalkan');
          }
        },
        onError: (error) {
          _showError('Error monitoring scan: $error');
        },
      );
    } catch (e) {
      setState(() {
        _isCreatingRequest = false;
      });

      // Tampilkan error dan tutup dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _cancelScan() {
    if (_requestId != null) {
      RfidScanService.cancelScanRequest(_requestId!);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelScan();
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Scan Kartu RFID',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                _isCreatingRequest
                    ? 'Mempersiapkan scanner...'
                    : 'Tempelkan kartu RFID Anda pada alat scanner yang tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Loading indicator
              if (_isCreatingRequest || _requestId != null)
                Column(
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isCreatingRequest ? 'Menyiapkan...' : 'Menunggu scan...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pastikan alat scanner RFID sudah aktif dan terhubung',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelScan,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Function helper untuk show dialog
/// Cek apakah ada request aktif dulu sebelum membuka dialog
Future<void> showRfidScanDialog({
  required BuildContext context,
  required String userId,
  required String userName,
  required Function(String rfidCardId) onSuccess,
}) async {
  // Cek apakah ada request aktif
  try {
    final activeRequest = await RfidScanService.getActiveRequest();

    if (activeRequest != null && context.mounted) {
      // Ada request aktif dari user lain
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scanner Sedang Digunakan'),
          content: Text(
            'Scanner sedang digunakan oleh ${activeRequest.userName}.\n\nApakah Anda ingin membatalkan request tersebut?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );

      if (shouldCancel == true && context.mounted) {
        // Cancel request yang ada
        await RfidScanService.cancelScanRequest(activeRequest.id);

        // Tunggu sebentar
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        return; // User memilih tidak membatalkan
      }
    }
  } catch (e) {
    // Error saat cek active request, lanjutkan saja
  }

  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RfidScanDialog(
      userId: userId,
      userName: userName,
      onSuccess: onSuccess,
    ),
  );
}
