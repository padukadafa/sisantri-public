import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum untuk status scan RFID
enum RfidScanStatus {
  waiting('waiting'),
  scanning('scanning'),
  success('success'),
  failed('failed'),
  cancelled('cancelled');

  const RfidScanStatus(this.value);
  final String value;

  static RfidScanStatus fromString(String value) {
    return RfidScanStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RfidScanStatus.waiting,
    );
  }
}

/// Model untuk konfigurasi scan RFID
class RfidScanConfigModel {
  final String id;
  final String userId;
  final String userName;
  final RfidScanStatus status;
  final String? rfidCardId;
  final String? errorMessage;
  final DateTime? requestedAt;
  final DateTime? scannedAt;
  final String? scannedBy; // Device ID scanner
  final bool isActive;

  const RfidScanConfigModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    this.rfidCardId,
    this.errorMessage,
    this.requestedAt,
    this.scannedAt,
    this.scannedBy,
    this.isActive = true,
  });

  /// Factory constructor dari JSON
  factory RfidScanConfigModel.fromJson(Map<String, dynamic> json) {
    return RfidScanConfigModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      status: RfidScanStatus.fromString(json['status'] as String? ?? 'waiting'),
      rfidCardId: json['rfidCardId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      requestedAt: json['requestedAt'] != null
          ? (json['requestedAt'] is Timestamp
                ? (json['requestedAt'] as Timestamp).toDate()
                : json['requestedAt'] as DateTime)
          : null,
      scannedAt: json['scannedAt'] != null
          ? (json['scannedAt'] is Timestamp
                ? (json['scannedAt'] as Timestamp).toDate()
                : json['scannedAt'] as DateTime)
          : null,
      scannedBy: json['scannedBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'status': status.value,
      'rfidCardId': rfidCardId,
      'errorMessage': errorMessage,
      'requestedAt': requestedAt,
      'scannedAt': scannedAt,
      'scannedBy': scannedBy,
      'isActive': isActive,
    };
  }

  /// Copy with
  RfidScanConfigModel copyWith({
    String? id,
    String? userId,
    String? userName,
    RfidScanStatus? status,
    String? rfidCardId,
    String? errorMessage,
    DateTime? requestedAt,
    DateTime? scannedAt,
    String? scannedBy,
    bool? isActive,
  }) {
    return RfidScanConfigModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      rfidCardId: rfidCardId ?? this.rfidCardId,
      errorMessage: errorMessage ?? this.errorMessage,
      requestedAt: requestedAt ?? this.requestedAt,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedBy: scannedBy ?? this.scannedBy,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'RfidScanConfigModel(id: $id, userId: $userId, status: ${status.value}), rfidCardId: $rfidCardId, errorMessage: $errorMessage, isActive: $isActive)';
  }
}
