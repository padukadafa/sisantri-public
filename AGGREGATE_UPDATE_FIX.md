# Fix: Aggregate Tidak Terupdate

## Masalah yang Ditemukan

1. **Ketika presensi dilakukan**: Aggregate tidak terupdate
2. **Ketika jadwal baru dibuat**: Santri otomatis alpha tapi aggregate tidak terupdate

## Penyebab

Ada **3 tempat** di kode yang membuat/update presensi tapi **tidak memanggil `updateAggregates()`**:

### 1. ❌ `AttendanceService.generateDefaultAttendanceForJadwal`

Ketika jadwal baru dibuat, service ini membuat record presensi alpha untuk semua santri, tapi tidak update aggregate.

### 2. ❌ `FirestoreService.addPresensi`

Method legacy yang masih dipakai beberapa tempat, tidak update aggregate.

### 3. ❌ `ManualAttendancePage._recordAttendance`

Ketika admin catat presensi manual per santri, tidak update aggregate.

## Solusi yang Diterapkan

### ✅ File 1: `lib/shared/services/attendance_service.dart`

**Perubahan:**

1. Import `PresensiAggregateService`
2. Update `generateDefaultAttendanceForJadwal`:
   - Setelah batch commit presensi alpha
   - Loop semua santri dan panggil `updateAggregates()` dengan status alpha
3. Update `updateAttendanceStatus`:
   - Fetch data lama (oldStatus, oldPoin)
   - Setelah update status
   - Panggil `updateAggregates()` dengan old dan new data

```dart
// Setelah batch.commit()
for (final santri in santriNeedingRecords) {
  await PresensiAggregateService.updateAggregates(
    userId: santri.id,
    tanggal: tanggalJadwal,
    status: 'alpha',
    poin: 0,
  );
}
```

### ✅ File 2: `lib/shared/services/firestore_service.dart`

**Perubahan:**

1. Import `PresensiAggregateService`
2. Update `addPresensi`:
   - Setelah add presensi dan update poin user
   - Panggil `updateAggregates()`

```dart
await PresensiAggregateService.updateAggregates(
  userId: presensi.userId,
  tanggal: presensi.timestamp ?? DateTime.now(),
  status: presensi.status.name,
  poin: presensi.poin,
);
```

### ✅ File 3: `lib/features/admin/attendance_management/presentation/pages/manual_attendance_page.dart`

**Perubahan:**

1. Update `_recordAttendance`:
   - Simpan `oldPoin` saat fetch existing record
   - Setelah update/create presensi
   - Fetch jadwal data untuk dapat tanggal dan poin
   - Panggil `updateAggregates()` dengan parameter lengkap

```dart
// Setelah update/create presensi
final jadwalDoc = await firestore.collection('jadwal').doc(_selectedActivity).get();
final jadwalData = jadwalDoc.data();
final tanggalJadwal = (jadwalData?['tanggalMulai'] as Timestamp?)?.toDate() ?? DateTime.now();
final poin = jadwalData?['poin'] as int? ?? 1;
final newPoin = attendanceStatus == 'hadir' ? poin : 0;

await PresensiAggregateService.updateAggregates(
  userId: santri.id,
  tanggal: tanggalJadwal,
  status: attendanceStatus,
  poin: newPoin,
  oldStatus: oldStatus,
  oldPoin: oldPoin,
);
```

## Testing

Setelah fix ini, aggregate akan otomatis terupdate di 5 skenario:

### ✅ Skenario 1: Buat Jadwal Baru

1. Admin → Schedule Management → Add Jadwal
2. Semua santri aktif otomatis dapat record alpha
3. **Aggregate semua santri terupdate** dengan totalAlpha++

### ✅ Skenario 2: Presensi Manual Per Santri

1. Admin → Attendance Management → Manual Attendance
2. Pilih jadwal → Tap santri → Pilih status (Hadir/Izin/Sakit/Alpha)
3. **Aggregate santri tersebut terupdate** sesuai status

### ✅ Skenario 3: Bulk Attendance

1. Admin → Attendance Management → Manual Attendance
2. Select multiple santri → Bulk action
3. **Aggregate semua santri terpilih terupdate** (sudah fix sebelumnya)

### ✅ Skenario 4: Presensi via RFID

1. Santri scan RFID di perangkat
2. Status otomatis hadir
3. **Aggregate santri terupdate** via `PresensiRemoteDataSource.addPresensi` (sudah fix sebelumnya)

### ✅ Skenario 5: Update Status Presensi

1. Admin ubah status presensi yang sudah ada
2. `AttendanceService.updateAttendanceStatus` dipanggil
3. **Aggregate terupdate** dengan decrement old status, increment new status

## Verifikasi

Cek di **Firestore Console**:

- Collection: `presensi_aggregates`
- Setelah buat jadwal baru → harus muncul 5 dokumen per santri:
  - `{userId}_daily_{YYYY-MM-DD}`
  - `{userId}_weekly_{YYYY-Www}`
  - `{userId}_monthly_{YYYY-MM}`
  - `{userId}_semester_{YYYY-S1/S2}`
  - `{userId}_yearly_{YYYY}`
- Field `totalAlpha` harus increment

Cek di **App**:

- Dashboard santri → PeriodeComparisonWidget harus tampil data
- Profile santri → PresensiAggregateStatsWidget harus tampil stats bulan ini
- Admin Statistics → Charts harus tampil data
- Leaderboard → Ranking harus muncul

## Catatan Penting

⚠️ **Data lama tidak akan otomatis terupdate!**

- Fix ini hanya berlaku untuk presensi yang dibuat/diupdate setelah fix
- Untuk migrate data lama, jalankan: `flutter run scripts/migrate_aggregates.dart`

✅ **Semua alur presensi sudah covered**:

- ✅ Create jadwal → alpha default
- ✅ Manual attendance per santri
- ✅ Bulk attendance
- ✅ RFID attendance
- ✅ Update status existing
- ✅ Legacy FirestoreService.addPresensi

## Next Steps

1. **Test** di development:

   ```bash
   flutter run
   ```

2. **Buat jadwal baru** dan verifikasi aggregate muncul

3. **Catat presensi** (manual/RFID) dan verifikasi aggregate terupdate

4. **Cek UI** di Dashboard, Profile, Statistics, dan Leaderboard

5. Jika semua OK, **commit changes**:
   ```bash
   git add .
   git commit -m "fix: Update aggregates saat presensi dan buat jadwal baru"
   git push
   ```

## Summary

**3 files diubah** untuk memastikan aggregate selalu terupdate:

1. ✅ `attendance_service.dart` - Generate alpha + update status
2. ✅ `firestore_service.dart` - Legacy add presensi
3. ✅ `manual_attendance_page.dart` - Manual per santri

**Semua alur presensi kini memanggil `updateAggregates()`** ✨
