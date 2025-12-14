import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';

/// Service untuk mengelola waktu sholat
/// Menggunakan package adhan_dart untuk kalkulasi akurat berdasarkan koordinat
class PrayerTimesService {
  // Koordinat untuk Bandar Lampung, Indonesia
  static const double latitude = -5.4292;
  static const double longitude = 105.2625;

  /// Get waktu sholat untuk hari ini
  static Map<String, DateTime> getTodayPrayerTimes() {
    final now = DateTime.now();
    final coordinates = Coordinates(latitude, longitude);

    // Calculate prayer times menggunakan metode Singapore (cocok untuk Indonesia)
    final calculationParams = CalculationMethodParameters.singapore();
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: now,
      calculationParameters: calculationParams,
      precision: true,
    );

    // Konversi dari UTC ke WIB (UTC+7)
    const wibOffset = Duration(hours: 7);

    return {
      'subuh': prayerTimes.fajr.add(wibOffset),
      'dzuhur': prayerTimes.dhuhr.add(wibOffset),
      'ashar': prayerTimes.asr.add(wibOffset),
      'maghrib': prayerTimes.maghrib.add(wibOffset),
      'isya': prayerTimes.isha.add(wibOffset),
    };
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
    final coordinates = Coordinates(latitude, longitude);

    final calculationParams = CalculationMethodParameters.singapore();
    final tomorrowPrayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: tomorrow,
      calculationParameters: calculationParams,
      precision: true,
    );

    // Konversi dari UTC ke WIB (UTC+7)
    const wibOffset = Duration(hours: 7);
    return {'name': 'subuh', 'time': tomorrowPrayerTimes.fajr.add(wibOffset)};
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

  /// Get koordinat Bandar Lampung (bisa di-customize untuk lokasi lain)
  static Coordinates getCoordinates() {
    return Coordinates(latitude, longitude);
  }

  /// Get calculation parameters (bisa di-customize)
  static CalculationParameters getCalculationParams() {
    return CalculationMethodParameters.singapore();
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
