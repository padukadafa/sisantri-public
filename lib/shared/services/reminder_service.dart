import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'prayer_times_service.dart';
import '../models/jadwal_model.dart';

/// Service untuk mengelola pengingat (reminder) sholat dan jadwal
/// Sustainable dan efisien dengan scheduling yang proper
class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _prayerReminderIdStart = 1000;
  static const int _scheduleReminderIdStart = 2000;

  // SharedPreferences keys
  static const String _keyPrayerReminderEnabled = 'prayer_reminder_enabled';
  static const String _keyScheduleReminderEnabled = 'schedule_reminder_enabled';
  static const String _keyPrayerReminderMinutes = 'prayer_reminder_minutes';
  static const String _keyScheduleReminderMinutes = 'schedule_reminder_minutes';

  /// Initialize reminder service
  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Get device timezone
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      // Fallback ke Asia/Jakarta untuk Indonesia
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    // Setup notification channels
    await _setupNotificationChannels();

    // Load preferences dan schedule reminders
    await scheduleAllReminders();
  }

  /// Setup notification channels untuk Android
  static Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'Pengingat Sholat',
      description: 'Notifikasi pengingat waktu sholat',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel scheduleChannel =
        AndroidNotificationChannel(
          'schedule_reminders',
          'Pengingat Jadwal',
          description: 'Notifikasi pengingat jadwal kegiatan',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(prayerChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(scheduleChannel);
  }

  /// Schedule semua reminders (prayer + schedule)
  static Future<void> scheduleAllReminders() async {
    await schedulePrayerReminders();
    await scheduleJadwalReminders();
  }

  /// Schedule pengingat sholat
  static Future<void> schedulePrayerReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyPrayerReminderEnabled) ?? true;

    if (!enabled) {
      await cancelPrayerReminders();
      return;
    }

    final minutesBefore = prefs.getInt(_keyPrayerReminderMinutes) ?? 10;
    final prayerTimes = PrayerTimesService.getTodayPrayerTimes();

    int notificationId = _prayerReminderIdStart;

    for (var entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;
      final reminderTime = prayerTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Skip jika waktu sudah lewat
      if (reminderTime.isBefore(DateTime.now())) {
        continue;
      }

      await _scheduleNotification(
        id: notificationId++,
        title:
            '🕌 Pengingat Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            '$minutesBefore menit lagi masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        scheduledTime: reminderTime,
        channelId: 'prayer_reminders',
        channelName: 'Pengingat Sholat',
        payload: 'prayer_$prayerName',
      );

      // Schedule notifikasi tepat waktu sholat juga
      if (prayerTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: notificationId++,
          title:
              '🕌 Waktu Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
          body:
              'Sudah masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}. Yuk segera ke masjid! 🤲',
          scheduledTime: prayerTime,
          channelId: 'prayer_reminders',
          channelName: 'Pengingat Sholat',
          payload: 'prayer_now_$prayerName',
        );
      }
    }

    // Schedule untuk besok juga (recurring daily)
    await _scheduleTomorrowPrayerReminders();
  }

  /// Schedule prayer reminders untuk besok (untuk recurring)
  static Future<void> _scheduleTomorrowPrayerReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final minutesBefore = prefs.getInt(_keyPrayerReminderMinutes) ?? 10;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final prayerTimes = PrayerTimesService.getTodayPrayerTimes();

    int notificationId = _prayerReminderIdStart + 100;

    for (var entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final time = entry.value;

      // Buat waktu untuk besok
      final tomorrowPrayerTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        time.hour,
        time.minute,
      );

      final reminderTime = tomorrowPrayerTime.subtract(
        Duration(minutes: minutesBefore),
      );

      await _scheduleNotification(
        id: notificationId++,
        title:
            '🕌 Pengingat Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            '$minutesBefore menit lagi masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        scheduledTime: reminderTime,
        channelId: 'prayer_reminders',
        channelName: 'Pengingat Sholat',
        payload: 'prayer_$prayerName',
      );

      await _scheduleNotification(
        id: notificationId++,
        title:
            '🕌 Waktu Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            'Sudah masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}. Yuk segera ke masjid! 🤲',
        scheduledTime: tomorrowPrayerTime,
        channelId: 'prayer_reminders',
        channelName: 'Pengingat Sholat',
        payload: 'prayer_now_$prayerName',
      );
    }
  }

  /// Schedule pengingat jadwal kegiatan
  static Future<void> scheduleJadwalReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyScheduleReminderEnabled) ?? true;

    if (!enabled) {
      await cancelJadwalReminders();
      return;
    }

    final minutesBefore = prefs.getInt(_keyScheduleReminderMinutes) ?? 15;

    try {
      // Ambil jadwal yang aktif untuk hari ini dan besok
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfTomorrow = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        23,
        59,
        59,
      );

      final jadwalSnapshot = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('isAktif', isEqualTo: true)
          .where(
            'tanggal',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'tanggal',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow),
          )
          .get();

      int notificationId = _scheduleReminderIdStart;

      for (var doc in jadwalSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final jadwal = JadwalModel.fromJson(data);

          // Skip jika tidak ada waktu mulai
          if (jadwal.waktuMulai == null) continue;

          // Parse waktu mulai
          final timeParts = jadwal.waktuMulai!.split(':');
          if (timeParts.length < 2) continue;

          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);

          if (hour == null || minute == null) continue;

          final jadwalTime = DateTime(
            jadwal.tanggal.year,
            jadwal.tanggal.month,
            jadwal.tanggal.day,
            hour,
            minute,
          );

          // Skip jika waktu sudah lewat
          if (jadwalTime.isBefore(DateTime.now())) continue;

          final reminderTime = jadwalTime.subtract(
            Duration(minutes: minutesBefore),
          );

          // Schedule reminder sebelum kegiatan
          if (reminderTime.isAfter(DateTime.now())) {
            await _scheduleNotification(
              id: notificationId++,
              title: '📅 Pengingat: ${jadwal.nama}',
              body:
                  '$minutesBefore menit lagi ada kegiatan ${jadwal.nama}${jadwal.tempat != null ? ' di ${jadwal.tempat}' : ''}',
              scheduledTime: reminderTime,
              channelId: 'schedule_reminders',
              channelName: 'Pengingat Jadwal',
              payload: 'schedule_${jadwal.id}',
            );
          }

          // Schedule notifikasi tepat waktu kegiatan
          await _scheduleNotification(
            id: notificationId++,
            title: '📅 ${jadwal.nama}',
            body:
                'Kegiatan ${jadwal.nama} dimulai sekarang!${jadwal.tempat != null ? ' Lokasi: ${jadwal.tempat}' : ''}',
            scheduledTime: jadwalTime,
            channelId: 'schedule_reminders',
            channelName: 'Pengingat Jadwal',
            payload: 'schedule_now_${jadwal.id}',
          );
        } catch (e) {
          // Skip jadwal yang error
          continue;
        }
      }
    } catch (e) {
      // Error fetching jadwal
    }
  }

  /// Helper untuk schedule single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel semua prayer reminders
  static Future<void> cancelPrayerReminders() async {
    // Cancel range of prayer notification IDs
    for (
      int i = _prayerReminderIdStart;
      i < _prayerReminderIdStart + 200;
      i++
    ) {
      await _notifications.cancel(i);
    }
  }

  /// Cancel semua jadwal reminders
  static Future<void> cancelJadwalReminders() async {
    // Cancel range of schedule notification IDs
    for (
      int i = _scheduleReminderIdStart;
      i < _scheduleReminderIdStart + 1000;
      i++
    ) {
      await _notifications.cancel(i);
    }
  }

  /// Cancel semua reminders
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // === Preference Getters & Setters ===

  static Future<bool> isPrayerReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPrayerReminderEnabled) ?? true;
  }

  static Future<void> setPrayerReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrayerReminderEnabled, enabled);
    await schedulePrayerReminders();
  }

  static Future<bool> isScheduleReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyScheduleReminderEnabled) ?? true;
  }

  static Future<void> setScheduleReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScheduleReminderEnabled, enabled);
    await scheduleJadwalReminders();
  }

  static Future<int> getPrayerReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPrayerReminderMinutes) ?? 10;
  }

  static Future<void> setPrayerReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPrayerReminderMinutes, minutes);
    await schedulePrayerReminders();
  }

  static Future<int> getScheduleReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyScheduleReminderMinutes) ?? 15;
  }

  static Future<void> setScheduleReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScheduleReminderMinutes, minutes);
    await scheduleJadwalReminders();
  }

  /// Re-schedule reminders (dipanggil setelah update jadwal atau setiap hari)
  static Future<void> refreshReminders() async {
    await cancelAllReminders();
    await scheduleAllReminders();
  }
}
