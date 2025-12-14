# 🔧 Fix: exact_alarm_not_permitted

## 📋 Problem Description

Error `exact_alarm_not_permitted` terjadi di Android 12+ (API level 31+) ketika aplikasi mencoba menjadwalkan notifikasi dengan waktu yang tepat (exact alarm) tanpa permission yang sesuai.

---

## ✅ Solution Implemented

### 1. **AndroidManifest.xml** - Added Permissions

```xml
<!-- For exact alarms (Android 12+) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

**Location:** `/android/app/src/main/AndroidManifest.xml`

**What it does:**

- `SCHEDULE_EXACT_ALARM`: Allows app to schedule exact alarms (user must grant)
- `USE_EXACT_ALARM`: For time-sensitive apps (auto-granted, no user prompt)

---

### 2. **ReminderService** - Permission Handling

#### Added Import:

```dart
import 'package:permission_handler/permission_handler.dart';
```

#### Added Methods:

**a) Request Permission:**

```dart
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
```

**b) Check Permission:**

```dart
static Future<bool> canScheduleExactAlarms() async {
  try {
    return await Permission.scheduleExactAlarm.isGranted;
  } catch (e) {
    return false;
  }
}
```

**c) Initialize with Permission Request:**

```dart
static Future<void> initialize() async {
  // ... existing timezone setup ...

  // Request exact alarm permission for Android 12+
  await requestExactAlarmPermission();

  // ... continue with scheduling ...
}
```

**d) Smart Scheduling Mode:**

```dart
static Future<void> _scheduleNotification({...}) async {
  // Determine scheduling mode based on permission
  final canUseExact = await canScheduleExactAlarms();
  final scheduleMode = canUseExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  await _notifications.zonedSchedule(
    id,
    title,
    body,
    scheduledTime,
    notificationDetails,
    androidScheduleMode: scheduleMode, // Dynamic mode
    // ...
  );
}
```

---

## 🎯 How It Works

### Permission Flow:

1. **App Starts** → `ReminderService.initialize()` called
2. **Check Permission** → `canScheduleExactAlarms()`
   - ✅ If granted → Use `exactAllowWhileIdle`
   - ❌ If not granted → Request permission
3. **Request Permission** → `requestExactAlarmPermission()`
   - Opens system settings for user to grant
4. **Fallback Mode** → If denied → Use `inexactAllowWhileIdle`

### Scheduling Modes:

| Mode                    | Accuracy    | Permission Required | When Used          |
| ----------------------- | ----------- | ------------------- | ------------------ |
| `exactAllowWhileIdle`   | Exact time  | ✅ Yes              | Permission granted |
| `inexactAllowWhileIdle` | ±15 minutes | ❌ No               | Permission denied  |

---

## 📱 User Experience

### First Time App Open:

```
1. App launches
2. Permission dialog appears:
   "Allow SiSantri to schedule exact alarms?"
3. User taps "Allow"
4. Notifications will be exact
```

### If User Denies:

```
1. App still works
2. Notifications scheduled with inexact mode
3. May have ±15 min delay
4. User can grant later in Settings
```

### Manual Grant (If Denied):

```
Settings → Apps → SiSantri → Alarms & reminders → Enable
```

---

## 🧪 Testing

### Test Permission Status:

```dart
final canUse = await ReminderService.canScheduleExactAlarms();
print('Can schedule exact alarms: $canUse');
```

### Test Permission Request:

```dart
final granted = await ReminderService.requestExactAlarmPermission();
print('Permission granted: $granted');
```

### Test Notification Scheduling:

1. Grant permission → Test 10s notification → Should arrive EXACTLY at 10s
2. Deny permission → Test 10s notification → May arrive 10s ± 15 min window

---

## ✅ Verification Checklist

- [x] AndroidManifest.xml has both permissions
- [x] permission_handler package in pubspec.yaml
- [x] `requestExactAlarmPermission()` method added
- [x] `canScheduleExactAlarms()` method added
- [x] Permission requested in `initialize()`
- [x] Dynamic scheduling mode in `_scheduleNotification()`
- [x] Fallback to inexact mode if permission denied
- [x] No crashes if permission denied

---

## 🔍 Error Messages

### Before Fix:

```
PlatformException(exact_alarm_not_permitted, Exact alarms are not permitted, null, null)
```

### After Fix:

```
✅ No error
- If granted: Uses exact scheduling
- If denied: Uses inexact scheduling (no crash)
```

---

## 📚 References

- [Android Exact Alarms](https://developer.android.com/about/versions/12/behavior-changes-12#exact-alarm-permission)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

---

## 📝 Notes

1. **Android 12+ Required**: Permission only needed for API 31+
2. **Auto-fallback**: App gracefully handles denied permission
3. **User Control**: User can grant/revoke anytime in Settings
4. **No Breaking**: Existing functionality preserved even if denied

---

**Status:** ✅ FIXED  
**Version:** 1.0  
**Date:** 14 Desember 2025  
**Tested On:** Android 12+ (API 31+)
