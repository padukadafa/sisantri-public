import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';
import 'package:sisantri/shared/services/presensi_service.dart';
import 'package:sisantri/shared/services/announcement_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import '../models/user_model.dart';
import '../models/jadwal_kegiatan_model.dart';
import '../models/presensi_model.dart';
import '../models/leaderboard_model.dart';

/// Service untuk mengelola operasi Firestore
/// Note: Untuk operasi pengumuman, gunakan AnnouncementService
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== USER OPERATIONS =====

  /// Get semua users
  static Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      throw Exception('Error mengambil data user: $e');
    }
  }

  /// Update poin user
  static Future<void> updateUserPoin(String userId, int poin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'poin': FieldValue.increment(poin),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error mengupdate poin user: $e');
    }
  }

  // ===== PRESENSI OPERATIONS =====

  /// Get presensi by user ID
  static Stream<List<PresensiModel>> getPresensiByUser(String userId) {
    return _firestore
        .collection('presensi')
        .where('userId', isEqualTo: userId)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PresensiModel.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  /// Tambah presensi
  static Future<void> addPresensi(PresensiModel presensi) async {
    try {
      await _firestore.collection('presensi').add(presensi.toJson());

      final poin = presensi.poin;
      await updateUserPoin(presensi.userId, poin);

      // Update aggregates
      await PresensiAggregateService.updateAggregates(
        userId: presensi.userId,
        tanggal: presensi.timestamp ?? DateTime.now(),
        status: presensi.status.name,
        poin: presensi.poin,
      );
    } catch (e) {
      throw Exception('Error menambah presensi: $e');
    }
  }

  // ===== LEADERBOARD OPERATIONS =====

  static Future<int> calculateUserPoints(String userId) async {
    try {
      // Ambil semua presensi hadir user
      final presensiSnapshot = await _firestore
          .collection('presensi')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'hadir')
          .get();

      int totalPoin = 0;

      // Hitung poin dari setiap presensi
      for (final presensiDoc in presensiSnapshot.docs) {
        final presensiData = presensiDoc.data();
        final jadwalId =
            presensiData['jadwalId'] as String? ??
            presensiData['activity'] as String? ??
            '';

        if (jadwalId.isNotEmpty) {
          // Ambil data jadwal untuk mendapatkan poin
          final jadwalDoc = await _firestore
              .collection('jadwal')
              .doc(jadwalId)
              .get();

          if (jadwalDoc.exists) {
            final jadwalData = jadwalDoc.data();
            final poin = jadwalData?['poin'] as int? ?? 1;
            totalPoin += poin;
          }
        }
      }

      return totalPoin;
    } catch (e) {
      return 0;
    }
  }

  /// Get leaderboard santri
  static Stream<List<LeaderboardModel>> getLeaderboard() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'santri')
        .snapshots()
        .asyncMap((snapshot) async {
          final users = snapshot.docs
              .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

          // Hitung poin untuk setiap user
          final List<Map<String, dynamic>> userWithPoints = [];

          for (final user in users) {
            final totalPoin = await calculateUserPoints(user.id);
            userWithPoints.add({'user': user, 'poin': totalPoin});
          }

          // Sort berdasarkan poin descending
          userWithPoints.sort(
            (a, b) => (b['poin'] as int).compareTo(a['poin'] as int),
          );

          // Convert ke LeaderboardModel dengan ranking
          return userWithPoints.take(50).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final user = data['user'] as UserModel;
            final poin = data['poin'] as int;

            return LeaderboardModel(
              id: user.id,
              userId: user.id,
              nama: user.nama,
              poin: poin,
              fotoProfil: user.fotoProfil,
              ranking: index + 1,
              lastUpdated: user.updatedAt,
            );
          }).toList();
        });
  }

  /// Get leaderboard mingguan
  static Stream<List<LeaderboardModel>> getWeeklyLeaderboard() {
    // TODO: Implement logic untuk poin mingguan
    return getLeaderboard();
  }

  /// Get leaderboard bulanan
  static Stream<List<LeaderboardModel>> getMonthlyLeaderboard() {
    // TODO: Implement logic untuk poin bulanan
    return getLeaderboard();
  }

  // ===== DASHBOARD DATA =====

  /// Get data dashboard untuk santri
  static Future<Map<String, dynamic>> getDashboardData(String userId) async {
    try {
      final user = await getUserById(userId);

      final todayPresensi = await PresensiService.getPresensiToday(
        userId: userId,
      );

      // Get upcoming kegiatan
      final upcomingKegiatanSnapshot = await _firestore
          .collection('jadwal_kegiatan')
          .where('tanggal', isGreaterThan: DateTime.now())
          .orderBy('tanggal')
          .limit(3)
          .get();

      final upcomingKegiatan = upcomingKegiatanSnapshot.docs
          .map(
            (doc) =>
                JadwalKegiatanModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();

      // Get recent pengumuman - use AnnouncementService
      final recentPengumumanStream = AnnouncementService.getRecentPengumuman(
        limit: 3,
      );
      final recentPengumuman = await recentPengumumanStream.first;

      return {
        'user': user,
        'todayPresensi': todayPresensi,
        'upcomingKegiatan': upcomingKegiatan,
        'recentPengumuman': recentPengumuman,
      };
    } catch (e) {
      throw Exception('Error mengambil data dashboard: $e');
    }
  }

  // ===== PENGUMUMAN OPERATIONS (Wrapper untuk AnnouncementService) =====

  /// Get recent pengumuman (wrapper method)
  /// Gunakan AnnouncementService.getRecentPengumuman() untuk lebih banyak opsi
  static Stream<List<AnnouncementModel>> getRecentPengumuman({int limit = 5}) {
    return AnnouncementService.getRecentPengumuman(limit: limit);
  }

  /// Get all pengumuman (wrapper method)
  /// Gunakan AnnouncementService untuk operasi pengumuman lainnya
  static Stream<List<AnnouncementModel>> getAllPengumuman() {
    return AnnouncementService.getAllPengumuman();
  }
}
