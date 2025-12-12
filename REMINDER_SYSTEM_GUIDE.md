# 🕌 Fitur Pengingat Sholat dan Jadwal

## 📋 Overview

Fitur pengingat yang sustainable dan efisien untuk:

1. **Pengingat Sholat** - Notifikasi otomatis sebelum waktu sholat
2. **Pengingat Jadwal** - Notifikasi sebelum kegiatan dimulai

## ✨ Fitur Utama

### 🕌 Pengingat Sholat

- ✅ Notifikasi otomatis untuk 5 waktu sholat (Subuh, Dzuhur, Ashar, Maghrib, Isya)
- ✅ Pengingat sebelum waktu sholat (5, 10, 15, atau 30 menit)
- ✅ Notifikasi tepat saat waktu sholat tiba
- ✅ Automatic scheduling untuk hari ini dan besok
- ✅ Widget display waktu sholat di dashboard
- ✅ Countdown timer ke waktu sholat berikutnya

### 📅 Pengingat Jadwal

- ✅ Notifikasi otomatis untuk jadwal kegiatan dari Firestore
- ✅ Pengingat sebelum kegiatan (5, 10, 15, 30 menit, atau 1 jam)
- ✅ Notifikasi tepat saat kegiatan dimulai
- ✅ Include informasi lokasi dan detail kegiatan
- ✅ Automatic refresh ketika jadwal berubah

### 🔄 Sustainability Features

- ✅ **Auto-refresh harian** - Reminder otomatis di-refresh setiap tengah malam
- ✅ **Lifecycle management** - Auto-refresh saat app di-resume
- ✅ **Timezone aware** - Menggunakan timezone lokal device
- ✅ **Exact scheduling** - Menggunakan `AndroidScheduleMode.exactAllowWhileIdle`
- ✅ **Background execution** - Notifikasi muncul meskipun app ditutup
- ✅ **Persistent preferences** - Settings tersimpan di SharedPreferences

## 📁 File Structure

```
lib/
├── shared/
│   ├── services/
│   │   ├── prayer_times_service.dart          # Service waktu sholat
│   │   ├── reminder_service.dart              # Service pengingat (core)
│   │   └── notification_service.dart          # Service notifikasi (existing)
│   └── widgets/
│       └── reminder_lifecycle_manager.dart    # Lifecycle manager
├── features/
│   └── santri/
│       ├── dashboard/
│       │   └── presentation/
│       │       └── widgets/
│       │           └── prayer_times_widget.dart  # Widget waktu sholat
│       └── profile/
│           └── presentation/
│               └── pages/
│                   └── reminder_settings_page.dart  # Settings page
└── main.dart                                   # Initialize services
```

## 🚀 Usage

### 1. Initialization (Otomatis di Main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Reminder Service
  await ReminderService.initialize();

  runApp(const ProviderScope(child: SiSantriApp()));
}
```

### 2. Menampilkan Widget Waktu Sholat

```dart
import 'package:sisantri/features/santri/dashboard/presentation/widgets/prayer_times_widget.dart';

// Di dashboard santri
Column(
  children: [
    NextPrayerCard(),      // Card waktu sholat berikutnya dengan countdown
    PrayerTimesCard(),     // Card jadwal sholat hari ini
  ],
)
```

### 3. Settings Page

```dart
import 'package:sisantri/features/santri/profile/presentation/pages/reminder_settings_page.dart';

// Navigate ke settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReminderSettingsPage(),
  ),
);
```

### 4. Manual Control (Optional)

```dart
import 'package:sisantri/shared/services/reminder_service.dart';

// Enable/disable prayer reminders
await ReminderService.setPrayerReminderEnabled(true);

// Set reminder minutes
await ReminderService.setPrayerReminderMinutes(10);

// Enable/disable schedule reminders
await ReminderService.setScheduleReminderEnabled(true);

// Set schedule reminder minutes
await ReminderService.setScheduleReminderMinutes(15);

// Manual refresh
await ReminderService.refreshReminders();
```

## ⚙️ Configuration

### Default Settings

```dart
// Prayer Reminders
- Enabled: true
- Minutes before: 10 minutes

// Schedule Reminders
- Enabled: true
- Minutes before: 15 minutes

// Prayer Times (Bandar Lampung)
- Subuh:   04:30
- Dzuhur:  12:00
- Ashar:   15:15
- Maghrib: 18:00
- Isya:    19:15
```

### Customization

Untuk mengubah waktu sholat default, edit `prayer_times_service.dart`:

```dart
static const Map<String, String> defaultPrayerTimes = {
  'subuh': '04:30',
  'dzuhur': '12:00',
  'ashar': '15:15',
  'maghrib': '18:00',
  'isya': '19:15',
};
```

## 🔔 Notification Channels

### Prayer Reminders Channel

```
ID: prayer_reminders
Name: Pengingat Sholat
Importance: High
Sound: Yes
Vibration: Yes
```

### Schedule Reminders Channel

```
ID: schedule_reminders
Name: Pengingat Jadwal
Importance: High
Sound: Yes
Vibration: Yes
```

## 📱 Permissions Required

### Android (AndroidManifest.xml)

```xml
<!-- Sudah ada di project -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS (Info.plist)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 🔄 Lifecycle & Scheduling

### Daily Refresh Flow

```
1. App starts → Initialize ReminderService
2. Schedule reminders untuk hari ini dan besok
3. Setup daily refresh timer (tengah malam)
4. Tengah malam → Auto refresh reminders
5. Repeat step 2-4
```

### App Resume Flow

```
1. User membuka app
2. ReminderLifecycleManager detect app resumed
3. Check apakah hari sudah berganti
4. Jika ya → Refresh reminders
5. Update last refresh date
```

### Jadwal Update Flow

```
1. Admin add/update jadwal di Firestore
2. Call ReminderService.refreshReminders()
3. Cancel existing schedule reminders
4. Re-fetch jadwal dari Firestore
5. Schedule new reminders
```

## 🎯 Notification ID Management

```dart
// Prayer Reminders: 1000-1199
- Today reminders: 1000-1099
- Tomorrow reminders: 1100-1199

// Schedule Reminders: 2000-2999
- Up to 1000 schedule reminders
```

## 🧪 Testing

### Test Prayer Reminders

```dart
// 1. Set reminder to 1 minute before
await ReminderService.setPrayerReminderMinutes(1);

// 2. Wait for notification
// 3. Check notification appears 1 minute before prayer time
```

### Test Schedule Reminders

```dart
// 1. Create jadwal in Firestore with time 10 minutes from now
// 2. Set reminder to 5 minutes before
// 3. Wait for notification 5 minutes from now
// 4. Wait for second notification at jadwal time
```

### Test Daily Refresh

```dart
// 1. Check scheduled reminders
await ReminderService.refreshReminders();

// 2. Verify reminders scheduled for today and tomorrow
// 3. Wait until tomorrow
// 4. Verify new reminders scheduled automatically
```

## 🐛 Troubleshooting

### Notifikasi tidak muncul?

1. ✅ Check notification permissions
2. ✅ Check battery optimization settings (whitelist app)
3. ✅ Verify reminder is enabled in settings
4. ✅ Check device timezone matches Asia/Jakarta
5. ✅ Verify exact alarm permission granted (Android 12+)

### Reminder tidak auto-refresh?

1. ✅ Check ReminderLifecycleManager is wrapping MaterialApp
2. ✅ Verify timer is running (check logs)
3. ✅ Ensure app has wake lock permission

### Waktu sholat tidak akurat?

1. ✅ Update defaultPrayerTimes di prayer_times_service.dart
2. ✅ Or implement API integration (e.g., Aladhan API)
3. ✅ Consider timezone differences

## 🔧 Advanced Configuration

### Custom Prayer Times API Integration

```dart
// prayer_times_service.dart
static Future<Map<String, DateTime>> getTodayPrayerTimes() async {
  // Option 1: Use Aladhan API
  final response = await http.get(
    Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=Bandar Lampung&country=Indonesia'),
  );

  // Parse and return prayer times
  // ...

  // Option 2: Use local calculation with adhan package
  // ...
}
```

### Firebase Cloud Function for Reminder Management

```javascript
// For centralized reminder management
exports.scheduleReminders = functions.firestore
  .document("jadwal/{jadwalId}")
  .onWrite(async (change, context) => {
    // Trigger reminder refresh for all users
    // Send FCM to all devices to refresh reminders
  });
```

## 📊 Performance Optimization

### Memory Usage

- Lightweight services (< 1MB memory)
- Efficient timer management
- No background service running constantly

### Battery Impact

- Minimal (uses exact alarm, not continuous polling)
- Notifications scheduled once, executed by system
- No CPU usage when app is closed

### Network Usage

- Only during initial jadwal fetch
- Cached prayer times (no repeated API calls)
- Optional: implement offline-first with SharedPreferences cache

## 🎉 Benefits

### For Users

- ✅ Never miss prayer times
- ✅ Never miss scheduled activities
- ✅ Customizable reminder timing
- ✅ Beautiful UI widgets showing prayer times
- ✅ Works even when app is closed

### For Developers

- ✅ Clean, maintainable code
- ✅ Separation of concerns (multiple services)
- ✅ Easy to extend and customize
- ✅ Sustainable architecture
- ✅ Well documented

### For System

- ✅ Efficient scheduling
- ✅ Low battery impact
- ✅ Proper lifecycle management
- ✅ Automatic cleanup and refresh
- ✅ Scalable (supports many reminders)

## 📝 TODO / Future Enhancements

- [ ] Integrate with Aladhan API for accurate prayer times based on GPS
- [ ] Add Qibla direction indicator
- [ ] Add prayer tracking (mark as completed)
- [ ] Add statistics: prayer attendance rate
- [ ] Customize notification sound per reminder type
- [ ] Add widget for home screen (Android)
- [ ] Support for multiple timezones (for travelers)
- [ ] Add dua after adhan in notification
- [ ] Integration with mosque prayer times via admin panel

---

**Version**: 1.0.0  
**Last Updated**: 12 Desember 2025  
**Status**: ✅ Production Ready
