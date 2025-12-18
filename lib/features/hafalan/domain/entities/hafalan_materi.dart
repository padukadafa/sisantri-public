import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity untuk materi hafalan
/// Tipe: alquran (auto-generated), doa, tambahan
class HafalanMateri {
  final String id;
  final String nama; // Nama materi
  final String tipe; // 'alquran', 'doa', 'tambahan'
  final String? link; // Link ke resource (PDF, video, dll)
  final DateTime createdAt;
  final String? createdBy; // Admin yang membuat
  final bool isActive;
  final int urutan; // Urutan tampilan

  const HafalanMateri({
    required this.id,
    required this.nama,
    required this.tipe,
    this.link,
    required this.createdAt,
    this.createdBy,
    this.isActive = true,
    this.urutan = 0,
  });

  factory HafalanMateri.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HafalanMateri(
      id: doc.id,
      nama: data['nama'] ?? '',
      tipe: data['tipe'] ?? '',
      link: data['link'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isActive: data['isActive'] ?? true,
      urutan: data['urutan'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'tipe': tipe,
      'link': link,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'urutan': urutan,
    };
  }

  HafalanMateri copyWith({
    String? id,
    String? nama,
    String? tipe,
    String? link,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    int? urutan,
  }) {
    return HafalanMateri(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      urutan: urutan ?? this.urutan,
    );
  }
}
