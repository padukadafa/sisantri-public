import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/services/announcement_service.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';
import 'package:sisantri/features/admin/announcement_management/presentation/widgets/announcement_form_fields.dart';
import 'package:sisantri/features/admin/announcement_management/presentation/widgets/announcement_form_buttons.dart';

class AnnouncementFormPage extends ConsumerStatefulWidget {
  final AnnouncementModel? announcement;

  const AnnouncementFormPage({super.key, this.announcement});

  @override
  ConsumerState<AnnouncementFormPage> createState() =>
      _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends ConsumerState<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final announcement = widget.announcement!;
    _judulController.text = announcement.judul;
    _kontenController.text = announcement.konten;
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isView = widget.announcement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isView ? 'Pengumuman' : 'Buat Pengumuman'),
        actions: [
          if (isView)
            TextButton(
              onPressed: _isLoading ? null : _saveAsDraft,
              child: const Text(
                'Simpan Draft',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnnouncementFormFields(
              judulController: _judulController,
              kontenController: _kontenController,
              isReadOnly: isView,
            ),
            const SizedBox(height: 24),

            Visibility(
              visible: !isView,
              child: AnnouncementFormButtons(
                isLoading: _isLoading,
                onCancel: () => Navigator.pop(context),
                onPublish: _saveAndPublish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveAnnouncement(published: false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndPublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveAnnouncement(published: true);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil dipublikasi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAnnouncement({required bool published}) async {
    final currentUser = AuthService.currentUser;

    if (currentUser == null) {
      throw Exception('User tidak ditemukan');
    }

    final now = DateTime.now();

    final announcementModel = AnnouncementModel(
      id: widget.announcement?.id ?? '',
      judul: _judulController.text.trim(),
      konten: _kontenController.text.trim(),
      kategori: 'umum',
      prioritas: 'medium',
      createdBy: currentUser.uid,
      createdByName: currentUser.displayName ?? 'Admin',
      targetAudience: 'all',
      targetRoles: const [],
      targetClasses: const [],
      lampiranUrl: null,
      tanggalMulai: now,
      tanggalBerakhir: null,
      isPublished: published,
      isPinned: false,
      viewCount: widget.announcement?.viewCount ?? 0,
      createdAt: widget.announcement?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.announcement != null) {
      await AnnouncementService.updatePengumuman(
        widget.announcement!.id,
        announcementModel,
      );
    } else {
      await AnnouncementService.addPengumuman(announcementModel);
    }
  }
}
