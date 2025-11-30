# 🔍 Troubleshooting: Aggregate Documents Tidak Terbuat

## Problem

Migration script berhasil running (exit code 0) tapi tidak ada dokumen aggregate yang terbuat di Firestore collection `presensi_aggregates`.

---

## ✅ Yang Sudah Berhasil

- ✅ Firestore indexes deployed
- ✅ Firestore rules deployed

---

## 🔍 Kemungkinan Penyebab

### 1️⃣ **Tidak Ada Data Presensi**

Migration script hanya membuat aggregates jika ada data presensi.

**Check di Firestore Console:**

- Buka Firestore → Collection `presensi`
- Apakah ada documents?
- Jika tidak ada → **Solusi:** Tambah presensi manual dulu

**Test Manual:**

1. Login sebagai admin/dewan_guru
2. Buka "Manual Attendance"
3. Tambah presensi untuk beberapa santri
4. Check di Firestore apakah document presensi terbuat

---

### 2️⃣ **Users Tidak Memiliki Role yang Benar**

Script hanya migrate users dengan role `'santri'` atau `'dewan_guru'` (string, bukan enum).

**Check di Firestore Console:**

- Buka Firestore → Collection `users`
- Check field `role` untuk setiap user
- Apakah nilai nya `"santri"` atau `"dewan_guru"`? (string)

**Kemungkinan Issue:**

- Role tersimpan sebagai enum (e.g., `UserRole.santri`)
- Role field tidak ada
- Role menggunakan capitalization berbeda (e.g., `"Santri"`)

**Solusi:**
Update role di Firestore Console atau fix migration script untuk match format role Anda.

---

### 3️⃣ **Migration Exit Sebelum Selesai**

Script running di emulator bisa exit sebelum selesai.

**Cara Check:**
Lihat log output dari migration - apakah sampai menunjukkan:

```
📊 MIGRATION SUMMARY
✅ Success: X users
```

**Jika tidak sampai ke summary:**

- Script terminated early
- Try running di device fisik atau Chrome (web)

---

### 4️⃣ **Security Rules Blocking Writes**

Meskipun rules sudah deployed, bisa jadi user yang running script bukan admin.

**Check:**

- User yang login saat running script harus role `'admin'`
- Rules hanya allow admin untuk write aggregates

**Test:**
Login dengan user admin, kemudian run migration.

---

## 🛠️ Quick Fix & Testing

### **Method 1: Debug Script**

Jalankan debug script untuk check data:

```bash
flutter run scripts/debug_firestore.dart
```

Script ini akan check:

- ✅ Apakah ada users?
- ✅ Berapa banyak users dengan role santri/dewan_guru?
- ✅ Apakah ada presensi data?
- ✅ Apakah ada aggregates yang sudah terbuat?

---

### **Method 2: Manual Test via App**

**Cara paling reliable - test auto-update aggregates:**

1. **Login sebagai admin** di app

2. **Tambah 1 presensi baru:**

   - Buka "Manual Attendance"
   - Pilih jadwal hari ini
   - Pilih 1 santri
   - Set status: Hadir
   - Save

3. **Check Firestore Console:**
   - Buka collection `presensi_aggregates`
   - Cari documents dengan pattern: `{userId}_daily_{YYYY-MM-DD}`
   - Jika ada → **Auto-update working!** ✅
   - Jika tidak → check console logs untuk errors

---

### **Method 3: Check Console Logs**

Saat running migration atau adding presensi, check console di VS Code:

**Look for:**

- ✅ "Found X users to migrate"
- ✅ "Processing: User Name (santri)"
- ✅ "Aggregates rebuilt successfully"
- ❌ Any error messages

---

## 🎯 Recommended Steps

**Langkah paling efektif:**

1. **Test auto-update dulu** (Method 2):

   - Lebih cepat
   - Lebih reliable
   - Test production flow

2. **Jika auto-update berhasil:**

   - Run migration untuk historical data
   - Atau biarkan - aggregates akan terbuat gradual saat users presensi

3. **Jika auto-update gagal:**
   - Check console errors
   - Check user role (harus admin)
   - Check presensi_remote_data_source integration

---

## 📊 Expected Results

**Setelah adding 1 presensi untuk 1 user, harus ada 5 documents di `presensi_aggregates`:**

```
Collection: presensi_aggregates

Documents:
1. {userId}_daily_2025-11-30
   - totalHadir: 1
   - totalPoin: X
   - periode: "daily"
   - periodeKey: "2025-11-30"

2. {userId}_weekly_2025-W48
   - totalHadir: 1
   - totalPoin: X
   - periode: "weekly"

3. {userId}_monthly_2025-11
   - totalHadir: 1
   - totalPoin: X
   - periode: "monthly"

4. {userId}_semester_2025-S2
   - totalHadir: 1
   - totalPoin: X
   - periode: "semester"

5. {userId}_yearly_2025
   - totalHadir: 1
   - totalPoin: X
   - periode: "yearly"
```

---

## 🆘 Still Not Working?

**If documents still not created:**

1. **Check integration in presensi_remote_data_source.dart:**

   ```dart
   // Setelah addPresensi, pastikan ada:
   await PresensiAggregateService.updateAggregates(
     userId: presensi.userId,
     newTotalHadir: status == StatusPresensi.hadir ? 1 : 0,
     newTotalIzin: status == StatusPresensi.izin ? 1 : 0,
     // ...
   );
   ```

2. **Check console untuk errors:**

   - Permission denied → Check user role
   - Missing index → Wait for indexes to finish building
   - Other errors → Share error message

3. **Test dengan Firestore Console:**
   - Manually create 1 aggregate document
   - Verify structure matches PresensiAggregateModel
   - Test if reads work

---

## ✨ Once Working

Setelah confirm auto-update working:

1. **Historical data migration optional:**

   - Aggregates akan terbuat gradual
   - Atau run full migration saat low-traffic

2. **Monitor:**
   - Check aggregates collection growing
   - Verify leaderboard showing data
   - Test statistics dashboard

---

**Need more help?** Run debug script dan share output! 🔍
