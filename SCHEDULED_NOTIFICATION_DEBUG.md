# 🐛 Debug: Scheduled Notification Tidak Muncul

## 📋 Problem

Scheduled notification (10 detik, 30 detik, 1 menit) tidak muncul sesuai waktu yang dijadwalkan, meskipun:
- ✅ Logger tertulis "berhasil dijadwalkan"
- ✅ Notification ada di pending list
- ❌ Notification TIDAK muncul setelah waktu yang ditentukan

---

## 🔍 Root Cause Analysis

Ini adalah masalah umum di Android dengan beberapa kemungkinan penyebab:

### 1. **Notification Plugin Tidak Fully Initialized**
Problem: Plugin `flutter_local_notifications` perlu di-initialize dengan proper settings dan permissions.

### 2. **Android Doze Mode**
Problem: Android mengoptimalkan battery dengan delay/skip scheduled notifications saat device idle.

### 3. **Exact Alarm Permission Not Working**
Problem: Meskipun permission "granted", sistem masih bisa ignore exact timing.

### 4. **Notification Channel Priority**
Problem: Channel dengan `Importance.high` bisa di-suppress oleh system.

---

## ✅ Fix yang Sudah Diimplementasi

### 1. **Full Plugin Initialization**
```dart
// ReminderService.initialize() sekarang include:
const AndroidInitializationSettings androidSettings = 
    AndroidInitializationSettings('@mipmap/ic_launcher');

await _notifications.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (response) {
    print('📱 Notification tapped: ${response.payload}');
  },
);

// Request notification permission (Android 13+)
await androidPlugin?.requestNotificationsPermission();
```

### 2. **Enhanced Notification Channel**
```dart
// Upgraded dari Importance.high → Importance.max
const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
  'prayer_reminders',
  'Pengingat Sholat',
  importance: Importance.max,  // CHANGED
  showBadge: true,             // NEW
);
```

### 3. **Full Android Notification Details**
```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'prayer_reminders',
  'Pengingat Sholat',
  importance: Importance.max,
  priority: Priority.high,
  fullScreenIntent: true,          // NEW - Bypass DND
  category: AndroidNotificationCategory.alarm,  // NEW
  visibility: NotificationVisibility.public,    // NEW
);
```

### 4. **Auto-Cancel Previous Test**
```dart
// Sebelum schedule baru, cancel yang lama dulu
await _notifications.cancel(998);
print('🗑️ Cancelled existing test notification (ID 998)');
```

### 5. **Enhanced Debug Logging**
```dart
print('🔔 Scheduling test notification:');
print('   - Now: $now');
print('   - Scheduled: $scheduledDate');
print('   - Difference: ${scheduledDate.difference(now).inSeconds} seconds');
print('   - Can use exact: $canUseExact');
print('   - Found in pending list: ${testNotif.isNotEmpty}');
```

### 6. **Debug Info Method**
```dart
// Button baru di AppBar: 🐛 (bug report icon)
ReminderService.printDebugInfo();

// Output:
// ═══════════════════════════════════════
// 🔍 REMINDER SERVICE DEBUG INFO
// ⏰ Timezone: Asia/Jakarta
// ✅ Exact alarm permission: true
// 📋 Pending notifications: 1
//    - ID 998: ⏰ Test Reminder 10 detik
// ═══════════════════════════════════════
```

---

## 🔍 Cara Debug (Updated)

### Step 1: Print Debug Info

1. **Buka Test Page** → Profile → Pengaturan Pengingat → Icon 🧪
2. **Tap icon 🐛** (bug report) di AppBar
3. **Check console output**:
```
═══════════════════════════════════════
🔍 REMINDER SERVICE DEBUG INFO
═══════════════════════════════════════
⏰ Timezone: Asia/Jakarta
📅 Current time: 2025-12-14 10:30:00.000+0700
✅ Exact alarm permission: true
📋 Pending notifications: 0
🕌 Prayer reminder enabled: true
📅 Schedule reminder enabled: true
═══════════════════════════════════════
```

**Good signs:**
- ✅ Timezone correct (Asia/Jakarta or your region)
- ✅ Exact alarm permission: true
- ✅ Current time is accurate

**Bad signs:**
- ❌ Exact alarm permission: false → Go to Settings
- ❌ Timezone wrong → Restart app
- ❌ Current time wrong → Check device time

### Step 2: Test Instant Notification First

**IMPORTANT:** Sebelum test scheduled, pastikan instant notification bekerja!

```
1. Tap "Kirim Test Instant"
2. Notifikasi HARUS muncul dalam <1 detik
3. Jika tidak muncul → Problem dengan notification channel/permission
4. Jika muncul → Lanjut ke Step 3
```

**Jika instant tidak muncul:**
```
❌ Plugin tidak properly initialized
❌ Notification permission denied
❌ Channel tidak dibuat

Solution:
1. Restart app (hot restart tidak cukup)
2. Check Settings → Apps → SiSantri → Notifications (Enable all)
3. Clear app data dan re-install
```

### Step 3: Schedule Test dengan Log Monitoring

```
1. Open terminal/console untuk monitor log
2. Tap "Test 10 detik"
3. IMMEDIATELY check console:

Expected log:
🗑️ Cancelled existing test notification (ID 998)
🔔 Scheduling test notification:
   - Now: 2025-12-14 10:30:00.000+0700
   - Scheduled: 2025-12-14 10:30:10.000+0700
   - Seconds: 10
   - Difference: 10 seconds
   - Can use exact: true
   - Schedule mode: AndroidScheduleMode.exactAllowWhileIdle
✅ Test notification scheduled successfully!
   - Notification ID: 998
   - Will trigger at: 2025-12-14 10:30:10.000+0700
   - Found in pending list: true  ← PENTING!

4. Tunggu TEPAT 10 detik
5. Check notification bar
```

**Jika "Found in pending list: false":**
```
❌ CRITICAL: Notification tidak masuk queue!
Possible causes:
- Permission issue (meskipun tertulis true)
- Android blocking exact alarms
- Plugin bug

Solution:
- Re-grant exact alarm permission
- Restart device
- Check battery optimization
```

### Step 4: Monitor Pending Notifications

```
1. Scroll ke "Pending Notifications" section
2. Harus ada item:
   ID: 998
   Title: "⏰ Test Reminder 10 detik"
   
3. Tap refresh (🔄) setiap 5 detik
4. Setelah 10 detik:
   - Notification harus muncul
   - ID 998 harus hilang dari pending list
```

**Jika ID 998 masih ada setelah >20 detik:**
```
❌ Notification stuck di queue
Possible causes:
- Android Doze mode active
- Battery optimization blocking
- Exact alarm permission not working

Solution:
- Check battery settings
- Disable power saving mode
- Tap notification di pending list (might trigger manually)
```

### Step 5: Verify Notification Settings

```
Android Settings:
1. Apps → SiSantri → Notifications
   - ✅ All notifications: ON
   - ✅ Pengingat Sholat: ON, Importance HIGH

2. Apps → SiSantri → Battery
   - ✅ Battery optimization: Don't optimize
   - ✅ Background restriction: Unrestricted

3. Apps → SiSantri → Alarms & reminders
   - ✅ Allow setting alarms and reminders: ON

4. System → Do Not Disturb
   - ✅ OFF atau SiSantri whitelisted
```

---

## 🔧 Common Issues & Solutions (Updated)

### Issue 1: Instant Test Works, Scheduled Doesn't
**Symptom:** 
- ✅ "Kirim Test Instant" muncul
- ❌ "Test 10 detik" tidak muncul
- ✅ Pending list shows ID 998

**Root Cause:** Android Doze mode atau battery optimization blocking scheduled alarms.

**Solution:**
```
1. Settings → Apps → SiSantri → Battery
   → Battery optimization → Don't optimize
   
2. Settings → Battery → Battery Saver → OFF
   
3. Settings → Developer Options → Standby apps
   → SiSantri → Active
   
4. Keep screen ON saat testing (untuk bypass Doze)

5. Alternative: Plug charger saat testing
```

### Issue 2: Permission Granted But Still Not Working
**Symptom:** 
- ✅ Log shows "Can use exact: true"
- ✅ Pending list has notification
- ❌ Notification never triggers

**Root Cause:** Android silently downgrading exact alarms to inexact.

**Solution:**
```
1. Go to Settings → Apps → SiSantri
   
2. Tap "Alarms & reminders"
   
3. You should see:
   - "Allow setting alarms and reminders" → ON
   - Below it: List of recent alarms
   
4. If no recent alarms shown:
   - Android is blocking
   - Try re-install app
   - Grant permission during first launch
   
5. Alternative approach:
   - Schedule "Test 1 menit" instead of 10 detik
   - Longer intervals more reliable
```

### Issue 3: Notification Found in Pending But Never Delivered
**Symptom:** 
- ✅ ID 998 in pending list
- ⏰ Wait >30 seconds
- ❌ Notification still in pending (not delivered)
- ❌ Never appears in notification bar

**Root Cause:** Notification stuck in queue, Android scheduler not triggering.

**Solution:**
```
IMMEDIATE FIX:
1. Tap "Cancel Test Notification" button
2. Wait 2 seconds
3. Tap "Test 10 detik" again
4. Check console for "Found in pending list: true"
5. If still stuck → Restart app (full restart, not hot reload)

PERMANENT FIX:
1. Clear app data:
   Settings → Apps → SiSantri → Storage → Clear data
   
2. Uninstall app completely
   
3. Re-install app
   
4. Grant ALL permissions during first launch:
   - Notifications
   - Exact alarms
   - Battery optimization exception
   
5. Test instant notification first
   
6. Then test scheduled notification
```

### Issue 4: Works on Some Devices, Not Others
**Symptom:** Same app, different behavior on different Android devices.

**Root Cause:** OEM-specific battery optimization (Samsung, Xiaomi, Huawei, Oppo).

**Solution by Brand:**

**Samsung:**
```
1. Settings → Apps → SiSantri → Battery → Optimize battery usage
   → All apps → SiSantri → Don't optimize
   
2. Settings → Device care → Battery → Background usage limits
   → Never sleeping apps → Add SiSantri
   
3. Settings → Notifications → Advanced settings → Manage notifications
   → SiSantri → Allow all
```

**Xiaomi:**
```
1. Settings → Apps → Manage apps → SiSantri
   → Battery saver → No restrictions
   
2. Settings → Battery & performance → Manage apps battery usage
   → SiSantri → No restrictions
   
3. Security → Permissions → Autostart → Enable for SiSantri
```

**Huawei:**
```
1. Settings → Apps → Apps → SiSantri
   → Battery → Launch manually: ON
   → Auto-launch: ON
   → Run in background: ON
```

**Oppo/Realme:**
```
1. Settings → Apps → App management → SiSantri
   → Battery usage → Don't optimize
   
2. Settings → Battery → Smart power saving → OFF
   
3. Settings → Privacy → Startup manager → SiSantri: ON
```

### Issue 5: Notification Delayed (Not Exact Time)
**Symptom:** 
- Test 10 detik tapi muncul setelah 15-20 detik
- Log shows "exactAllowWhileIdle"

**Root Cause:** Android still batching notifications despite exact alarm.

**Solution:**
```
This is normal behavior untuk short intervals (<60 seconds).
Android may batch notifications to save battery.

Workarounds:
1. Keep app in foreground saat testing
2. Keep screen on
3. Plug charger
4. Test dengan interval >60 detik (more reliable)

For production (prayer reminders):
- 5-30 menit delay is acceptable
- Android will respect timing lebih baik untuk longer intervals
```

### Issue 6: Works After Re-install, Then Stops
**Symptom:** 
- Fresh install: Works perfect
- After few hours/days: Stops working
- No code changes

**Root Cause:** Android learning patterns and optimizing app.

**Solution:**
```
1. Prevent Android from learning:
   Settings → Apps → SiSantri → Battery
   → Background restriction → Unrestricted
   
2. Add to protected apps:
   - Samsung: Never sleeping apps
   - Xiaomi: Protected apps
   - Other: Similar feature
   
3. Keep app active:
   - Open app at least once per day
   - App usage prevents Android from hibernating it
```

---

## 📱 Testing Checklist

- [ ] Permission status ditampilkan di UI
- [ ] Permission "Exact Alarm" enabled
- [ ] Battery optimization disabled
- [ ] Do Not Disturb disabled
- [ ] Test instant notification → muncul <1 detik
- [ ] Test 10 detik → muncul tepat 10 detik
- [ ] Test 30 detik → muncul tepat 30 detik
- [ ] Test 1 menit → muncul tepat 60 detik
- [ ] Pending notifications list updated setelah schedule
- [ ] Log menunjukkan `Can use exact: true`
- [ ] Log menunjukkan `Schedule mode: exactAllowWhileIdle`
- [ ] Cancel button berhasil cancel scheduled notification

---

## 🎯 Expected vs Actual

### Expected Behavior:
```
1. Tap "Test 10 detik"
2. Snackbar muncul: "✅ Reminder dijadwalkan..."
3. Pending list updated (ada ID 998)
4. Tunggu 10 detik
5. Notifikasi muncul TEPAT di detik ke-10
```

### Actual Behavior (Before Fix):
```
1. Tap "Test 10 detik"
2. Snackbar muncul: "✅ Reminder dijadwalkan..."
3. Pending list updated (ada ID 998)
4. Tunggu 10 detik
5. ❌ Notifikasi TIDAK muncul (Permission issue)
```

### Actual Behavior (After Fix):
```
1. Tap "Test 10 detik"
2. Snackbar muncul: "✅ Reminder dijadwalkan..."
3. Pending list updated (ada ID 998)
4. Log: "Can use exact: true"
5. Tunggu 10 detik
6. ✅ Notifikasi muncul TEPAT di detik ke-10
```

---

## 🛠️ Quick Fixes

### Reset Everything:
```dart
// Di test page, tambahkan button:
await ReminderService.cancelTestNotifications();
await ReminderService.requestExactAlarmPermission();
await _loadPendingNotifications();
```

### Force Re-schedule:
```dart
// Cancel dulu, baru schedule lagi
await ReminderService.cancelTestNotifications();
await Future.delayed(Duration(milliseconds: 500));
await ReminderService.scheduleTestNotification(secondsFromNow: 10);
```

---

## 📝 Notes

1. **Android 12+**: Exact alarm permission WAJIB
2. **Delay Tolerance**: ±2 detik masih normal untuk production
3. **Battery Saver**: Bisa delay sampai 15 menit jika enabled
4. **Doze Mode**: Android bisa delay notification jika device idle
5. **App in Background**: Harusnya tetap muncul (menggunakan `exactAllowWhileIdle`)
6. **Short Intervals**: 10-30 detik unreliable untuk production, gunakan ≥60 detik
7. **Testing Best Practice**: Keep screen ON dan charger plugged saat testing

---

## ✅ Testing Checklist (MUST DO SEBELUM LAPOR BUG)

Lakukan semua langkah ini sebelum melaporkan issue:

### Pre-Test Setup:
- [ ] App fully restarted (bukan hot reload)
- [ ] Screen brightness >50% (prevent sleep)
- [ ] Charger plugged in
- [ ] Battery saver OFF
- [ ] Do Not Disturb OFF
- [ ] Airplane mode OFF

### Permission Check:
- [ ] Settings → Apps → SiSantri → Notifications → ON
- [ ] Settings → Apps → SiSantri → Alarms & reminders → ON
- [ ] Settings → Apps → SiSantri → Battery → Don't optimize
- [ ] Exact alarm permission granted (check in app)

### Debug Steps:
- [ ] Tap 🐛 icon → Check debug info
- [ ] Verify "Exact alarm permission: true"
- [ ] Verify timezone correct
- [ ] Test instant notification → Must work!
- [ ] Schedule test 10 detik
- [ ] Check console log untuk "Found in pending list: true"
- [ ] Wait 10 detik (count mentally or use timer)
- [ ] Check notification bar

### If Failed:
- [ ] Check pending list → ID 998 still there?
- [ ] Try cancel → reschedule
- [ ] Try longer interval (60 detik)
- [ ] Clear app data → re-install
- [ ] Test on different device (if available)
- [ ] Report with FULL console log

---

## 🚀 Next Steps untuk User

**Sekarang silakan:**

1. **Restart app completely** (stop dan run ulang, bukan hot reload/restart)

2. **Buka test page** → Tap 🐛 icon → Screenshot debug info

3. **Test instant** → Tap "Kirim Test Instant":
   - ✅ Muncul → Lanjut step 4
   - ❌ Tidak muncul → Report "instant test failed"

4. **Test scheduled** → Tap "Test 10 detik":
   - Check console immediately
   - Screenshot console log
   - Wait EXACTLY 10 detik
   - Check notification bar

5. **Report hasil:**
   ```
   ✅ Instant test: [WORKS/FAILED]
   ✅ Scheduled test: [WORKS/FAILED]
   ✅ Found in pending: [YES/NO]
   ✅ Console log: [PASTE ATAU SCREENSHOT]
   ✅ Device model: [e.g. Samsung A52, Xiaomi Redmi Note 10]
   ✅ Android version: [e.g. Android 12, MIUI 13]
   ```

---

**Status:** 🔧 ENHANCED WITH FULL DEBUGGING  
**Version:** 2.0  
**Date:** 14 Desember 2025  
**Updates:** 
- Full plugin initialization
- Enhanced notification channels (Importance.max)
- Auto-cancel previous test
- Debug info method (🐛 button)
- Comprehensive troubleshooting by device brand
- Testing checklist
