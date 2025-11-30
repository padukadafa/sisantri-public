# Presensi Aggregate System Documentation

## Overview

Sistem agregasi presensi dirancang untuk mengurangi pembacaan dokumen Firestore dengan menyimpan data statistik presensi dalam dokumen agregasi terpisah. Data diagregasi secara real-time setiap kali ada perubahan presensi.

## Struktur Data

### Collection: `presensi_aggregates`

Setiap dokumen menyimpan agregasi untuk satu user dalam satu periode tertentu.

**Document ID Format**: `{userId}_{periode}_{periodeKey}`

- Contoh: `user123_monthly_2025-11`
- Contoh: `user456_weekly_2025-W48`

**Fields**:

```dart
{
  "id": "user123_monthly_2025-11",
  "userId": "user123",
  "periode": "monthly", // 'daily', 'weekly', 'monthly', 'semester', 'yearly'
  "periodeKey": "2025-11", // Format tergantung periode
  "totalHadir": 15,
  "totalIzin": 2,
  "totalSakit": 1,
  "totalAlpha": 0,
  "totalPoin": 150,
  "startDate": Timestamp(2025-11-01),
  "endDate": Timestamp(2025-11-30),
  "lastUpdated": Timestamp(2025-11-29),
  "detailPerJadwal": { // Optional
    "jadwal_001": 10,
    "jadwal_002": 5
  }
}
```

## Periode Key Format

| Periode  | Format     | Contoh     | Deskripsi                           |
| -------- | ---------- | ---------- | ----------------------------------- |
| daily    | YYYY-MM-DD | 2025-11-29 | Harian                              |
| weekly   | YYYY-Www   | 2025-W48   | Mingguan (ISO week)                 |
| monthly  | YYYY-MM    | 2025-11    | Bulanan                             |
| semester | YYYY-S1/S2 | 2025-S2    | Semester (S1: Jan-Jun, S2: Jul-Des) |
| yearly   | YYYY       | 2025       | Tahunan                             |

## Firestore Indexes Required

Tambahkan indexes berikut di Firebase Console atau `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "presensi_aggregates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "periode", "order": "ASCENDING" },
        { "fieldPath": "periodeKey", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "presensi_aggregates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "periode", "order": "ASCENDING" },
        { "fieldPath": "periodeKey", "order": "ASCENDING" },
        { "fieldPath": "totalPoin", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "presensi_aggregates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "periode", "order": "ASCENDING" },
        { "fieldPath": "periodeKey", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Presensi Aggregates
    match /presensi_aggregates/{aggregateId} {
      // Allow read for authenticated users
      allow read: if request.auth != null;

      // Allow write only for admin or system (via cloud functions)
      allow write: if request.auth != null &&
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
         request.auth.token.admin == true);
    }
  }
}
```

## Usage Examples

### 1. Get Aggregate Summary (Dashboard)

```dart
// Get all periode summaries for a user
final summary = await PresensiAggregateService.getAggregateSummary(
  userId: 'user123',
);

// Access specific periode
final monthlyAggregate = summary['monthly'];
if (monthlyAggregate != null) {
  print('Total Hadir: ${monthlyAggregate.totalHadir}');
  print('Total Poin: ${monthlyAggregate.totalPoin}');
  print('Persentase: ${monthlyAggregate.persentaseKehadiran}%');
}
```

### 2. Get Specific Aggregate

```dart
// Get monthly aggregate for November 2025
final aggregate = await PresensiAggregateService.getAggregate(
  userId: 'user123',
  periode: 'monthly',
  date: DateTime(2025, 11, 29),
);
```

### 3. Get Multiple Aggregates (History)

```dart
// Get all monthly aggregates for 2025
final aggregates = await PresensiAggregateService.getAggregates(
  userId: 'user123',
  periode: 'monthly',
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 12, 31),
);

for (final agg in aggregates) {
  print('${agg.periodeKey}: ${agg.totalPoin} poin');
}
```

### 4. Real-time Stream

```dart
// Watch monthly aggregate in real-time
PresensiAggregateService.watchAggregate(
  userId: 'user123',
  periode: 'monthly',
  date: DateTime.now(),
).listen((aggregate) {
  if (aggregate != null) {
    print('Updated poin: ${aggregate.totalPoin}');
  }
});
```

### 5. Leaderboard (Fast Query)

```dart
// Get leaderboard for current month
final periodeKey = PeriodeKeyHelper.monthly(DateTime.now());
final leaderboard = await PresensiAggregateService.getLeaderboard(
  periode: 'monthly',
  periodeKey: periodeKey,
  limit: 10,
);

for (int i = 0; i < leaderboard.length; i++) {
  print('${i + 1}. User ${leaderboard[i]['userId']}: ${leaderboard[i]['totalPoin']} poin');
}
```

### 6. Statistics Dashboard (Admin)

```dart
// Get overall statistics for current month
final periodeKey = PeriodeKeyHelper.monthly(DateTime.now());
final stats = await PresensiAggregateService.getStatistics(
  periode: 'monthly',
  periodeKey: periodeKey,
);

print('Total Users: ${stats['totalUsers']}');
print('Total Hadir: ${stats['totalHadir']}');
print('Persentase Kehadiran: ${stats['persentaseKehadiran']}%');
```

## Widget Usage

### PresensiAggregateStatsWidget

Menampilkan statistik untuk satu periode:

```dart
PresensiAggregateStatsWidget(
  userId: currentUser.id,
  periode: 'monthly', // or 'daily', 'weekly', 'semester', 'yearly'
)
```

### PeriodeComparisonWidget

Menampilkan perbandingan semua periode:

```dart
PeriodeComparisonWidget(
  userId: currentUser.id,
)
```

## Migration Guide

### Rebuild Aggregates dari Data Existing

Jalankan fungsi rebuild untuk migrasi data:

```dart
// Rebuild untuk satu user
await PresensiAggregateService.rebuildAggregates(
  userId: 'user123',
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime.now(),
);

// Rebuild untuk semua user (jalankan di Cloud Function)
final users = await FirebaseFirestore.instance.collection('users').get();
for (final user in users.docs) {
  await PresensiAggregateService.rebuildAggregates(
    userId: user.id,
  );
}
```

### Cloud Function untuk Batch Rebuild

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.rebuildAllAggregates = functions.https.onCall(async (data, context) => {
  // Check admin role
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Admin only");
  }

  const usersSnapshot = await admin.firestore().collection("users").get();
  const batch = admin.firestore().batch();

  for (const userDoc of usersSnapshot.docs) {
    // Call Flutter service via HTTP or implement in JS
    // This is just a trigger, actual rebuild done in Flutter
  }

  return { success: true, totalUsers: usersSnapshot.size };
});
```

## Performance Benefits

### Before (Without Aggregates)

- Get user stats: Read **ALL** presensi documents (~500+ docs for active user)
- Leaderboard: Read **ALL** users × **ALL** presensi (~50k+ docs)
- Monthly report: Read **ALL** presensi for month (~10k+ docs)

### After (With Aggregates)

- Get user stats: Read **5 docs** (one per periode)
- Leaderboard: Read **~100 docs** (one aggregate per user)
- Monthly report: Read **1 doc** per user

**Result**: **99% reduction in document reads** = Lower costs + Faster queries

## Automatic Updates

Agregasi di-update otomatis ketika:

1. ✅ Presensi baru ditambahkan (`addPresensi`)
2. ✅ Presensi diupdate (`updatePresensi`)
3. ✅ Bulk attendance (admin)
4. ✅ RFID scan presensi

Tidak perlu manual trigger, semua terintegrasi di:

- `PresensiRemoteDataSource.addPresensi()`
- `PresensiRemoteDataSource.updatePresensi()`
- `ManualAttendancePage._bulkAttendance()`

## Monitoring & Maintenance

### Check Aggregate Health

```dart
// Count aggregates untuk user
final aggregates = await FirebaseFirestore.instance
  .collection('presensi_aggregates')
  .where('userId', isEqualTo: userId)
  .get();

print('Total aggregates: ${aggregates.size}');
// Should have ~5 docs per active month (daily, weekly, monthly, semester, yearly)
```

### Cleanup Old Aggregates

```dart
// Delete aggregates older than 2 years
final cutoffDate = DateTime.now().subtract(Duration(days: 730));
final oldAggregates = await FirebaseFirestore.instance
  .collection('presensi_aggregates')
  .where('endDate', isLessThan: Timestamp.fromDate(cutoffDate))
  .get();

final batch = FirebaseFirestore.instance.batch();
for (final doc in oldAggregates.docs) {
  batch.delete(doc.reference);
}
await batch.commit();
```

## Troubleshooting

### Aggregate data tidak sesuai

**Solution**: Rebuild aggregate untuk user tersebut

```dart
await PresensiAggregateService.rebuildAggregates(userId: 'problematic_user_id');
```

### Query timeout di leaderboard

**Solution**: Pastikan Firestore index sudah dibuat dan composite index untuk `periode + periodeKey + totalPoin` aktif

### Aggregate tidak update otomatis

**Solution**: Check apakah `PresensiAggregateService.updateAggregates()` dipanggil di semua tempat yang melakukan create/update presensi

## Best Practices

1. ✅ Selalu gunakan aggregate untuk menampilkan statistik
2. ✅ Gunakan Stream untuk real-time updates
3. ✅ Cache hasil aggregate di local state/provider
4. ✅ Rebuild aggregate jika data tidak konsisten
5. ✅ Set cleanup schedule untuk old aggregates
6. ⚠️ Jangan query collection `presensi` untuk statistik
7. ⚠️ Jangan manual update aggregate tanpa update presensi asli
