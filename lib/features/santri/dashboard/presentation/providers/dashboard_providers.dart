import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';
import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/jadwal_kegiatan_model.dart';
import 'package:sisantri/shared/models/presensi_model.dart';
import 'package:sisantri/shared/services/presensi_service.dart';

final dashboardUserProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) {
    return null;
  }

  // One-time fetch of user data (non-realtime)
  return await FirestoreService.getUserById(currentUser.uid);
});

final todayPresensiProvider = FutureProvider<PresensiModel?>((ref) async {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) return null;

  return await PresensiService.getCurrentPresensi(currentUser.uid);
});

final upcomingKegiatanProvider = StreamProvider<List<JadwalKegiatanModel>>((
  ref,
) {
  // Query jadwal upcoming langsung dari Firestore
  return FirebaseFirestore.instance
      .collection('jadwal')
      .where('tanggalMulai', isGreaterThanOrEqualTo: Timestamp.now())
      .orderBy('tanggalMulai')
      .limit(5)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) =>
                  JadwalKegiatanModel.fromJson({'id': doc.id, ...doc.data()}),
            )
            .toList(),
      );
});

final recentPengumumanProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return FirestoreService.getRecentPengumuman();
});

final dashboardDataProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final user = ref.watch(dashboardUserProvider);
  final todayPresensi = ref.watch(todayPresensiProvider);
  final upcomingKegiatan = ref.watch(upcomingKegiatanProvider);
  final recentPengumuman = ref.watch(recentPengumumanProvider);

  if (user.isLoading ||
      todayPresensi.isLoading ||
      upcomingKegiatan.isLoading ||
      recentPengumuman.isLoading) {
    return const AsyncValue.loading();
  }

  if (user.hasError) {
    return AsyncValue.error(user.error!, user.stackTrace!);
  }
  if (todayPresensi.hasError) {
    return AsyncValue.error(todayPresensi.error!, todayPresensi.stackTrace!);
  }
  if (upcomingKegiatan.hasError) {
    return AsyncValue.error(
      upcomingKegiatan.error!,
      upcomingKegiatan.stackTrace!,
    );
  }
  if (recentPengumuman.hasError) {
    return AsyncValue.error(
      recentPengumuman.error!,
      recentPengumuman.stackTrace!,
    );
  }

  return AsyncValue.data({
    'user': user.value,
    'todayPresensi': todayPresensi.value,
    'upcomingKegiatan': upcomingKegiatan.value ?? [],
    'recentPengumuman': recentPengumuman.value ?? [],
  });
});
