import 'package:intl/intl.dart';

/// Service untuk mengelola waktu sholat
/// Menggunakan waktu standar untuk Bandar Lampung
class PrayerTimesService {
  // Waktu sholat default untuk Bandar Lampung
  // Bisa disesuaikan berdasarkan koordinat atau API
  static const Map<String, String> defaultPrayerTimes = {
    'subuh': '04:30',
    'dzuhur': '12:00',
    'ashar': '15:15',
    'maghrib': '18:00',
    'isya': '19:15',
  };

  /// Get waktu sholat untuk hari ini
  static Map<String, DateTime> getTodayPrayerTimes() {
    final now = DateTime.now();
    final Map<String, DateTime> prayerTimes = {};

    defaultPrayerTimes.forEach((prayer, time) {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      prayerTimes[prayer] = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
    });

    return prayerTimes;
  }

  /// Get waktu sholat berikutnya
  static Map<String, dynamic>? getNextPrayerTime() {
    final now = DateTime.now();
    final prayerTimes = getTodayPrayerTimes();

    for (var entry in prayerTimes.entries) {
      if (entry.value.isAfter(now)) {
        return {'name': entry.key, 'time': entry.value};
      }
    }

    // Jika semua waktu sholat hari ini sudah lewat, return Subuh besok
    final tomorrow = now.add(const Duration(days: 1));
    final timeParts = defaultPrayerTimes['subuh']!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return {
      'name': 'subuh',
      'time': DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      ),
    };
  }

  /// Check apakah sekarang waktu sholat (dalam range ±5 menit)
  static Map<String, dynamic>? getCurrentPrayerTime() {
    final now = DateTime.now();
    final prayerTimes = getTodayPrayerTimes();

    for (var entry in prayerTimes.entries) {
      final diff = entry.value.difference(now).inMinutes.abs();
      if (diff <= 5) {
        return {'name': entry.key, 'time': entry.value};
      }
    }

    return null;
  }

  /// Format waktu sholat untuk display
  static String formatPrayerTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Get nama sholat dalam bahasa Indonesia yang proper
  static String getPrayerDisplayName(String prayerName) {
    const displayNames = {
      'subuh': 'Subuh',
      'dzuhur': 'Dzuhur',
      'ashar': 'Ashar',
      'maghrib': 'Maghrib',
      'isya': 'Isya',
    };

    return displayNames[prayerName.toLowerCase()] ?? prayerName;
  }

  /// Update waktu sholat (untuk admin yang ingin custom)
  static void updatePrayerTime(String prayer, String time) {
    // TODO: Simpan ke SharedPreferences atau Firestore
    // Untuk implementasi sustainable, simpan di Firestore agar bisa di-update dari admin panel
  }

  /// Get semua waktu sholat untuk display
  static List<Map<String, dynamic>> getAllPrayerTimesForDisplay() {
    final prayerTimes = getTodayPrayerTimes();
    return prayerTimes.entries.map((entry) {
      return {
        'name': entry.key,
        'displayName': getPrayerDisplayName(entry.key),
        'time': entry.value,
        'formattedTime': formatPrayerTime(entry.value),
      };
    }).toList();
  }
}
