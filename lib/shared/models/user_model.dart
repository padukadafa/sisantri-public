class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String? fotoProfil;
  final bool statusAktif;
  final String? rfidCardId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? nim;
  final String? jurusan;
  final String? kampus;
  final String? tempatKos;
  final String? jenisKelamin;
  final List<String>? deviceTokens;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.fotoProfil,
    this.statusAktif = true,
    this.rfidCardId,
    this.createdAt,
    this.updatedAt,
    this.nim,
    this.jurusan,
    this.kampus,
    this.tempatKos,
    this.deviceTokens,
    this.jenisKelamin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fotoProfil: json['fotoProfil'] as String?,
      statusAktif: json['statusAktif'] as bool? ?? true,
      rfidCardId: json['rfidCardId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['createdAt'].millisecondsSinceEpoch,
            )
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['updatedAt'].millisecondsSinceEpoch,
            )
          : null,
      nim: json['nim'] as String?,
      jurusan: json['jurusan'] as String?,
      kampus: json['kampus'] as String?,
      tempatKos: json['tempatKos'] as String?,
      deviceTokens: json['deviceTokens'] != null
          ? List<String>.from(json['deviceTokens'] as List)
          : null,
      jenisKelamin: json['jenis_kelamin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
      'fotoProfil': fotoProfil,
      'statusAktif': statusAktif,
      'rfidCardId': rfidCardId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'nim': nim,
      'jurusan': jurusan,
      'kampus': kampus,
      'tempatKos': tempatKos,
      'deviceTokens': deviceTokens,
      'jenis_kelamin': jenisKelamin,
    };
  }

  UserModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? role,
    int? poin,
    String? fotoProfil,
    bool? statusAktif,
    String? rfidCardId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nim,
    String? jurusan,
    String? kampus,
    String? tempatKos,
    List<String>? deviceTokens,
    String? jenisKelamin,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      statusAktif: statusAktif ?? this.statusAktif,
      rfidCardId: rfidCardId ?? this.rfidCardId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nim: nim ?? this.nim,
      jurusan: jurusan ?? this.jurusan,
      kampus: kampus ?? this.kampus,
      tempatKos: tempatKos ?? this.tempatKos,
      deviceTokens: deviceTokens ?? this.deviceTokens,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
    );
  }

  bool get isAdmin => role == 'admin';

  bool get isSantri => role == 'santri';

  bool get isDewaGuru => role == 'dewan_guru';

  bool get hasRfidSetup => rfidCardId != null && rfidCardId!.isNotEmpty;

  bool get needsRfidSetup => isSantri && !hasRfidSetup;

  bool get hasDeviceTokens => deviceTokens != null && deviceTokens!.isNotEmpty;

  List<String> get safeDeviceTokens => deviceTokens ?? [];

  List<String> addDeviceToken(String token) {
    final currentTokens = safeDeviceTokens;
    if (!currentTokens.contains(token)) {
      return [...currentTokens, token];
    }
    return currentTokens;
  }

  List<String> removeDeviceToken(String token) {
    final currentTokens = safeDeviceTokens;
    return currentTokens.where((t) => t != token).toList();
  }

  static const List<String> tempatKosPilihan = [
    'Asrama Putra',
    'Kos Pak Harsono',
    'Kos Pak Sigit',
    'Asrama Putri',
    'Kos Pak Sukadi',
    'Kos Abah Rahmat',
    'Kos Biru',
    'Kos Bu Mardiana',
    'Kos Pak Sugi',
    'Lainnya',
  ];

  static const List<String> kampusPilihan = [
    'Institut Teknologi Sumatera',
    'UIN Raden Intan Lampung',
    'Universitas Lampung',
    'Institut Maritim Prasetya Mandiri',
    'Universitas Bandar Lampung',
    'Universitas Teknokrat Indonesia',
    'Universitas Muhammadiyah Metro',
    'Universitas Muhammadiyah Lampung',
    'Universitas Malahayati',
    'Universitas Mitra Indonesia',
    'Universitas Saburai',
    'Universitas Tulang bawang',
    'Institut Informatika dan Bisnis Darmajaya',
    'STIKP PGRI Lampung',
    'Politeknik Negeri Lampung',
    'Universitas Terbuka',
    'Lainnya',
  ];

  static String getTempatKosIcon(String? tempatKos) {
    if (tempatKos == null) return '🏠';

    switch (tempatKos.toLowerCase()) {
      case 'asrama putra':
      case 'asrama putri':
        return '🏢';
      case 'kos pak harsono':
      case 'kos pak sigit':
      case 'kos pak sukadi':
      case 'kos pak sugi':
        return '🏘️';
      case 'kos abah rahmat':
        return '🕌';
      case 'kos biru':
        return '🔵';
      case 'kos bu mardiana':
        return '🏡';
      default:
        return '🏠';
    }
  }

  String get formattedTempatKos {
    if (tempatKos == null || tempatKos!.isEmpty) return 'Belum diatur';
    return '${getTempatKosIcon(tempatKos)} $tempatKos';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nama: $nama, email: $email, role: $role';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
