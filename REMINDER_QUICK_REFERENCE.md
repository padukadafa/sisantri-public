# 🕌 Quick Reference - Sistem Pengingat

## 📦 Package Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
  flutter_timezone: ^3.0.1
  shared_preferences: ^2.3.2
```

## 🚀 Quick Start

### 1. Initialize (Sudah disetup di main.dart)

```dart
await ReminderService.initialize();
```

### 2. Tambahkan Widget di Dashboard

```dart
import 'package:sisantri/features/santri/dashboard/presentation/widgets/prayer_times_widget.dart';

NextPrayerCard()  // Waktu sholat berikutnya + countdown
PrayerTimesCard() // Semua waktu sholat hari ini
```

### 3. Tambahkan Settings Page

```dart
import 'package:sisantri/features/santri/profile/presentation/pages/reminder_settings_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ReminderSettingsPage()),
);
```

## 🎯 API Reference

### ReminderService

```dart
// Initialize
await ReminderService.initialize();

// Prayer Reminders
await ReminderService.setPrayerReminderEnabled(true);
await ReminderService.setPrayerReminderMinutes(10); // 5, 10, 15, 30
bool enabled = await ReminderService.isPrayerReminderEnabled();
int minutes = await ReminderService.getPrayerReminderMinutes();

// Schedule Reminders
await ReminderService.setScheduleReminderEnabled(true);
await ReminderService.setScheduleReminderMinutes(15); // 5, 10, 15, 30, 60
bool enabled = await ReminderService.isScheduleReminderEnabled();
int minutes = await ReminderService.getScheduleReminderMinutes();

// Manual Control
await ReminderService.schedulePrayerReminders();
await ReminderService.scheduleJadwalReminders();
await ReminderService.refreshReminders(); // Refresh all
await ReminderService.cancelAllReminders();
```

### PrayerTimesService

```dart
// Get prayer times
Map<String, DateTime> times = PrayerTimesService.getTodayPrayerTimes();
// Returns: {'subuh': DateTime, 'dzuhur': DateTime, ...}

// Get next prayer
Map<String, dynamic>? next = PrayerTimesService.getNextPrayerTime();
// Returns: {'name': 'dzuhur', 'time': DateTime}

// Check current prayer time (±5 minutes)
Map<String, dynamic>? current = PrayerTimesService.getCurrentPrayerTime();

// Format helpers
String formatted = PrayerTimesService.formatPrayerTime(dateTime);
String displayName = PrayerTimesService.getPrayerDisplayName('subuh');

// Get all for display
List<Map<String, dynamic>> all = PrayerTimesService.getAllPrayerTimesForDisplay();
```

## 🔔 Notification IDs

```
Prayer Reminders:  1000-1199
- Today:          1000-1099
- Tomorrow:       1100-1199

Schedule Reminders: 2000-2999
- Up to 1000 schedules
```

## ⏰ Default Prayer Times (Bandar Lampung)

```
Subuh:   04:30
Dzuhur:  12:00
Ashar:   15:15
Maghrib: 18:00
Isya:    19:15
```

## 📱 Notification Channels

```dart
// Prayer Channel
ID: 'prayer_reminders'
Name: 'Pengingat Sholat'
Importance: High

// Schedule Channel
ID: 'schedule_reminders'
Name: 'Pengingat Jadwal'
Importance: High
```

## 🔄 Auto-Refresh Schedule

- **Tengah Malam**: Otomatis refresh setiap hari
- **App Resume**: Refresh jika hari berganti
- **Manual**: Call `refreshReminders()` setelah update jadwal

## ✅ Checklist Integration

- [ ] Install dependencies (`flutter pub get`)
- [ ] `ReminderService.initialize()` di main.dart (✅ Done)
- [ ] `ReminderLifecycleManager` wrapping MaterialApp (✅ Done)
- [ ] Tambahkan `NextPrayerCard` di dashboard
- [ ] Tambahkan `PrayerTimesCard` di dashboard
- [ ] Tambahkan menu ke `ReminderSettingsPage` di profile
- [ ] Call `refreshReminders()` setelah admin update jadwal
- [ ] Test notifications
- [ ] Request notification permissions

## 🐛 Common Issues

**Notifikasi tidak muncul?**

```dart
// 1. Check permissions
await Permission.notification.request();

// 2. Check battery optimization (Android)
// Settings > Apps > Your App > Battery > Unrestricted

// 3. Check exact alarm permission (Android 12+)
await Permission.scheduleExactAlarm.request();
```

**Reminder tidak auto-refresh?**

```dart
// Ensure ReminderLifecycleManager wraps MaterialApp
ReminderLifecycleManager(
  child: MaterialApp(...),
)
```

**Waktu tidak akurat?**

```dart
// Update defaultPrayerTimes in prayer_times_service.dart
static const Map<String, String> defaultPrayerTimes = {
  'subuh': '04:30', // Update this
  // ...
};
```

## 📊 Testing Commands

```bash
# Check for errors
flutter analyze

# Run app
flutter run

# Test notifications (set reminder to 1 minute)
# Then wait for notification
```

## 🎨 UI Components

### NextPrayerCard

- Shows next prayer with countdown
- Gradient green background
- Live updating timer
- Mosque icon

### PrayerTimesCard

- Lists all 5 prayer times
- Shows "Sekarang" badge for current prayer
- Checkmark for passed prayers
- Clean, minimal design

### ReminderSettingsPage

- Toggle prayer/schedule reminders
- Select reminder minutes
- View today's prayer times
- Refresh button
- Info card with instructions

## 🔧 Advanced

### Custom Prayer Times API

```dart
// Integrate with Aladhan API
// https://aladhan.com/prayer-times-api

final response = await http.get(
  Uri.parse('http://api.aladhan.com/v1/timingsByCity'
    '?city=Bandar Lampung&country=Indonesia'),
);
```

### Admin Panel Integration

```dart
// Store in Firestore
FirebaseFirestore.instance
  .collection('prayer_times')
  .doc('config')
  .set({
    'subuh': '04:30',
    'dzuhur': '12:00',
    // ...
  });
```

---

**Quick Links:**

- [Full Documentation](REMINDER_SYSTEM_GUIDE.md)
- [Integration Examples](REMINDER_INTEGRATION_EXAMPLE.dart)
- [Source Code](lib/shared/services/reminder_service.dart)
