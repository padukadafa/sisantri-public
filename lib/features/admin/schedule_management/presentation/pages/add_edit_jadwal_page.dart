import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisantri/shared/helpers/messaging_helper.dart';
import 'package:sisantri/shared/models/jadwal_model.dart';
import 'package:sisantri/shared/services/attendance_service.dart';
import 'package:sisantri/core/theme/app_theme.dart';

import '../widgets/form_sections/basic_info_form_section.dart';
import '../widgets/form_sections/date_time_form_section.dart';
import '../widgets/form_sections/kategori_form_section.dart';
import '../widgets/form_sections/materi_form_section.dart';

class AddEditJadwalPage extends ConsumerStatefulWidget {
  final JadwalModel? jadwal;

  const AddEditJadwalPage({super.key, this.jadwal});

  @override
  ConsumerState<AddEditJadwalPage> createState() =>
      _AddEditJadwalPageNewState();
}

class _AddEditJadwalPageNewState extends ConsumerState<AddEditJadwalPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tempatController = TextEditingController();
  final _poinController = TextEditingController(text: '1');

  // Controllers untuk materi kajian
  String? _selectedPemateriId;
  String? _selectedPemateriNama;
  String? _selectedMateriId;
  String? _selectedMateriNama;
  String? _selectedMateriJenis; // quran, hadist, atau lainnya
  final _temaController = TextEditingController();
  final _ayatMulaiController = TextEditingController();
  final _ayatSelesaiController = TextEditingController();
  final _halamanMulaiController = TextEditingController();
  final _halamanSelesaiController = TextEditingController();
  final _hadistMulaiController = TextEditingController();
  final _hadistSelesaiController = TextEditingController();

  DateTime? _selectedDate;
  TipeJadwal _selectedKategori = TipeJadwal.kegiatan;
  String _waktuMulai = '08:00';
  String _waktuSelesai = '09:00';
  bool _isAktif = true;
  bool _isLoading = false;

  final List<TipeJadwal> _kategoriOptions = [
    TipeJadwal.pengajian,
    TipeJadwal.tahfidz,
    TipeJadwal.bacaan,
    TipeJadwal.olahraga,
    TipeJadwal.kegiatan,
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.jadwal != null) {
      _namaController.text = widget.jadwal!.nama;
      _deskripsiController.text = widget.jadwal!.deskripsi ?? '';
      _tempatController.text = widget.jadwal!.tempat ?? '';
      _poinController.text = widget.jadwal!.poin.toString();
      _selectedDate = widget.jadwal!.tanggal;
      _selectedKategori = widget.jadwal!.kategori;
      _waktuMulai = widget.jadwal!.waktuMulai ?? '08:00';
      _waktuSelesai = widget.jadwal!.waktuSelesai ?? '09:00';
      _isAktif = widget.jadwal!.isAktif;

      // Initialize materi fields if available
      _selectedPemateriId = widget.jadwal!.pemateriId;
      _selectedPemateriNama = widget.jadwal!.pemateriNama;
      _selectedMateriId = widget.jadwal!.materiId;
      // materiNama tidak perlu disimpan karena akan di-fetch dari dropdown

      if (widget.jadwal!.ayatMulai != null) {
        _ayatMulaiController.text = widget.jadwal!.ayatMulai.toString();
      }
      if (widget.jadwal!.ayatSelesai != null) {
        _ayatSelesaiController.text = widget.jadwal!.ayatSelesai.toString();
      }
      if (widget.jadwal!.halamanMulai != null) {
        _halamanMulaiController.text = widget.jadwal!.halamanMulai.toString();
      }
      if (widget.jadwal!.halamanSelesai != null) {
        _halamanSelesaiController.text = widget.jadwal!.halamanSelesai
            .toString();
      }
    } else {
      final currentDate = DateTime.now();
      _selectedDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _tempatController.dispose();
    _poinController.dispose();
    _temaController.dispose();
    _ayatMulaiController.dispose();
    _ayatSelesaiController.dispose();
    _halamanMulaiController.dispose();
    _halamanSelesaiController.dispose();
    _hadistMulaiController.dispose();
    _hadistSelesaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jadwal != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KategoriFormSection(
                      selectedKategori: _selectedKategori,
                      kategoriOptions: _kategoriOptions,
                      onKategoriChanged: (kategori) {
                        if (kategori != null) {
                          setState(() {
                            _selectedKategori = kategori;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    BasicInfoFormSection(
                      namaController: _namaController,
                      deskripsiController: _deskripsiController,
                      tempatController: _tempatController,
                      selectedKategori: _selectedKategori,
                    ),
                    const SizedBox(height: 24),
                    // Poin Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Poin Kehadiran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _poinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Poin yang Didapatkan',
                                hintText: 'Masukkan jumlah poin',
                                helperText:
                                    'Poin yang didapat santri jika hadir',
                                prefixIcon: Icon(Icons.star),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Poin tidak boleh kosong';
                                }
                                final poin = int.tryParse(value);
                                if (poin == null || poin < 0) {
                                  return 'Poin harus berupa angka positif';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MateriFormSection(
                      selectedKategori: _selectedKategori,
                      selectedMateriId: _selectedMateriId,
                      selectedMateriNama: _selectedMateriNama,
                      selectedMateriJenis: _selectedMateriJenis,
                      onMateriChanged: (id, nama, jenis) {
                        setState(() {
                          _selectedMateriId = id;
                          _selectedMateriNama = nama;
                          _selectedMateriJenis = jenis;
                          // Clear fields yang tidak relevan saat materi berubah
                          if (jenis != 'quran') {
                            _ayatMulaiController.clear();
                            _ayatSelesaiController.clear();
                          }
                          if (jenis == 'quran') {
                            _halamanMulaiController.clear();
                            _halamanSelesaiController.clear();
                          }
                        });
                      },
                      selectedPemateriId: _selectedPemateriId,
                      selectedPemateriNama: _selectedPemateriNama,
                      onPemateriChanged: (id, nama) {
                        setState(() {
                          _selectedPemateriId = id;
                          _selectedPemateriNama = nama;
                        });
                      },
                      temaController: _temaController,
                      ayatMulaiController: _ayatMulaiController,
                      ayatSelesaiController: _ayatSelesaiController,
                      halamanMulaiController: _halamanMulaiController,
                      halamanSelesaiController: _halamanSelesaiController,
                    ),
                    const SizedBox(height: 24),
                    DateTimeFormSection(
                      selectedDate: _selectedDate,
                      waktuMulai: _parseTimeOfDay(_waktuMulai),
                      waktuSelesai: _parseTimeOfDay(_waktuSelesai),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      onWaktuMulaiChanged: (time) {
                        setState(() {
                          _waktuMulai = _formatTimeOfDay(time);
                        });
                      },
                      onWaktuSelesaiChanged: (time) {
                        setState(() {
                          _waktuSelesai = _formatTimeOfDay(time);
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveJadwal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEdit ? 'Update Jadwal' : 'Simpan Jadwal',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper methods untuk convert waktu
  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveJadwal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal untuk kegiatan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Helper untuk parse integer atau null
      int? parseIntOrNull(String? text) {
        if (text == null || text.trim().isEmpty) return null;
        return int.tryParse(text.trim());
      }

      // Helper untuk string atau null
      String? stringOrNull(String text) {
        final trimmed = text.trim();
        return trimmed.isEmpty ? null : trimmed;
      }

      final jadwal = JadwalModel(
        id: widget.jadwal?.id ?? '',
        nama: _namaController.text.trim(),
        tanggal: _selectedDate!,
        waktuMulai: _waktuMulai,
        waktuSelesai: _waktuSelesai,
        kategori: _selectedKategori,
        tempat: stringOrNull(_tempatController.text),
        deskripsi: stringOrNull(_deskripsiController.text),
        materiId: _selectedMateriId,
        pemateriId: _selectedPemateriId,
        pemateriNama: _selectedPemateriNama,
        ayatMulai: parseIntOrNull(_ayatMulaiController.text),
        ayatSelesai: parseIntOrNull(_ayatSelesaiController.text),
        halamanMulai: parseIntOrNull(_halamanMulaiController.text),
        halamanSelesai: parseIntOrNull(_halamanSelesaiController.text),
        poin: int.tryParse(_poinController.text.trim()) ?? 1,
        isAktif: _isAktif,
        createdAt: widget.jadwal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.jadwal == null) {
        await _addJadwal(jadwal);
      } else {
        await _updateJadwal(jadwal);
      }

      if (mounted) {
        Navigator.pop(context, jadwal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addJadwal(JadwalModel jadwal) async {
    final docRef = await FirebaseFirestore.instance
        .collection('jadwal')
        .add(jadwal.toNewFirebaseData());

    await AttendanceService.generateDefaultAttendanceForJadwal(
      jadwalId: docRef.id,
      createdBy: 'admin',
      createdByName: 'Admin',
      jadwal: jadwal,
    );

    await MessagingHelper.sendPengumumanToSantri(
      title: 'Jadwal Baru Ditambahkan',
      message:
          '${jadwal.nama} - ${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}',
    );
  }

  Future<void> _updateJadwal(JadwalModel jadwal) async {
    await FirebaseFirestore.instance
        .collection('jadwal')
        .doc(jadwal.id)
        .update(jadwal.toJson());
  }
}
