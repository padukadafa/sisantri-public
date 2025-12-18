import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity untuk materi hafalan
/// Tipe: alquran (auto-generated), doa, tambahan
class HafalanMateri {
  final String id;
  final String judul;
  final String tipe; // 'alquran', 'doa', 'tambahan'
  final String? konten; // Isi doa/tambahan, null untuk alquran
  final String? suratName; // Untuk alquran: nama surat
  final int? suratNumber; // Untuk alquran: nomor surat
  final int? ayatStart; // Untuk alquran: ayat mulai
  final int? ayatEnd; // Untuk alquran: ayat selesai
  final String? arabText; // Teks arab untuk doa
  final String? latinText; // Teks latin untuk doa
  final String? translation; // Terjemahan
  final DateTime createdAt;
  final String? createdBy; // Admin yang membuat
  final bool isActive;
  final int urutan; // Urutan tampilan

  const HafalanMateri({
    required this.id,
    required this.judul,
    required this.tipe,
    this.konten,
    this.suratName,
    this.suratNumber,
    this.ayatStart,
    this.ayatEnd,
    this.arabText,
    this.latinText,
    this.translation,
    required this.createdAt,
    this.createdBy,
    this.isActive = true,
    this.urutan = 0,
  });

  factory HafalanMateri.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HafalanMateri(
      id: doc.id,
      judul: data['judul'] ?? '',
      tipe: data['tipe'] ?? '',
      konten: data['konten'],
      suratName: data['suratName'],
      suratNumber: data['suratNumber'],
      ayatStart: data['ayatStart'],
      ayatEnd: data['ayatEnd'],
      arabText: data['arabText'],
      latinText: data['latinText'],
      translation: data['translation'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isActive: data['isActive'] ?? true,
      urutan: data['urutan'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'tipe': tipe,
      'konten': konten,
      'suratName': suratName,
      'suratNumber': suratNumber,
      'ayatStart': ayatStart,
      'ayatEnd': ayatEnd,
      'arabText': arabText,
      'latinText': latinText,
      'translation': translation,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'urutan': urutan,
    };
  }

  HafalanMateri copyWith({
    String? id,
    String? judul,
    String? tipe,
    String? konten,
    String? suratName,
    int? suratNumber,
    int? ayatStart,
    int? ayatEnd,
    String? arabText,
    String? latinText,
    String? translation,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    int? urutan,
  }) {
    return HafalanMateri(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      tipe: tipe ?? this.tipe,
      konten: konten ?? this.konten,
      suratName: suratName ?? this.suratName,
      suratNumber: suratNumber ?? this.suratNumber,
      ayatStart: ayatStart ?? this.ayatStart,
      ayatEnd: ayatEnd ?? this.ayatEnd,
      arabText: arabText ?? this.arabText,
      latinText: latinText ?? this.latinText,
      translation: translation ?? this.translation,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      urutan: urutan ?? this.urutan,
    );
  }
}
