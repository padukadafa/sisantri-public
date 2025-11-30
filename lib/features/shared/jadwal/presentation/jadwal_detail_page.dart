import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/models/materi_model.dart';
import 'package:sisantri/shared/services/auth_service.dart';

/// Provider untuk detail jadwal dengan realtime updates
final jadwalDetailProvider = StreamProvider.family<JadwalModel, String>((
  ref,
  jadwalId,
) {
  return FirebaseFirestore.instance
      .collection('jadwal')
      .doc(jadwalId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          throw Exception('Jadwal tidak ditemukan');
        }
        final data = doc.data()!;
        return JadwalModel.fromJson({'id': doc.id, ...data});
      });
});

/// Provider untuk data pemateri
final pemateriProvider = FutureProvider.family<UserModel?, String?>((
  ref,
  pemateriId,
) async {
  if (pemateriId == null || pemateriId.isEmpty) return null;
  return await AuthService.getUserData(pemateriId);
});

/// Provider untuk data materi kajian
final materiProvider = FutureProvider.family<MateriModel?, String?>((
  ref,
  materiId,
) async {
  if (materiId == null || materiId.isEmpty) return null;

  final doc = await FirebaseFirestore.instance
      .collection('materi')
      .doc(materiId)
      .get();

  if (!doc.exists) return null;

  return MateriModel.fromJson({'id': doc.id, ...doc.data()!});
});

/// Provider untuk daftar presensi santri
final jadwalPresensiProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, jadwalId) {
      return FirebaseFirestore.instance
          .collection('presensi')
          .where('jadwalId', isEqualTo: jadwalId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final presensiList = <Map<String, dynamic>>[];

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final userId = data['userId'] as String?;

              if (userId != null) {
                final userData = await AuthService.getUserData(userId);
                presensiList.add({
                  'id': doc.id,
                  'user': userData,
                  'status': data['status'] ?? 'alpha',
                  'timestamp': data['timestamp'] as Timestamp?,
                  'poin': data['poin'] ?? 0,
                });
              }
            }

            return presensiList;
          });
    });

/// Halaman Detail Jadwal
class JadwalDetailPage extends ConsumerWidget {
  final String jadwalId;

  const JadwalDetailPage({super.key, required this.jadwalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwalAsync = ref.watch(jadwalDetailProvider(jadwalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jadwal')),
      body: jadwalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
        data: (jadwal) => _buildDetailContent(context, ref, jadwal),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    WidgetRef ref,
    JadwalModel jadwal,
  ) {
    final presensiAsync = ref.watch(jadwalPresensiProvider(jadwalId));
    final pemateriAsync = ref.watch(pemateriProvider(jadwal.pemateriId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Nama Jadwal Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getKategoriIcon(jadwal.kategori),
                            color: Colors.black,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getKategoriLabel(jadwal.kategori),
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jadwal.nama,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tanggal & Waktu
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Tanggal & Waktu',
                  children: [
                    _buildInfoRow(
                      'Tanggal',
                      DateFormat(
                        'EEEE, dd MMMM yyyy',
                        'id_ID',
                      ).format(jadwal.tanggal),
                    ),
                    if (jadwal.waktuMulai != null)
                      _buildInfoRow('Waktu', jadwal.formattedWaktuRange),
                  ],
                ),
                const SizedBox(height: 12),

                // Tempat
                if (jadwal.tempat != null)
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Lokasi',
                    children: [_buildInfoRow('Tempat', jadwal.tempat!)],
                  ),
                if (jadwal.tempat != null) const SizedBox(height: 12),

                // Pemateri (jika ada)
                if (jadwal.pemateriId != null)
                  pemateriAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (pemateri) {
                      if (pemateri == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _buildPemateriCard(pemateri),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                // Materi Kajian (jika ada)
                if (jadwal.materiId != null)
                  ref
                      .watch(materiProvider(jadwal.materiId))
                      .when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (materi) {
                          if (materi == null) {
                            // Fallback jika materi tidak ditemukan tapi ada info ayat/halaman
                            if (jadwal.ayatMulai != null ||
                                jadwal.halamanMulai != null) {
                              return Column(
                                children: [
                                  _buildInfoCard(
                                    icon: Icons.book,
                                    title: 'Materi Kajian',
                                    children: [
                                      if (jadwal.ayatMulai != null)
                                        _buildInfoRow(
                                          'Ayat',
                                          '${jadwal.ayatMulai} - ${jadwal.ayatSelesai ?? ""}',
                                        ),
                                      if (jadwal.halamanMulai != null)
                                        _buildInfoRow(
                                          'Halaman',
                                          '${jadwal.halamanMulai} - ${jadwal.halamanSelesai ?? ""}',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              _buildMateriCard(materi, jadwal),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      )
                else if (jadwal.ayatMulai != null ||
                    jadwal.halamanMulai != null)
                  Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.book,
                        title: 'Materi Kajian',
                        children: [
                          if (jadwal.ayatMulai != null)
                            _buildInfoRow(
                              'Ayat',
                              '${jadwal.ayatMulai} - ${jadwal.ayatSelesai ?? ""}',
                            ),
                          if (jadwal.halamanMulai != null)
                            _buildInfoRow(
                              'Halaman',
                              '${jadwal.halamanMulai} - ${jadwal.halamanSelesai ?? ""}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Poin
                _buildInfoCard(
                  icon: Icons.star,
                  title: 'Poin Kehadiran',
                  children: [
                    _buildInfoRow(
                      'Poin',
                      '${jadwal.poin} poin untuk hadir',
                      valueColor: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deskripsi
                if (jadwal.deskripsi != null && jadwal.deskripsi!.isNotEmpty)
                  _buildDescriptionCard(jadwal.deskripsi!),
                if (jadwal.deskripsi != null && jadwal.deskripsi!.isNotEmpty)
                  const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPemateriCard(UserModel pemateri) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: pemateri.fotoProfil != null
                ? NetworkImage(pemateri.fotoProfil!)
                : null,
            child: pemateri.fotoProfil == null
                ? Text(
                    pemateri.nama.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemateri',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  pemateri.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pemateri.email.isNotEmpty)
                  Text(
                    pemateri.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriCard(MateriModel materi, JadwalModel jadwal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getJenisMateriColor(materi.jenis).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getJenisMateriIcon(materi.jenis),
                  color: _getJenisMateriColor(materi.jenis),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materi Kajian',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materi.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getJenisMateriColor(materi.jenis).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  materi.jenisDisplayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getJenisMateriColor(materi.jenis),
                  ),
                ),
              ),
            ],
          ),
          if (materi.pengarang != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildInfoRow('Pengarang', materi.pengarang!),
          ],
          if (materi.deskripsi != null && materi.deskripsi!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Keterangan', materi.deskripsi!),
          ],
          // Info range ayat/halaman dari jadwal
          if (jadwal.ayatMulai != null || jadwal.halamanMulai != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Cakupan Pembahasan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (jadwal.ayatMulai != null)
              _buildInfoRow(
                'Ayat',
                'Ayat ${jadwal.ayatMulai}${jadwal.ayatSelesai != null ? " - ${jadwal.ayatSelesai}" : ""}',
              ),
            if (jadwal.halamanMulai != null)
              _buildInfoRow(
                'Halaman',
                'Halaman ${jadwal.halamanMulai}${jadwal.halamanSelesai != null ? " - ${jadwal.halamanSelesai}" : ""}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStatistikCard(JadwalModel jadwal) {
    final total = jadwal.totalPresensi;
    final hadir = jadwal.presensiHadir;
    final izin = jadwal.presensiIzin;
    final sakit = jadwal.presensiSakit;
    final alpha = jadwal.presensiAlpha;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Statistik Presensi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Hadir', hadir, Colors.green),
              _buildStatItem('Izin', izin, Colors.orange),
              _buildStatItem('Sakit', sakit, Colors.blue),
              _buildStatItem('Alpha', alpha, Colors.red),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total Presensi: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPresensiTile(Map<String, dynamic> item) {
    final user = item['user'] as UserModel?;
    final status = item['status'] as String;
    final timestamp = item['timestamp'] as Timestamp?;
    final poin = item['poin'] as int;

    if (user == null) return const SizedBox.shrink();

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.fotoProfil != null
              ? NetworkImage(user.fotoProfil!)
              : null,
          child: user.fotoProfil == null
              ? Text(
                  user.nama.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          user.nama,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: timestamp != null
            ? Text(
                DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (poin > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '+$poin',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getKategoriColor(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.pengajian:
        return Colors.green;
      case TipeJadwal.tahfidz:
        return Colors.purple;
      case TipeJadwal.bacaan:
        return Colors.blue;
      case TipeJadwal.olahraga:
        return Colors.orange;
      case TipeJadwal.kegiatan:
        return AppTheme.primaryColor;
    }
  }

  IconData _getKategoriIcon(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.pengajian:
        return Icons.book;
      case TipeJadwal.tahfidz:
        return Icons.menu_book;
      case TipeJadwal.bacaan:
        return Icons.import_contacts;
      case TipeJadwal.olahraga:
        return Icons.sports_soccer;
      case TipeJadwal.kegiatan:
        return Icons.event;
    }
  }

  String _getKategoriLabel(TipeJadwal kategori) {
    switch (kategori) {
      case TipeJadwal.pengajian:
        return 'Pengajian';
      case TipeJadwal.tahfidz:
        return 'Tahfidz';
      case TipeJadwal.bacaan:
        return 'Bacaan';
      case TipeJadwal.olahraga:
        return 'Olahraga';
      case TipeJadwal.kegiatan:
        return 'Kegiatan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'izin':
        return Colors.orange;
      case 'sakit':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      default:
        return 'Alpha';
    }
  }

  Color _getJenisMateriColor(JenisMateri jenis) {
    switch (jenis) {
      case JenisMateri.quran:
        return Colors.green;
      case JenisMateri.hadist:
        return Colors.blue;
      case JenisMateri.lainnya:
        return Colors.orange;
    }
  }

  IconData _getJenisMateriIcon(JenisMateri jenis) {
    switch (jenis) {
      case JenisMateri.quran:
        return Icons.menu_book;
      case JenisMateri.hadist:
        return Icons.auto_stories;
      case JenisMateri.lainnya:
        return Icons.import_contacts;
    }
  }
}
