# 🧪 Panduan Testing Sistem Reminder

## 📋 Overview

Dokumen ini berisi panduan lengkap untuk testing sistem reminder (pengingat sholat dan jadwal) di aplikasi SiSantri.

---

## 🎯 Tujuan Testing

1. ✅ Memastikan notifikasi instant berfungsi
2. ✅ Memastikan scheduled reminder berfungsi
3. ✅ Memastikan pengingat sholat muncul tepat waktu
4. ✅ Memastikan pengingat jadwal muncul sesuai schedule

---

## 🚀 Cara Akses Halaman Testing

### Method 1: Via Pengaturan Pengingat (Recommended)

```
1. Login sebagai Santri
2. Buka Profil
3. Tap "Pengaturan Pengingat"
4. Tap icon 🧪 (Test) di AppBar
5. Masuk ke halaman "Test Reminder System"
```

### Method 2: Direct Navigation (Development)

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReminderTestPage(),
  ),
);
```

---

## 📱 Fitur Testing yang Tersedia

### 1. **Test Notifikasi Instant** 🟢

**Fungsi:** Mengirim notifikasi langsung (muncul sekarang juga)

**Cara Test:**

1. Tap tombol "Kirim Test Instant"
2. Notifikasi akan muncul SEGERA di notification bar
3. Cek apakah notifikasi muncul dengan:
   - ✅ Title: "🔔 Test Notifikasi Instant"
   - ✅ Body: "Jika kamu melihat ini, notifikasi instant berhasil! ✅"

**Expected Result:**

- Notifikasi muncul dalam <1 detik
- Ada suara notifikasi (jika tidak di-silent)
- Ada getaran (jika enabled)

---

### 2. **Test Scheduled Reminder** 🟠

#### Option A: Test 10 Detik

**Fungsi:** Schedule notifikasi untuk muncul 10 detik dari sekarang

**Cara Test:**

1. Tap tombol "Test 10 detik"
2. Lihat snackbar konfirmasi "✅ Reminder dijadwalkan..."
3. Tunggu tepat 10 detik
4. Notifikasi akan muncul

**Expected Result:**

- Notifikasi muncul TEPAT setelah 10 detik
- Title: "⏰ Test Reminder 10 detik"
- Body: "Reminder yang dijadwalkan 10 detik berhasil muncul! ✅"

#### Option B: Test 30 Detik

**Fungsi:** Schedule notifikasi untuk muncul 30 detik dari sekarang

**Cara Test:**

1. Tap tombol "Test 30 detik"
2. Tunggu tepat 30 detik
3. Notifikasi akan muncul

#### Option C: Test 1 Menit

**Fungsi:** Schedule notifikasi untuk muncul 1 menit dari sekarang

**Cara Test:**

1. Tap tombol "Test 1 menit"
2. Tunggu tepat 60 detik
3. Notifikasi akan muncul

---

### 3. **Pending Notifications** 🟣

**Fungsi:** Menampilkan daftar notifikasi yang sudah dijadwalkan

**Informasi yang Ditampilkan:**

- ID notifikasi
- Title notifikasi
- Body notifikasi
- Jumlah total pending notifications

**Cara Lihat:**

1. Scroll ke section "Pending Notifications"
2. Lihat list notifikasi yang sudah dijadwalkan
3. Tap icon 🔄 untuk refresh list

**Expected Result:**

- Setelah schedule test, akan muncul di pending list
- Setelah notifikasi muncul, akan hilang dari pending list

---

## 🕌 Testing Pengingat Sholat Real

### Setup

1. Buka "Pengaturan Pengingat"
2. Enable "Aktifkan Pengingat Sholat"
3. Set waktu: **5 menit** sebelumnya (untuk testing cepat)
4. Save settings

### Cara Test (Method 1: Mengubah Waktu Sholat)

**Edit file `prayer_times_service.dart`:**

```dart
// Ubah waktu sholat ke 2-3 menit dari sekarang
static Map<String, DateTime> getTodayPrayerTimes() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Set waktu test: 3 menit dari sekarang
  final testTime = now.add(Duration(minutes: 3));

  return {
    'Subuh': DateTime(today.year, today.month, today.day, testTime.hour, testTime.minute),
    // ... dst
  };
}
```

**Langkah Testing:**

1. Ubah kode seperti di atas
2. Hot restart app
3. Buka "Pengaturan Pengingat"
4. Tap icon 🔄 (Refresh)
5. Tunggu (3 menit - 5 menit reminder) = tunggu sampai 2 menit sebelum waktu sholat
6. Notifikasi reminder akan muncul 5 menit sebelum waktu sholat
7. Notifikasi waktu sholat akan muncul tepat di waktu sholat

### Cara Test (Method 2: Gunakan API Berikutnya)

**Untuk production**, gunakan API waktu sholat real seperti:

- Aladhan API: https://aladhan.com/prayer-times-api
- Islamic Finder API: https://www.islamicfinder.org/

---

## 📅 Testing Pengingat Jadwal Real

### Prerequisite

- Harus ada jadwal di Firestore collection `jadwal`
- Jadwal harus untuk hari ini atau besok
- Jadwal harus aktif (`isAktif: true`)

### Setup

1. Tambah jadwal test di Firestore:

```json
{
  "namaKegiatan": "Test Kajian",
  "tanggal": "2025-12-14T15:00:00.000Z", // 3 jam dari sekarang
  "waktuMulai": "15:00",
  "lokasi": "Masjid",
  "isAktif": true
}
```

2. Enable pengingat jadwal:
   - Buka "Pengaturan Pengingat"
   - Enable "Aktifkan Pengingat Jadwal"
   - Set: **15 menit** sebelumnya

### Expected Result

- Reminder akan muncul 15 menit sebelum jadwal
- Notifikasi akan muncul tepat di waktu jadwal

---

## 🔧 Troubleshooting

### ❌ Problem: Notifikasi tidak muncul

**Possible Causes:**

1. **Permission tidak diberikan**

   - Solution: Check Settings → Apps → SiSantri → Notifications (Enable)

2. **Exact Alarm Permission (Android 12+)**

   - Error: `exact_alarm_not_permitted`
   - Solution: Settings → Apps → SiSantri → Alarms & reminders (Enable)
   - Note: App akan auto-request permission saat pertama kali dibuka

3. **Battery optimization mengblock**

   - Solution: Settings → Battery → Battery optimization → SiSantri → Don't optimize

4. **Do Not Disturb aktif**

   - Solution: Disable DND atau whitelist SiSantri

5. **Timezone salah**

   - Solution: Check `ReminderService.initialize()` dipanggil di `main()`

6. **Channel tidak dibuat**
   - Solution: Re-install app atau clear data

### ❌ Problem: Notifikasi terlambat/tidak tepat waktu

**Possible Causes:**

1. **Android Doze mode**

   - Solution: Gunakan `AndroidScheduleMode.exactAllowWhileIdle`
   - Already implemented ✅

2. **Device delay**
   - Solution: Normal, bisa delay 1-2 detik

### ❌ Problem: Notifikasi muncul di test tapi tidak muncul di real

**Possible Causes:**

1. **Jadwal sudah lewat**
   - Solution: Schedule hanya untuk hari ini dan besok
2. **Data aggregates belum ada**
   - Solution: Jalankan migration script

---

## ✅ Checklist Testing

### Basic Testing

- [ ] Test Instant Notification muncul
- [ ] Test 10 detik muncul tepat waktu
- [ ] Test 30 detik muncul tepat waktu
- [ ] Pending notifications ditampilkan dengan benar
- [ ] Refresh pending notifications bekerja

### Prayer Reminder Testing

- [ ] Enable/disable prayer reminder bekerja
- [ ] Setting waktu reminder (5/10/15/30 menit) bekerja
- [ ] Notifikasi muncul sesuai waktu yang diset
- [ ] Notifikasi muncul untuk semua 5 waktu sholat
- [ ] Sound dan vibration bekerja

### Schedule Reminder Testing

- [ ] Enable/disable schedule reminder bekerja
- [ ] Setting waktu reminder (5/10/15/30/60 menit) bekerja
- [ ] Notifikasi muncul untuk jadwal hari ini
- [ ] Notifikasi muncul untuk jadwal besok
- [ ] Refresh setelah update jadwal bekerja

### Edge Cases

- [ ] App closed → notifikasi tetap muncul ✅
- [ ] App background → notifikasi muncul ✅
- [ ] Device restart → schedule ulang di app start
- [ ] Midnight → auto refresh bekerja
- [ ] App resume setelah lama → refresh bekerja

---

## 📊 Expected Results Summary

| Test Case         | Expected Time | Expected Result               |
| ----------------- | ------------- | ----------------------------- |
| Instant Test      | < 1 second    | Muncul segera                 |
| 10 Detik Test     | Exactly 10s   | Muncul tepat 10s              |
| 30 Detik Test     | Exactly 30s   | Muncul tepat 30s              |
| 1 Menit Test      | Exactly 60s   | Muncul tepat 60s              |
| Prayer Reminder   | X min before  | Muncul X menit sebelum sholat |
| Prayer Time       | Exact time    | Muncul tepat waktu sholat     |
| Schedule Reminder | X min before  | Muncul X menit sebelum jadwal |
| Schedule Time     | Exact time    | Muncul tepat waktu jadwal     |

---

## 🎯 Success Criteria

✅ **PASSED** jika:

1. Instant notification muncul dalam <1 detik
2. Scheduled notification muncul tepat waktu (±2 detik tolerance)
3. Prayer reminders muncul untuk semua 5 waktu sholat
4. Schedule reminders muncul untuk semua jadwal aktif
5. Pending notifications list akurat
6. Sound dan vibration bekerja
7. Notifikasi muncul bahkan saat app closed

❌ **FAILED** jika:

1. Notifikasi tidak muncul sama sekali
2. Notifikasi terlambat >5 detik
3. Notifikasi muncul tapi tanpa sound/vibration
4. Pending list tidak akurat
5. Notifikasi tidak muncul saat app closed

---

## 📝 Notes

- **Battery Optimization:** Pastikan disable untuk akurasi maksimal
- **Timezone:** System akan auto-detect, fallback ke Asia/Jakarta
- **Permissions:** Android 13+ perlu explicit notification permission
- **Testing Window:** Best time untuk test: pagi atau sore (untuk prayer testing)

---

## 🚀 Quick Test Command

```dart
// Untuk developer: Panggil di console/debug
await ReminderService.sendTestNotification();
await ReminderService.scheduleTestNotification(secondsFromNow: 10);
final pending = await ReminderService.getPendingNotifications();
print('Pending: ${pending.length}');
```

---

**Version:** 1.0  
**Last Updated:** 14 Desember 2025  
**Tested On:** Android (Flutter 3.8.1+)
