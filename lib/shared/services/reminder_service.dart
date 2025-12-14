import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import 'prayer_times_service.dart';
import 'native_notification_service.dart';
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
  static const String _keyLastPrayerScheduleUpdate =
      'last_prayer_schedule_update';

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

    // Initialize notification plugin with proper settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification tapped: ${response.payload}');
      },
    );

    // Request notification permissions (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Setup notification channels
    await _setupNotificationChannels();

    // Request exact alarm permission for Android 12+
    await requestExactAlarmPermission();

    // Check dan update jadwal sholat otomatis
    await checkAndUpdatePrayerSchedule();

    // Load preferences dan schedule reminders
    await scheduleAllReminders();

    print('✅ ReminderService initialized successfully');
  }

  /// Request exact alarm permission for Android 12+
  static Future<bool> requestExactAlarmPermission() async {
    try {
      // Check if already granted
      if (await Permission.scheduleExactAlarm.isGranted) {
        return true;
      }

      // Request permission
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (e) {
      // Jika error atau tidak support, return false
      return false;
    }
  }

  /// Check if exact alarm permission is granted
  static Future<bool> canScheduleExactAlarms() async {
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Setup notification channels untuk Android
  static Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'Pengingat Sholat',
      description: 'Notifikasi pengingat waktu sholat',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    const AndroidNotificationChannel scheduleChannel =
        AndroidNotificationChannel(
          'schedule_reminders',
          'Pengingat Jadwal',
          description: 'Notifikasi pengingat jadwal kegiatan',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(prayerChannel);
      await androidPlugin.createNotificationChannel(scheduleChannel);
      print('✅ Notification channels created');
    } else {
      print('⚠️ Android plugin not available');
    }
  }

  /// Schedule semua reminders (prayer + schedule)
  static Future<void> scheduleAllReminders() async {
    await schedulePrayerReminders();
    await scheduleJadwalReminders();
  }

  /// Check dan update jadwal sholat otomatis
  /// - Pertama kali buka aplikasi: jadwalkan 1 bulan ke depan
  /// - Setiap tanggal 1: update jadwal untuk bulan baru
  static Future<void> checkAndUpdatePrayerSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateStr = prefs.getString(_keyLastPrayerScheduleUpdate);
    final now = DateTime.now();

    bool needsUpdate = false;

    if (lastUpdateStr == null) {
      // Pertama kali buka aplikasi
      print(
        '🕌 Pertama kali membuka aplikasi - jadwalkan sholat 1 bulan ke depan',
      );
      needsUpdate = true;
    } else {
      final lastUpdate = DateTime.parse(lastUpdateStr);

      // Check apakah sudah ganti bulan dan hari ini tanggal 1
      if (now.month != lastUpdate.month || now.year != lastUpdate.year) {
        if (now.day == 1) {
          print('🕌 Tanggal 1 - update jadwal sholat untuk bulan baru');
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate) {
      await scheduleMonthlyPrayerReminders();
      await prefs.setString(
        _keyLastPrayerScheduleUpdate,
        now.toIso8601String(),
      );
      print('✅ Jadwal sholat 1 bulan berhasil dijadwalkan');
    }
  }

  /// Schedule pengingat sholat untuk 1 bulan ke depan
  static Future<void> scheduleMonthlyPrayerReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyPrayerReminderEnabled) ?? true;

    if (!enabled) {
      return;
    }

    final minutesBefore = prefs.getInt(_keyPrayerReminderMinutes) ?? 10;
    final now = DateTime.now();
    int notificationId = _prayerReminderIdStart;

    // Loop untuk 30 hari ke depan
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDate = DateTime(now.year, now.month, now.day + dayOffset);
      final prayerTimes = _getPrayerTimesForDate(targetDate);

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

        // Schedule reminder sebelum waktu sholat
        await NativeNotificationService.scheduleExactNotification(
          id: notificationId++,
          title:
              '🕌 Pengingat Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
          body:
              '$minutesBefore menit lagi masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
          scheduledTime: reminderTime,
        );

        // Schedule notifikasi tepat waktu sholat
        if (prayerTime.isAfter(DateTime.now())) {
          await NativeNotificationService.scheduleExactNotification(
            id: notificationId++,
            title:
                '🕌 Waktu Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
            body:
                'Sudah masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}. Yuk segera ke masjid! 🤲',
            scheduledTime: prayerTime,
          );
        }
      }
    }

    print('✅ Prayer reminders untuk 1 bulan (30 hari) berhasil dijadwalkan');
  }

  /// Get prayer times untuk tanggal tertentu
  static Map<String, DateTime> _getPrayerTimesForDate(DateTime date) {
    // Get today's prayer times as template
    final prayerTimes = PrayerTimesService.getTodayPrayerTimes();

    // Adjust to target date (keeping the time, changing the date)
    final result = <String, DateTime>{};
    for (var entry in prayerTimes.entries) {
      final originalTime = entry.value;
      final adjustedTime = DateTime(
        date.year,
        date.month,
        date.day,
        originalTime.hour,
        originalTime.minute,
        originalTime.second,
      );
      result[entry.key] = adjustedTime;
    }

    return result;
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

      // USE NATIVE IMPLEMENTATION - More reliable!
      await NativeNotificationService.scheduleExactNotification(
        id: notificationId++,
        title:
            '🕌 Pengingat Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            '$minutesBefore menit lagi masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        scheduledTime: reminderTime,
      );

      // Schedule notifikasi tepat waktu sholat juga
      if (prayerTime.isAfter(DateTime.now())) {
        await NativeNotificationService.scheduleExactNotification(
          id: notificationId++,
          title:
              '🕌 Waktu Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
          body:
              'Sudah masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}. Yuk segera ke masjid! 🤲',
          scheduledTime: prayerTime,
        );
      }
    }

    print('✅ Prayer reminders scheduled using NATIVE implementation');

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

      // Schedule reminder before prayer (native)
      await NativeNotificationService.scheduleExactNotification(
        id: notificationId++,
        title:
            '🕌 Pengingat Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            '$minutesBefore menit lagi masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        scheduledTime: reminderTime,
      );

      // Schedule notification at exact prayer time (native)
      await NativeNotificationService.scheduleExactNotification(
        id: notificationId++,
        title:
            '🕌 Waktu Sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}',
        body:
            'Sudah masuk waktu sholat ${PrayerTimesService.getPrayerDisplayName(prayerName)}. Yuk segera ke masjid! 🤲',
        scheduledTime: tomorrowPrayerTime,
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

          // Schedule reminder sebelum kegiatan (native)
          if (reminderTime.isAfter(DateTime.now())) {
            await NativeNotificationService.scheduleExactNotification(
              id: notificationId++,
              title: '📅 Pengingat: ${jadwal.nama}',
              body:
                  '$minutesBefore menit lagi ada kegiatan ${jadwal.nama}${jadwal.tempat != null ? ' di ${jadwal.tempat}' : ''}',
              scheduledTime: reminderTime,
            );
          }

          // Schedule notifikasi tepat waktu kegiatan (native)
          await NativeNotificationService.scheduleExactNotification(
            id: notificationId++,
            title: '📅 ${jadwal.nama}',
            body:
                'Kegiatan ${jadwal.nama} dimulai sekarang!${jadwal.tempat != null ? ' Lokasi: ${jadwal.tempat}' : ''}',
            scheduledTime: jadwalTime,
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

  /// Cancel semua prayer reminders
  static Future<void> cancelPrayerReminders() async {
    // Cancel range of prayer notification IDs (using native service)
    for (
      int i = _prayerReminderIdStart;
      i < _prayerReminderIdStart + 200;
      i++
    ) {
      await NativeNotificationService.cancelNotification(i);
    }
    print('🗑️ Cancelled all prayer reminders');
  }

  /// Cancel semua jadwal reminders
  static Future<void> cancelJadwalReminders() async {
    // Cancel range of schedule notification IDs (using native service)
    for (
      int i = _scheduleReminderIdStart;
      i < _scheduleReminderIdStart + 1000;
      i++
    ) {
      await NativeNotificationService.cancelNotification(i);
    }
    print('🗑️ Cancelled all schedule reminders');
  }

  /// Cancel semua reminders
  static Future<void> cancelAllReminders() async {
    // Cancel both prayer and schedule reminders
    await cancelPrayerReminders();
    await cancelJadwalReminders();
    print('🗑️ Cancelled all reminders');
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

  /// Schedule test notification untuk beberapa detik ke depan (NATIVE)
  static Future<void> scheduleTestNotification({
    required int secondsFromNow,
    String title = '⏰ Test Reminder',
    String body = 'Test reminder dijadwalkan muncul!',
  }) async {
    try {
      final scheduledTime = DateTime.now().add(
        Duration(seconds: secondsFromNow),
      );

      print('🔔 Scheduling native test notification:');
      print('   - Will trigger in: $secondsFromNow seconds');
      print('   - Scheduled time: $scheduledTime');

      final success = await NativeNotificationService.scheduleExactNotification(
        id: 998,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );

      if (success) {
        print('✅ Test notification scheduled successfully!');
      } else {
        print('❌ Failed to schedule test notification');
      }
    } catch (e) {
      print('❌ Error scheduling test notification: $e');
      rethrow;
    }
  }

  /// Debug info - Print semua notification settings
  static Future<void> printDebugInfo() async {
    print('\n═══════════════════════════════════════');
    print('🔍 REMINDER SERVICE DEBUG INFO');
    print('═══════════════════════════════════════');

    // Timezone
    print('⏰ Timezone: ${tz.local.name}');
    print('📅 Current time: ${tz.TZDateTime.now(tz.local)}');

    // Permissions
    final canExact = await canScheduleExactAlarms();
    print('✅ Exact alarm permission: $canExact');

    // Pending notifications
    final pending = await _notifications.pendingNotificationRequests();
    print('📋 Pending notifications: ${pending.length}');
    for (var notif in pending) {
      print('   - ID ${notif.id}: ${notif.title}');
    }

    // Preferences
    final prefs = await SharedPreferences.getInstance();
    final prayerEnabled = prefs.getBool(_keyPrayerReminderEnabled) ?? true;
    final scheduleEnabled = prefs.getBool(_keyScheduleReminderEnabled) ?? true;
    final prayerMinutes = prefs.getInt(_keyPrayerReminderMinutes) ?? 10;
    final scheduleMinutes = prefs.getInt(_keyScheduleReminderMinutes) ?? 15;

    print('🕌 Prayer reminder: $prayerEnabled ($prayerMinutes min before)');
    print(
      '📅 Schedule reminder: $scheduleEnabled ($scheduleMinutes min before)',
    );
    print('🔔 Using native AlarmManager for reliable scheduling');

    print('═══════════════════════════════════════\n');
  }
}
