import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/presensi_aggregate_model.dart';
import 'package:sisantri/features/santri/presensi/data/models/presensi_model.dart';

/// Service untuk mengelola agregasi data presensi
class PresensiAggregateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _aggregateCollection = 'presensi_aggregates';

  /// Update agregasi ketika ada presensi baru atau update
  /// Dipanggil setiap kali ada perubahan presensi
  static Future<void> updateAggregates({
    required String userId,
    required DateTime tanggal,
    required String status,
    required int poin,
    String? oldStatus,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Update semua periode
      final periodes = ['daily', 'weekly', 'monthly', 'semester', 'yearly'];

      for (final periode in periodes) {
        final periodeKey = _getPeriodeKey(periode, tanggal);
        final docId = '${userId}_${periode}_$periodeKey';
        final docRef = _firestore.collection(_aggregateCollection).doc(docId);

        final startDate = PeriodeKeyHelper.getStartDate(periode, tanggal);
        final endDate = PeriodeKeyHelper.getEndDate(periode, tanggal);

        Map<String, dynamic> updateData = {
          'lastUpdated': Timestamp.fromDate(now),
        };

        if (oldStatus != null) {
          updateData['total${_capitalize(oldStatus)}'] = FieldValue.increment(
            -1,
          );
        }

        updateData['total${_capitalize(status)}'] = FieldValue.increment(1);
        updateData['totalPoin'] = FieldValue.increment(poin);

        // Check if document exists
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          batch.update(docRef, updateData);
        } else {
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
    } catch (e) {
      throw Exception('Failed to update aggregates: $e');
    }
  }

  /// Get aggregate untuk periode tertentu
  static Future<PresensiAggregateModel?> getAggregate({
    required String userId,
    required String periode,
    required DateTime date,
  }) async {
    try {
      final periodeKey = _getPeriodeKey(periode, date);
      final docId = '${userId}_${periode}_$periodeKey';

      final docSnapshot = await _firestore
          .collection(_aggregateCollection)
          .doc(docId)
          .get();

      if (!docSnapshot.exists) return null;

      return PresensiAggregateModel.fromJson({
        'id': docSnapshot.id,
        ...docSnapshot.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get aggregate: $e');
    }
  }

  /// Get multiple aggregates untuk rentang waktu
  static Future<List<PresensiAggregateModel>> getAggregates({
    required String userId,
    required String periode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startKey = _getPeriodeKey(periode, startDate);
      final endKey = _getPeriodeKey(periode, endDate);

      final querySnapshot = await _firestore
          .collection(_aggregateCollection)
          .where('userId', isEqualTo: userId)
          .where('periode', isEqualTo: periode)
          .where('periodeKey', isGreaterThanOrEqualTo: startKey)
          .where('periodeKey', isLessThanOrEqualTo: endKey)
          .orderBy('periodeKey', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                PresensiAggregateModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get aggregates: $e');
    }
  }

  /// Get aggregate summary untuk dashboard
  static Future<Map<String, PresensiAggregateModel?>> getAggregateSummary({
    required String userId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();

    try {
      final results = await Future.wait([
        getAggregate(userId: userId, periode: 'weekly', date: targetDate),
        getAggregate(userId: userId, periode: 'monthly', date: targetDate),
        getAggregate(userId: userId, periode: 'semester', date: targetDate),
        getAggregate(userId: userId, periode: 'yearly', date: targetDate),
      ]);

      return {
        'weekly': results[0],
        'monthly': results[1],
        'semester': results[2],
        'yearly': results[3],
      };
    } catch (e) {
      throw Exception('Failed to get aggregate summary: $e');
    }
  }

  /// Rebuild aggregate dari data presensi yang ada (untuk migrasi atau fix data)
  static Future<void> rebuildAggregates({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Query presensi
      Query query = _firestore
          .collection('presensi')
          .where('userId', isEqualTo: userId)
          .orderBy('tanggal');

      if (startDate != null) {
        query = query.where(
          'tanggal',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'tanggal',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final presensiSnapshot = await query.get();

      // Delete existing aggregates
      final aggregatesToDelete = await _firestore
          .collection(_aggregateCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final deleteBatch = _firestore.batch();
      for (final doc in aggregatesToDelete.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      // Rebuild aggregates
      for (final doc in presensiSnapshot.docs) {
        final presensi = PresensiModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        await updateAggregates(
          userId: userId,
          tanggal: presensi.tanggal,
          status: presensi.status.name, // use .name instead of .value
          poin: presensi.poinDiperoleh,
        );
      }
    } catch (e) {
      throw Exception('Failed to rebuild aggregates: $e');
    }
  }

  /// Get leaderboard dari aggregates (lebih cepat)
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    required String periode,
    required String periodeKey,
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_aggregateCollection)
          .where('periode', isEqualTo: periode)
          .where('periodeKey', isEqualTo: periodeKey)
          .orderBy('totalPoin', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] ?? '',
          'totalPoin': data['totalPoin'] ?? 0,
          'totalHadir': data['totalHadir'] ?? 0,
          'totalIzin': data['totalIzin'] ?? 0,
          'totalSakit': data['totalSakit'] ?? 0,
          'totalAlpha': data['totalAlpha'] ?? 0,
        };
      }).toList();
    } catch (e) {
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Stream aggregate untuk real-time updates
  static Stream<PresensiAggregateModel?> watchAggregate({
    required String userId,
    required String periode,
    required DateTime date,
  }) {
    final periodeKey = _getPeriodeKey(periode, date);
    final docId = '${userId}_${periode}_$periodeKey';

    return _firestore
        .collection(_aggregateCollection)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return PresensiAggregateModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
        });
  }

  // Helper methods
  static String _getPeriodeKey(String periode, DateTime date) {
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

  // Public getter untuk digunakan di service lain
  static String getPeriodeKey(String periode, DateTime date) {
    return _getPeriodeKey(periode, date);
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Delete aggregate (untuk cleanup)
  static Future<void> deleteAggregate({
    required String userId,
    required String periode,
    required DateTime date,
  }) async {
    try {
      final periodeKey = _getPeriodeKey(periode, date);
      final docId = '${userId}_${periode}_$periodeKey';

      await _firestore.collection(_aggregateCollection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete aggregate: $e');
    }
  }

  /// Get statistics untuk admin dashboard
  static Future<Map<String, dynamic>> getStatistics({
    required String periode,
    required String periodeKey,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_aggregateCollection)
          .where('periode', isEqualTo: periode)
          .where('periodeKey', isEqualTo: periodeKey)
          .get();

      int totalUsers = querySnapshot.docs.length;
      int totalHadir = 0;
      int totalIzin = 0;
      int totalSakit = 0;
      int totalAlpha = 0;
      int totalPoin = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalHadir += (data['totalHadir'] as int? ?? 0);
        totalIzin += (data['totalIzin'] as int? ?? 0);
        totalSakit += (data['totalSakit'] as int? ?? 0);
        totalAlpha += (data['totalAlpha'] as int? ?? 0);
        totalPoin += (data['totalPoin'] as int? ?? 0);
      }

      final totalPresensi = totalHadir + totalIzin + totalSakit + totalAlpha;
      final persentaseKehadiran = totalPresensi > 0
          ? (totalHadir / totalPresensi) * 100
          : 0.0;

      return {
        'totalUsers': totalUsers,
        'totalHadir': totalHadir,
        'totalIzin': totalIzin,
        'totalSakit': totalSakit,
        'totalAlpha': totalAlpha,
        'totalPoin': totalPoin,
        'totalPresensi': totalPresensi,
        'persentaseKehadiran': persentaseKehadiran,
      };
    } catch (e) {
      // Return empty statistics instead of throwing
      return {
        'totalUsers': 0,
        'totalHadir': 0,
        'totalIzin': 0,
        'totalSakit': 0,
        'totalAlpha': 0,
        'totalPoin': 0,
        'totalPresensi': 0,
        'persentaseKehadiran': 0.0,
      };
    }
  }
}
