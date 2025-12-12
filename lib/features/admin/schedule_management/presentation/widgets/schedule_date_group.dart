import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import '../utils/schedule_helpers.dart';
import 'schedule_card.dart';

class ScheduleDateGroup extends StatelessWidget {
  final DateTime date;
  final List<JadwalModel> jadwalList;
  final Function(JadwalModel) onJadwalTap;
  final Function(JadwalModel)? onJadwalDelete;
  final bool isFirstGroup;

  const ScheduleDateGroup({
    super.key,
    required this.date,
    required this.jadwalList,
    required this.onJadwalTap,
    this.onJadwalDelete,
    this.isFirstGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedJadwal = List<JadwalModel>.from(jadwalList)
      ..sort((a, b) {
        final aTime = _parseTime(a.waktuMulai ?? '00:00');
        final bTime = _parseTime(b.waktuMulai ?? '00:00');
        final aMinutes = aTime.hour * 60 + aTime.minute;
        final bMinutes = bTime.hour * 60 + bTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

    final isToday = ScheduleHelpers.isToday(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          margin: EdgeInsets.only(bottom: 12, top: isFirstGroup ? 0 : 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isToday
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isToday ? Icons.today : Icons.calendar_today,
                size: 16,
                color: isToday ? AppTheme.primaryColor : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                ScheduleHelpers.formatDateHeader(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppTheme.primaryColor : Colors.grey[700],
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HARI INI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${sortedJadwal.length} kegiatan',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Activities for this date
        ...sortedJadwal.map(
          (jadwal) => ScheduleCard(
            jadwal: jadwal,
            onTap: () => onJadwalTap(jadwal),
            onDelete: onJadwalDelete != null
                ? () => onJadwalDelete!(jadwal)
                : null,
            onShare: () async {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      """
Assalamualaikum Wr Wb

Pengajian ppm ${jadwal.namaHari} Subuh (${jadwal.formattedTanggal})

Materi : ${jadwal.materiNama ?? ''}
Pemateri : ${jadwal.pemateriNama ?? ''}
Tempat : ${jadwal.tempat ?? ''}
Waktu : ${jadwal.formattedWaktuRange}

${jadwal.deskripsi != null ? '${jadwal.deskripsi}\n' : ''}

Bagi temen² yg berhalangan hadir bisa izin kepada pengurus kemahasiswaan & temen2 yg mau setor uang spp bisa diserahkan kepada mas faiz

Amal sholih semua santri apabila selesai kegiatan, bisa bersih bersih tempat masing masing

Kerjakan karena allah semoga allah paring aman sehat selamat lancar barokah dan sukses dunia akhiratnya

Alhamdulillah jazakumullahu khoiro
""",
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
