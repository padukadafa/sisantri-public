import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity untuk progress hafalan santri
class HafalanProgress {
  final String id;
  final String santriId;
  final String materiId;
  final String status; // 'belum', 'proses', 'selesai'
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String? guruPengujiId; // ID guru yang mengkonfirmasi
  final String? guruPengujiName;
  final String? catatan; // Catatan dari guru
  final int? nilai; // Nilai 1-100
  final DateTime createdAt;
  final DateTime updatedAt;

  const HafalanProgress({
    required this.id,
    required this.santriId,
    required this.materiId,
    this.status = 'belum',
    this.tanggalMulai,
    this.tanggalSelesai,
    this.guruPengujiId,
    this.guruPengujiName,
    this.catatan,
    this.nilai,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HafalanProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HafalanProgress(
      id: doc.id,
      santriId: data['santriId'] ?? '',
      materiId: data['materiId'] ?? '',
      status: data['status'] ?? 'belum',
      tanggalMulai: (data['tanggalMulai'] as Timestamp?)?.toDate(),
      tanggalSelesai: (data['tanggalSelesai'] as Timestamp?)?.toDate(),
      guruPengujiId: data['guruPengujiId'],
      guruPengujiName: data['guruPengujiName'],
      catatan: data['catatan'],
      nilai: data['nilai'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santriId': santriId,
      'materiId': materiId,
      'status': status,
      'tanggalMulai': tanggalMulai != null
          ? Timestamp.fromDate(tanggalMulai!)
          : null,
      'tanggalSelesai': tanggalSelesai != null
          ? Timestamp.fromDate(tanggalSelesai!)
          : null,
      'guruPengujiId': guruPengujiId,
      'guruPengujiName': guruPengujiName,
      'catatan': catatan,
      'nilai': nilai,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HafalanProgress copyWith({
    String? id,
    String? santriId,
    String? materiId,
    String? status,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? guruPengujiId,
    String? guruPengujiName,
    String? catatan,
    int? nilai,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HafalanProgress(
      id: id ?? this.id,
      santriId: santriId ?? this.santriId,
      materiId: materiId ?? this.materiId,
      status: status ?? this.status,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      guruPengujiId: guruPengujiId ?? this.guruPengujiId,
      guruPengujiName: guruPengujiName ?? this.guruPengujiName,
      catatan: catatan ?? this.catatan,
      nilai: nilai ?? this.nilai,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
