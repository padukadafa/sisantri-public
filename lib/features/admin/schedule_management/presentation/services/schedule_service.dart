import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/helpers/messaging_helper.dart';
import 'package:sisantri/shared/models/jadwal_kegiatan_model.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/shared/services/attendance_service.dart';
import '../models/jadwal_kegiatan_model.dart';

/// Service untuk CRUD operations jadwal kegiatan
class ScheduleService {
  final FirebaseFirestore _firestore;

  ScheduleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Tambah jadwal baru dengan attendance generation
  Future<String> addJadwalWithAttendance(JadwalModel jadwal) async {
    try {
      final docRef = await _firestore.collection('jadwal').add(jadwal.toJson());

      await AttendanceService.generateDefaultAttendanceForJadwal(
        jadwalId: docRef.id,
        createdBy: 'admin',
        createdByName: 'Admin',
        jadwal: jadwal,
      );

      // Step 3: Send notification about new schedule
      await MessagingHelper.sendPengumumanToSantri(
        title: 'Jadwal Baru Ditambahkan',
        message:
            '${jadwal.nama} - ${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}',
      );

      return docRef.id;
    } catch (e) {
      _showError('Gagal menambahkan jadwal: $e');
      rethrow;
    }
  }

  /// Update jadwal existing
  Future<void> updateJadwalData(JadwalKegiatan jadwal) async {
    try {
      await _firestore
          .collection('jadwal')
          .doc(jadwal.id)
          .update(jadwal.toJson());
    } catch (e) {
      _showError('Gagal mengupdate jadwal: $e');
      rethrow;
    }
  }

  Future<String> addJadwal(JadwalKegiatan jadwal) async {
    try {
      final docRef = await _firestore.collection('jadwal').add(jadwal.toJson());

      _showSuccess('Jadwal berhasil ditambahkan');
      return docRef.id;
    } catch (e) {
      _showError('Gagal menambahkan jadwal: $e');
      rethrow;
    }
  }

  Future<void> updateJadwal(JadwalKegiatan jadwal) async {
    try {
      await _firestore
          .collection('jadwal')
          .doc(jadwal.id)
          .update(jadwal.toJson());

      _showSuccess('Jadwal berhasil diupdate');
    } catch (e) {
      _showError('Gagal mengupdate jadwal: $e');
      rethrow;
    }
  }

  /// Hapus jadwal (soft delete) dan update aggregates
  Future<void> deleteJadwal(String id) async {
    try {
      // Get jadwal data untuk tanggal dan presensi yang terkait
      final jadwalDoc = await _firestore.collection('jadwal').doc(id).get();

      if (jadwalDoc.exists) {
        final jadwalData = jadwalDoc.data();
        final tanggalJadwal = (jadwalData?['tanggal'] as Timestamp?)?.toDate();

        // Get semua presensi untuk jadwal ini
        final presensiSnapshot = await _firestore
            .collection('presensi')
            .where('jadwalId', isEqualTo: id)
            .get();

        // Decrement aggregate untuk setiap presensi (hapus dari counter)
        for (final presensiDoc in presensiSnapshot.docs) {
          final presensiData = presensiDoc.data();
          final userId = presensiData['userId'] as String?;
          final status = presensiData['status'] as String?;
          final poinDiperoleh = presensiData['poinDiperoleh'] as int? ?? 0;

          if (userId != null && status != null && tanggalJadwal != null) {
            // Decrement aggregate dengan cara set status baru = null
            // dan oldStatus = status yang ingin dikurangi
            final batch = _firestore.batch();
            final periodes = [
              'daily',
              'weekly',
              'monthly',
              'semester',
              'yearly',
            ];

            for (final periode in periodes) {
              final periodeKey = _getPeriodeKey(periode, tanggalJadwal);
              final docId = '${userId}_${periode}_$periodeKey';
              final docRef = _firestore
                  .collection('presensi_aggregates')
                  .doc(docId);

              // Decrement counter status dan poin
              final updateData = <String, dynamic>{
                'lastUpdated': Timestamp.now(),
              };

              // Decrement status counter
              switch (status) {
                case 'hadir':
                  updateData['totalHadir'] = FieldValue.increment(-1);
                  break;
                case 'izin':
                  updateData['totalIzin'] = FieldValue.increment(-1);
                  break;
                case 'sakit':
                  updateData['totalSakit'] = FieldValue.increment(-1);
                  break;
                case 'alpha':
                  updateData['totalAlpha'] = FieldValue.increment(-1);
                  break;
              }

              // Decrement poin
              if (poinDiperoleh > 0) {
                updateData['totalPoin'] = FieldValue.increment(-poinDiperoleh);
              }

              batch.update(docRef, updateData);
            }

            await batch.commit();
          }
        }

        // Hapus semua presensi terkait jadwal ini
        final batch = _firestore.batch();
        for (final doc in presensiSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Soft delete jadwal
      await _firestore.collection('jadwal').doc(id).update({
        'isAktif': false,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
      });

      _showSuccess('Jadwal berhasil dihapus');
    } catch (e) {
      _showError('Gagal menghapus jadwal: $e');
      rethrow;
    }
  }

  // Helper method untuk generate periode key
  String _getPeriodeKey(String periode, DateTime date) {
    switch (periode) {
      case 'daily':
        return PeriodeKeyHelper.daily(date);
      case 'weekly':
        return PeriodeKeyHelper.weekly(date);
      case 'monthly':
        return PeriodeKeyHelper.monthly(date);
      case 'semester':
        return PeriodeKeyHelper.semester(date);
      case 'yearly':
        return PeriodeKeyHelper.yearly(date);
      default:
        return PeriodeKeyHelper.daily(date);
    }
  }

  /// Toggle status aktif jadwal
  Future<void> toggleJadwalStatus(String id, bool currentStatus) async {
    try {
      await _firestore.collection('jadwal').doc(id).update({
        'isAktif': !currentStatus,
      });

      final status = !currentStatus ? 'diaktifkan' : 'dinonaktifkan';
      _showSuccess('Jadwal berhasil $status');
    } catch (e) {
      _showError('Gagal mengubah status jadwal: $e');
      rethrow;
    }
  }

  /// Duplicate jadwal dengan tanggal baru
  Future<String> duplicateJadwal(
    JadwalKegiatan originalJadwal,
    DateTime newDate,
  ) async {
    try {
      final duplicatedJadwal = JadwalKegiatan(
        id: '', // Will be generated by Firestore
        nama: '${originalJadwal.nama} (Copy)',
        deskripsi: originalJadwal.deskripsi,
        tanggal: newDate,
        waktuMulai: originalJadwal.waktuMulai,
        waktuSelesai: originalJadwal.waktuSelesai,
        tempat: originalJadwal.tempat,
        kategori: originalJadwal.kategori,
        materiId: originalJadwal.materiId,
        materiNama: originalJadwal.materiNama,
        surah: originalJadwal.surah,
        ayatMulai: originalJadwal.ayatMulai,
        ayatSelesai: originalJadwal.ayatSelesai,
        halamanMulai: originalJadwal.halamanMulai,
        halamanSelesai: originalJadwal.halamanSelesai,
        catatan: originalJadwal.catatan,
        isAktif: true,
        createdAt: DateTime.now(),
      );

      return await addJadwal(duplicatedJadwal);
    } catch (e) {
      _showError('Gagal menduplikasi jadwal: $e');
      rethrow;
    }
  }

  /// Get jadwal berdasarkan tanggal range
  Future<List<JadwalKegiatan>> getJadwalByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('jadwal')
          .where(
            'tanggal',
            isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
          )
          .where('tanggal', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .where('isAktif', isEqualTo: true)
          .orderBy('tanggal')
          .orderBy('waktuMulai')
          .get();

      return snapshot.docs
          .map((doc) => JadwalKegiatan.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _showError('Gagal mengambil jadwal: $e');
      return [];
    }
  }

  /// Helper methods untuk menampilkan pesan
  void _showError(String message) {
    // TODO: Implement proper error handling
    print('Error: $message');
  }

  void _showSuccess(String message) {
    // TODO: Implement proper success handling
    print('Success: $message');
  }
}
