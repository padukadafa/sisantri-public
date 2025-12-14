# Native Notification Quick Reference

## 🚀 Quick Start

### Schedule a Notification

```dart
import 'package:sisantri/shared/services/native_notification_service.dart';

// Schedule notification
final scheduledTime = DateTime.now().add(Duration(minutes: 10));
await NativeNotificationService.scheduleExactNotification(
  id: 1001,
  title: '🕌 Prayer Reminder',
  body: '10 minutes until prayer time',
  scheduledTime: scheduledTime,
);
```

### Cancel a Notification

```dart
await NativeNotificationService.cancelNotification(1001);
```

---

## 📋 Complete API

### scheduleExactNotification()

**Purpose:** Schedule exact-time notification using native AlarmManager

**Parameters:**
- `id` (int, required): Unique notification ID
- `title` (String, required): Notification title
- `body` (String, required): Notification body text
- `scheduledTime` (DateTime, required): When to show notification

**Returns:** `Future<bool>` - true if successful

**Example:**
```dart
final success = await NativeNotificationService.scheduleExactNotification(
  id: 2001,
  title: '📅 Schedule Reminder',
  body: '15 minutes until meeting',
  scheduledTime: DateTime.now().add(Duration(minutes: 15)),
);

if (success) {
  print('✅ Notification scheduled');
} else {
  print('❌ Failed to schedule');
}
```

---

### cancelNotification()

**Purpose:** Cancel a scheduled notification

**Parameters:**
- `id` (int, required): ID of notification to cancel

**Returns:** `Future<bool>` - true if successful

**Example:**
```dart
await NativeNotificationService.cancelNotification(2001);
```

---

## 🔢 Notification ID Ranges

**Reserved Ranges:**
- `1000-1199`: Prayer reminders
- `2000-2999`: Schedule reminders  
- `997-999`: Test notifications

**Your Custom IDs:**
Use IDs outside reserved ranges (e.g., `3000+`)

---

## ⚠️ Important Notes

### ✅ DO
- Use unique IDs for each notification
- Schedule future times only (`scheduledTime > now`)
- Request permissions before scheduling
- Handle scheduling failures gracefully

### ❌ DON'T
- Reuse IDs without canceling first
- Schedule past times
- Assume scheduling always succeeds
- Forget to handle errors

---

## 🧪 Testing

### Test in UI
Navigate to: **Settings → Reminder Test Page**

Use purple "Native AlarmManager Test" section:
- **Native 10s** - Test 10 second notification
- **Native 30s** - Test 30 second notification

### Test Programmatically
```dart
import 'package:sisantri/shared/services/native_notification_service.dart';

// Quick 10 second test
await NativeNotificationService.scheduleExactNotification(
  id: 999,
  title: '⏰ Test',
  body: 'This is a test notification',
  scheduledTime: DateTime.now().add(Duration(seconds: 10)),
);

print('✅ Test scheduled - wait 10 seconds');
```

---

## 🐛 Troubleshooting

### Notification Not Appearing?

**1. Check Permissions:**
```dart
import 'package:sisantri/shared/services/reminder_service.dart';

await ReminderService.requestPermissions();
final canUse = await ReminderService.canScheduleExactAlarms();
print('Can schedule exact alarms: $canUse');
```

**2. Verify Scheduling:**
```dart
final success = await NativeNotificationService.scheduleExactNotification(
  id: 999,
  title: 'Test',
  body: 'Test body',
  scheduledTime: DateTime.now().add(Duration(seconds: 30)),
);
print('Scheduling result: $success');
```

**3. Check Logs:**
Look for these messages:
- ✅ `Native notification scheduled: ID=999 at ...`
- ❌ `Error scheduling native notification: ...`

**4. Test with Longer Delay:**
```dart
// Try 60 seconds instead of 10
await NativeNotificationService.scheduleExactNotification(
  id: 999,
  title: 'Test',
  body: 'Testing with 60 seconds',
  scheduledTime: DateTime.now().add(Duration(seconds: 60)),
);
```

---

## 📱 Platform Support

### Android
✅ **Fully Supported**
- Native AlarmManager implementation
- Exact timing guaranteed
- Works in Doze mode

### iOS
⚠️ **Not Yet Implemented**
- Falls back to Flutter local notifications
- May need separate iOS implementation
- iOS has different notification system

**Check Platform:**
```dart
import 'dart:io';

if (Platform.isAndroid) {
  // Use native notification
  await NativeNotificationService.scheduleExactNotification(...);
} else {
  // Use Flutter plugin or iOS-specific implementation
  await ReminderService.showNotification(...);
}
```

---

## 🔐 Permissions

### Required Android Permissions
```xml
<!-- Already configured in AndroidManifest.xml -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Request at Runtime
```dart
import 'package:sisantri/shared/services/reminder_service.dart';

// Request all notification permissions
await ReminderService.requestPermissions();

// Check specific permission
final canSchedule = await ReminderService.canScheduleExactAlarms();
if (!canSchedule) {
  // Show user a message to enable exact alarm permission
  print('⚠️ Exact alarm permission needed');
}
```

---

## 💡 Best Practices

### 1. Use Unique IDs
```dart
// ✅ GOOD - Unique ID for each notification
int notificationId = 1000;
for (var prayer in prayers) {
  await NativeNotificationService.scheduleExactNotification(
    id: notificationId++,  // Increment ID
    title: prayer.name,
    body: prayer.reminder,
    scheduledTime: prayer.time,
  );
}

// ❌ BAD - Reusing same ID
for (var prayer in prayers) {
  await NativeNotificationService.scheduleExactNotification(
    id: 1000,  // Same ID - will overwrite previous!
    ...
  );
}
```

### 2. Cancel Before Rescheduling
```dart
// ✅ GOOD - Cancel first, then reschedule
await NativeNotificationService.cancelNotification(1001);
await NativeNotificationService.scheduleExactNotification(
  id: 1001,
  ...
);

// ❌ BAD - Scheduling without canceling may cause issues
await NativeNotificationService.scheduleExactNotification(
  id: 1001,  // Old alarm might still exist
  ...
);
```

### 3. Validate Time
```dart
// ✅ GOOD - Check time is in future
final scheduledTime = calculateTime();
if (scheduledTime.isAfter(DateTime.now())) {
  await NativeNotificationService.scheduleExactNotification(
    id: 1001,
    title: 'Reminder',
    body: 'Scheduled notification',
    scheduledTime: scheduledTime,
  );
} else {
  print('⚠️ Cannot schedule past time');
}

// ❌ BAD - No validation
await NativeNotificationService.scheduleExactNotification(
  scheduledTime: pastTime,  // Will fail silently
  ...
);
```

### 4. Handle Errors
```dart
// ✅ GOOD - Try-catch with fallback
try {
  final success = await NativeNotificationService.scheduleExactNotification(
    id: 1001,
    title: 'Reminder',
    body: 'Important notification',
    scheduledTime: DateTime.now().add(Duration(hours: 1)),
  );
  
  if (!success) {
    // Fallback or show user message
    print('⚠️ Failed to schedule notification');
  }
} catch (e) {
  print('❌ Error: $e');
  // Handle error appropriately
}

// ❌ BAD - No error handling
await NativeNotificationService.scheduleExactNotification(...);
// What if it fails?
```

---

## 📊 Examples

### Prayer Reminder
```dart
Future<void> schedulePrayerReminder(String prayerName, DateTime prayerTime) async {
  final reminderTime = prayerTime.subtract(Duration(minutes: 10));
  
  await NativeNotificationService.scheduleExactNotification(
    id: 1001,
    title: '🕌 Prayer Reminder',
    body: '10 minutes until $prayerName prayer',
    scheduledTime: reminderTime,
  );
}
```

### Schedule Reminder
```dart
Future<void> scheduleEventReminder(String eventName, DateTime eventTime) async {
  // 15 minutes before
  final reminderTime = eventTime.subtract(Duration(minutes: 15));
  
  await NativeNotificationService.scheduleExactNotification(
    id: 2001,
    title: '📅 Event Reminder',
    body: '15 minutes until $eventName',
    scheduledTime: reminderTime,
  );
  
  // Exact time
  await NativeNotificationService.scheduleExactNotification(
    id: 2002,
    title: '📅 $eventName',
    body: 'Event starting now!',
    scheduledTime: eventTime,
  );
}
```

### Daily Recurring Reminder
```dart
Future<void> scheduleDailyReminder() async {
  // Schedule for today
  final today = DateTime.now();
  final todayReminder = DateTime(today.year, today.month, today.day, 8, 0); // 8 AM
  
  if (todayReminder.isAfter(DateTime.now())) {
    await NativeNotificationService.scheduleExactNotification(
      id: 3001,
      title: '☀️ Good Morning',
      body: 'Start your day!',
      scheduledTime: todayReminder,
    );
  }
  
  // Schedule for tomorrow
  final tomorrow = today.add(Duration(days: 1));
  final tomorrowReminder = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
  
  await NativeNotificationService.scheduleExactNotification(
    id: 3002,
    title: '☀️ Good Morning',
    body: 'Start your day!',
    scheduledTime: tomorrowReminder,
  );
}
```

### Multiple Notifications
```dart
Future<void> scheduleMultipleReminders(List<Reminder> reminders) async {
  int id = 4000;
  
  for (var reminder in reminders) {
    final success = await NativeNotificationService.scheduleExactNotification(
      id: id++,
      title: reminder.title,
      body: reminder.body,
      scheduledTime: reminder.time,
    );
    
    if (!success) {
      print('❌ Failed to schedule: ${reminder.title}');
    }
  }
  
  print('✅ Scheduled ${reminders.length} notifications');
}
```

---

## 🔗 Related Documentation

- [Native Notification Migration](NATIVE_NOTIFICATION_MIGRATION.md) - Full migration details
- [Reminder System Guide](REMINDER_SYSTEM_GUIDE.md) - Overall reminder architecture
- [Testing Guide](REMINDER_TESTING_GUIDE.md) - Comprehensive testing instructions

---

**Version:** 1.0  
**Last Updated:** Current session  
**Status:** ✅ Production Ready
