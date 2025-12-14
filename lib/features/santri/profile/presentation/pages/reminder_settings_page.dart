import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/shared/services/reminder_service.dart';
import 'package:sisantri/shared/services/prayer_times_service.dart';

/// Halaman untuk pengaturan pengingat sholat dan jadwal
class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  bool _prayerReminderEnabled = true;
  bool _scheduleReminderEnabled = true;
  int _prayerReminderMinutes = 10;
  int _scheduleReminderMinutes = 15;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    _prayerReminderEnabled = await ReminderService.isPrayerReminderEnabled();
    _scheduleReminderEnabled =
        await ReminderService.isScheduleReminderEnabled();
    _prayerReminderMinutes = await ReminderService.getPrayerReminderMinutes();
    _scheduleReminderMinutes =
        await ReminderService.getScheduleReminderMinutes();

    setState(() => _isLoading = false);
  }

  Future<void> _savePrayerReminderEnabled(bool value) async {
    setState(() => _prayerReminderEnabled = value);
    await ReminderService.setPrayerReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Pengingat sholat diaktifkan'
                : '❌ Pengingat sholat dinonaktifkan',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveScheduleReminderEnabled(bool value) async {
    setState(() => _scheduleReminderEnabled = value);
    await ReminderService.setScheduleReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Pengingat jadwal diaktifkan'
                : '❌ Pengingat jadwal dinonaktifkan',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _savePrayerReminderMinutes(int minutes) async {
    setState(() => _prayerReminderMinutes = minutes);
    await ReminderService.setPrayerReminderMinutes(minutes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Pengingat sholat: $minutes menit sebelumnya'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveScheduleReminderMinutes(int minutes) async {
    setState(() => _scheduleReminderMinutes = minutes);
    await ReminderService.setScheduleReminderMinutes(minutes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Pengingat jadwal: $minutes menit sebelumnya'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Pengingat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Pengingat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Semua Pengingat',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⏳ Memperbarui pengingat...')),
              );
              await ReminderService.refreshReminders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Pengingat berhasil diperbarui'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === PENGINGAT SHOLAT ===
          _buildSectionHeader('🕌 Pengingat Sholat'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aktifkan Pengingat Sholat'),
                  subtitle: const Text('Notifikasi sebelum waktu sholat'),
                  value: _prayerReminderEnabled,
                  onChanged: _savePrayerReminderEnabled,
                  secondary: const Icon(Icons.notifications_active),
                ),
                if (_prayerReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Waktu Pengingat'),
                    subtitle: Text('$_prayerReminderMinutes menit sebelumnya'),
                    trailing: DropdownButton<int>(
                      value: _prayerReminderMinutes,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 menit')),
                        DropdownMenuItem(value: 10, child: Text('10 menit')),
                        DropdownMenuItem(value: 15, child: Text('15 menit')),
                        DropdownMenuItem(value: 30, child: Text('30 menit')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _savePrayerReminderMinutes(value);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Jadwal Sholat Hari Ini
          _buildSectionHeader('⏰ Hari Ini'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: PrayerTimesService.getAllPrayerTimesForDisplay()
                    .map(
                      (prayer) => _buildPrayerTimeRow(
                        prayer['displayName'] as String,
                        prayer['formattedTime'] as String,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === PENGINGAT JADWAL ===
          _buildSectionHeader('📅 Pengingat Jadwal Kegiatan'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aktifkan Pengingat Jadwal'),
                  subtitle: const Text('Notifikasi sebelum kegiatan dimulai'),
                  value: _scheduleReminderEnabled,
                  onChanged: _saveScheduleReminderEnabled,
                  secondary: const Icon(Icons.event_available),
                ),
                if (_scheduleReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Waktu Pengingat'),
                    subtitle: Text(
                      '$_scheduleReminderMinutes menit sebelumnya',
                    ),
                    trailing: DropdownButton<int>(
                      value: _scheduleReminderMinutes,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 menit')),
                        DropdownMenuItem(value: 10, child: Text('10 menit')),
                        DropdownMenuItem(value: 15, child: Text('15 menit')),
                        DropdownMenuItem(value: 30, child: Text('30 menit')),
                        DropdownMenuItem(value: 60, child: Text('1 jam')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _saveScheduleReminderMinutes(value);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // === INFO ===
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Informasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Pengingat akan otomatis dijadwalkan untuk hari ini dan besok\n'
                    '• Setiap tengah malam, pengingat akan diperbarui otomatis\n'
                    '• Notifikasi akan muncul meskipun aplikasi ditutup\n'
                    '• Pastikan izin notifikasi telah diaktifkan',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
