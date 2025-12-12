import 'package:flutter/material.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'schedule_card_menu.dart';
import 'schedule_card_chips.dart';

/// Widget untuk menampilkan card jadwal individual
class ScheduleCard extends StatelessWidget {
  final JadwalModel jadwal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;

  const ScheduleCard({
    super.key,
    required this.jadwal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onDuplicate,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: jadwal.kategori.value == 'penting' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: jadwal.kategori.value == 'penting'
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      jadwal.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ScheduleCardMenu(
                    jadwal: jadwal,
                    onEdit:
                        onEdit ?? onTap, // Use onTap if onEdit is not provided
                    onDuplicate: onDuplicate,
                    onToggleStatus: onToggleStatus,
                    onDelete: onDelete,
                    onShare: onShare,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                jadwal.deskripsi ?? '',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${jadwal.waktuMulai ?? ''} - ${jadwal.waktuSelesai ?? ''}',
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      jadwal.tempat ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ScheduleCardChips(jadwal: jadwal),
            ],
          ),
        ),
      ),
    );
  }
}
