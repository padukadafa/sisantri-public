import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/models/jadwal_kegiatan_model.dart';

/// Provider untuk notifikasi real-time
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) {
    return Stream.value([]);
  }

  // Kombinasi notifikasi dari berbagai sumber
  return Stream.periodic(const Duration(minutes: 5), (index) async {
    try {
      List<Map<String, dynamic>> notifications = [];

      // Notifikasi pengumuman penting
      final recentPengumuman =
          await FirestoreService.getRecentPengumuman().first;
      for (final pengumuman in recentPengumuman.take(2)) {
        if (pengumuman.isHighPriority) {
          notifications.add({
            'type': 'pengumuman',
            'title': 'Pengumuman Penting',
            'message': pengumuman.judul,
            'time': DateFormat(
              'dd MMM yyyy HH:mm',
            ).format(pengumuman.createdAt),
            'icon': Icons.campaign,
            'color': Colors.red,
          });
        }
      }

      // Notifikasi kegiatan hari ini
      final upcomingKegiatan = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('tanggalMulai', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('tanggalMulai')
          .limit(5)
          .get()
          .then(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => JadwalKegiatanModel.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }),
                )
                .toList(),
          );
      for (final kegiatan in upcomingKegiatan) {
        if (kegiatan.isToday) {
          notifications.add({
            'type': 'kegiatan',
            'title': 'Kegiatan Hari Ini',
            'message': kegiatan.nama,
            'time': kegiatan.formattedWaktu,
            'icon': Icons.event,
            'color': Colors.blue,
          });
        }
      }

      return notifications;
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }).asyncMap((future) => future);
});
