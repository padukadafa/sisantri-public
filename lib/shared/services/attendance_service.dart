import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/jadwal_kegiatan_model.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import '../models/user_model.dart';
import '../models/presensi_model.dart';
import 'presensi_aggregate_service.dart';

/// Service untuk mengelola attendance/presensi
class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> generateDefaultAttendanceForJadwal({
    required String jadwalId,
    required String createdBy,
    required String createdByName,
    required JadwalModel jadwal,
    List<String>? specificSantriIds,
  }) async {
    try {
      List<UserModel> activeSantri;

      if (specificSantriIds != null && specificSantriIds.isNotEmpty) {
        final userFutures = specificSantriIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        );
        final userDocs = await Future.wait(userFutures);

        activeSantri = userDocs
            .where((doc) => doc.exists)
            .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()!}))
            .where((user) => user.isSantri)
            .toList();
      } else {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'santri')
            .where("statusAktif", isEqualTo: true)
            .get();

        activeSantri = usersSnapshot.docs
            .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList();
      }

      final existingRecords = await _firestore
          .collection('presensi')
          .where('jadwalId', isEqualTo: jadwalId)
          .get();

      final existingSantriIds = existingRecords.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet();

      final santriNeedingRecords = activeSantri
          .where((santri) => !existingSantriIds.contains(santri.id))
          .toList();

      if (santriNeedingRecords.isEmpty) return;

      final batch = _firestore.batch();
      final timestamp = Timestamp.now();

      for (final santri in santriNeedingRecords) {
        final newRecordRef = _firestore.collection('presensi').doc();
        final attendanceData = {
          'userId': santri.id,
          'userName': santri.nama,
          'jadwalId': jadwalId,
          'status': 'alpha',
          'timestamp': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
          'recordedBy': createdBy,
          'recordedByName': createdByName,
          'isManual': true,
          'keterangan': 'Auto-generated default record',
          'poin': jadwal.poin,
        };

        batch.set(newRecordRef, attendanceData);
      }

      await batch.commit();

      // Update aggregates untuk semua santri yang dibuat record alpha-nya
      // Menggunakan versi optimized tanpa read operations
      final tanggalJadwal = jadwal.tanggal;
      for (final santri in santriNeedingRecords) {
        await PresensiAggregateService.updateAggregates(
          userId: santri.id,
          tanggal: tanggalJadwal,
          status: 'alpha',
          poin: 0, // Alpha tidak dapat poin
        );
      }

      await _firestore.collection('jadwal').doc(jadwalId).update({
        'totalPresensi': santriNeedingRecords.length,
        'presensiAlpha': santriNeedingRecords.length,
      });
    } catch (e) {
      throw Exception('Failed to generate default attendance: $e');
    }
  }

  static Future<void> updateAttendanceStatus({
    required String attendanceId,
    required StatusPresensi newStatus,
    required String updatedBy,
    required String updatedByName,
    String? keterangan,
  }) async {
    try {
      // Get old data untuk update aggregate
      final oldDoc = await _firestore
          .collection('presensi')
          .doc(attendanceId)
          .get();
      final oldData = oldDoc.data();
      final oldStatus = oldData?['status'] as String?;
      final oldPoin = oldData?['poinDiperoleh'] as int? ?? 0;
      final userId = oldData?['userId'] as String;
      final timestamp = oldData?['timestamp'] as Timestamp?;

      // Get poin dari jadwal untuk status baru
      int newPoin = 0;
      if (newStatus == StatusPresensi.hadir) {
        final jadwalId = oldData?['jadwalId'] as String?;
        if (jadwalId != null) {
          final jadwalDoc = await _firestore
              .collection('jadwal')
              .doc(jadwalId)
              .get();
          newPoin = jadwalDoc.data()?['poin'] as int? ?? 1;
        }
      }

      // Update presensi record
      await _firestore.collection('presensi').doc(attendanceId).update({
        'status': newStatus.label.toLowerCase(),
        'poinDiperoleh': newPoin,
        'keterangan': keterangan ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
        'updatedByName': updatedByName,
      });

      // Update aggregates menggunakan batch untuk semua periode
      if (oldStatus != null && timestamp != null) {
        final batch = _firestore.batch();
        final tanggal = timestamp.toDate();
        final periodes = ['daily', 'weekly', 'monthly', 'semester', 'yearly'];
        final now = DateTime.now();

        for (final periode in periodes) {
          final periodeKey = PresensiAggregateService.getPeriodeKey(
            periode,
            tanggal,
          );
          final docId = '${userId}_${periode}_$periodeKey';
          final docRef = _firestore
              .collection('presensi_aggregates')
              .doc(docId);

          final updateData = <String, dynamic>{
            'lastUpdated': Timestamp.fromDate(now),
          };

          // Decrement old status counter
          if (oldStatus.isNotEmpty) {
            switch (oldStatus) {
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
            // Decrement old poin
            if (oldPoin > 0) {
              updateData['totalPoin'] = FieldValue.increment(-oldPoin);
            }
          }

          // Increment new status counter
          final newStatusLabel = newStatus.label.toLowerCase();
          switch (newStatusLabel) {
            case 'hadir':
              updateData['totalHadir'] = FieldValue.increment(1);
              break;
            case 'izin':
              updateData['totalIzin'] = FieldValue.increment(1);
              break;
            case 'sakit':
              updateData['totalSakit'] = FieldValue.increment(1);
              break;
            case 'alpha':
              updateData['totalAlpha'] = FieldValue.increment(1);
              break;
          }
          // Increment new poin
          if (newPoin > 0) {
            updateData['totalPoin'] = FieldValue.increment(newPoin);
          }

          // Check if document exists first
          final docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            batch.update(docRef, updateData);
          } else {
            // Create with initial values if doesn't exist
            final startDate = PeriodeKeyHelper.getStartDate(periode, tanggal);
            final endDate = PeriodeKeyHelper.getEndDate(periode, tanggal);
            batch.set(docRef, {
              'userId': userId,
              'periode': periode,
              'periodeKey': periodeKey,
              'startDate': Timestamp.fromDate(startDate),
              'endDate': Timestamp.fromDate(endDate),
              'totalHadir': 0,
              'totalIzin': 0,
              'totalSakit': 0,
              'totalAlpha': 0,
              'totalPoin': 0,
              ...updateData,
            });
          }
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to update attendance status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceForJadwal(
    String jadwalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('presensi')
          .where('jadwalId', isEqualTo: jadwalId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance for jadwal: $e');
    }
  }
}
