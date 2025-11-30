import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/shared/models/rfid_scan_config_model.dart';

/// Service untuk mengelola scan RFID via external scanner
class RfidScanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _configCollection = 'rfid_scan_config';

  /// Buat request scan RFID baru
  /// Ini akan dipanggil dari aplikasi mobile ketika user ingin mendaftar RFID
  /// Hanya 1 scan request yang bisa aktif pada satu waktu
  static Future<String> createScanRequest({
    required String userId,
    required String userName,
  }) async {
    try {
      // Cek apakah ada request aktif (dari user manapun)
      final activeRequests = await _firestore
          .collection(_configCollection)
          .where('isActive', isEqualTo: true)
          .where('status', whereIn: ['waiting', 'scanning'])
          .get();

      // Jika ada request aktif, throw error
      if (activeRequests.docs.isNotEmpty) {
        final activeRequest = activeRequests.docs.first.data();
        throw Exception(
          'Scanner sedang digunakan oleh ${activeRequest['userName']}. Silakan tunggu atau batalkan request tersebut.',
        );
      }

      // Buat request baru
      final docRef = await _firestore.collection(_configCollection).add({
        'userId': userId,
        'userName': userName,
        'status': RfidScanStatus.waiting.value,
        'requestedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Update dengan ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create scan request: $e');
    }
  }

  /// Stream untuk memonitor status scan
  /// Aplikasi mobile akan listen ke stream ini untuk mendapatkan hasil scan
  static Stream<RfidScanConfigModel?> watchScanRequest(String requestId) {
    return _firestore
        .collection(_configCollection)
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return RfidScanConfigModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
        });
  }

  /// Cancel request scan
  static Future<void> cancelScanRequest(String requestId) async {
    try {
      await _firestore.collection(_configCollection).doc(requestId).update({
        'status': RfidScanStatus.cancelled.value,
        'isActive': false,
        'errorMessage': 'Cancelled by user',
      });
    } catch (e) {
      throw Exception('Failed to cancel scan request: $e');
    }
  }

  /// Update status scan (dipanggil dari scanner/backend ketika scan berhasil/gagal)
  /// Method ini akan dipanggil oleh alat scanner RFID
  static Future<void> updateScanStatus({
    required String requestId,
    required RfidScanStatus status,
    String? rfidCardId,
    String? errorMessage,
    String? scannedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
        'scannedAt': FieldValue.serverTimestamp(),
      };

      if (rfidCardId != null) {
        updateData['rfidCardId'] = rfidCardId;
      }

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      if (scannedBy != null) {
        updateData['scannedBy'] = scannedBy;
      }

      if (status == RfidScanStatus.success ||
          status == RfidScanStatus.failed ||
          status == RfidScanStatus.cancelled) {
        updateData['isActive'] = false;
      }

      await _firestore
          .collection(_configCollection)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update scan status: $e');
    }
  }

  /// Get active scan requests (untuk scanner monitor)
  /// Method ini akan dipanggil oleh alat scanner untuk mendapatkan request yang perlu di-scan
  static Stream<List<RfidScanConfigModel>> watchActiveScanRequests() {
    return _firestore
        .collection(_configCollection)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: RfidScanStatus.waiting.value)
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    RfidScanConfigModel.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList();
        });
  }

  static Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_configCollection).doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete scan request: $e');
    }
  }

  /// Cleanup old requests (dipanggil secara periodik)
  static Future<void> cleanupOldRequests({int olderThanMinutes = 30}) async {
    try {
      final cutoffTime = DateTime.now().subtract(
        Duration(minutes: olderThanMinutes),
      );

      final oldRequests = await _firestore
          .collection(_configCollection)
          .where('requestedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in oldRequests.docs) {
        batch.update(doc.reference, {
          'status': RfidScanStatus.failed.value,
          'isActive': false,
          'errorMessage': 'Request timeout',
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old requests: $e');
    }
  }

  /// Get scan history untuk user tertentu
  static Future<List<RfidScanConfigModel>> getScanHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_configCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                RfidScanConfigModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get scan history: $e');
    }
  }

  /// Cek apakah ada scan request yang sedang aktif
  static Future<RfidScanConfigModel?> getActiveRequest() async {
    try {
      final snapshot = await _firestore
          .collection(_configCollection)
          .where('isActive', isEqualTo: true)
          .where('status', whereIn: ['waiting', 'scanning'])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return RfidScanConfigModel.fromJson({'id': doc.id, ...doc.data()});
    } catch (e) {
      throw Exception('Failed to get active request: $e');
    }
  }

  /// Cancel semua active requests (untuk admin)
  static Future<void> cancelAllActiveRequests() async {
    try {
      final activeRequests = await _firestore
          .collection(_configCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in activeRequests.docs) {
        batch.update(doc.reference, {
          'status': RfidScanStatus.cancelled.value,
          'isActive': false,
          'errorMessage': 'Cancelled by admin',
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cancel all requests: $e');
    }
  }
}
