# 📊 Database Schema - SiSantri

Dokumentasi lengkap struktur database Firebase Firestore untuk aplikasi SiSantri.

## 📑 Daftar Isi

1. [Users](#1-users)
2. [Jadwal (Unified Schedule)](#2-jadwal-unified-schedule)
3. [Presensi](#3-presensi)
4. [Presensi Aggregates](#4-presensi_aggregates)
5. [Pengumuman](#5-pengumuman)
6. [Materi](#6-materi)
7. [Progress Santri](#7-progress_santri)
8. [Sesi Kajian](#8-sesi_kajian)
9. [RFID Cards](#9-rfid_cards)
10. [RFID Scan Requests](#10-rfid_scan_requests)
11. [Activities](#11-activities)

---

## 1. Users

**Collection:** `users`

Menyimpan data pengguna sistem (Admin, Dewan Guru, Santri).

| Field                 | Type      | Required | Description                                    | Default             |
| --------------------- | --------- | -------- | ---------------------------------------------- | ------------------- |
| `id`                  | string    | ✅       | Document ID (auto)                             | -                   |
| `nama`                | string    | ✅       | Nama lengkap pengguna                          | -                   |
| `email`               | string    | ✅       | Email pengguna (unique)                        | -                   |
| `nim`                 | string    | ❌       | NIM santri                                     | -                   |
| `fakultas`            | string    | ❌       | Fakultas santri                                | -                   |
| `role`                | string    | ✅       | Role pengguna: `admin`, `dewan_guru`, `santri` | `santri`            |
| `statusAktif`         | boolean   | ✅       | Status aktif pengguna                          | `true`              |
| `poin`                | number    | ✅       | Total poin yang dikumpulkan                    | `0`                 |
| `totalKehadiran`      | number    | ✅       | Total kehadiran                                | `0`                 |
| `streakHarian`        | number    | ❌       | Streak kehadiran berturut-turut                | `0`                 |
| `maxStreak`           | number    | ❌       | Streak maksimal yang pernah dicapai            | `0`                 |
| `rfidCardId`          | string    | ❌       | ID kartu RFID santri                           | -                   |
| `fotoProfil`          | string    | ❌       | URL foto profil (Firebase Storage)             | -                   |
| `notificationEnabled` | boolean   | ❌       | Status notifikasi                              | `true`              |
| `language`            | string    | ❌       | Bahasa: `id`, `en`                             | `id`                |
| `level`               | number    | ❌       | Level gamifikasi                               | `1`                 |
| `exp`                 | number    | ❌       | Experience points                              | `0`                 |
| `tanggalDaftar`       | timestamp | ✅       | Tanggal pendaftaran                            | `serverTimestamp()` |
| `createdAt`           | timestamp | ✅       | Waktu pembuatan                                | `serverTimestamp()` |
| `updatedAt`           | timestamp | ✅       | Waktu update terakhir                          | `serverTimestamp()` |

**Indexes:**

- `role` (Ascending)
- `statusAktif` (Ascending)
- `poin` (Descending)
- `rfidCardId` (Ascending)

**Role Values:**

- `admin` - Administrator sistem
- `dewan_guru` - Dewan guru/ustadz
- `santri` - Santri pondok pesantren

---

## 2. Jadwal (Unified Schedule)

**Collection:** `jadwal`

Jadwal terpadu untuk semua kegiatan pondok pesantren.

| Field                  | Type      | Required | Description                                               | Default             |
| ---------------------- | --------- | -------- | --------------------------------------------------------- | ------------------- |
| `id`                   | string    | ✅       | Document ID (auto)                                        | -                   |
| `namaKegiatan`         | string    | ✅       | Nama kegiatan                                             | -                   |
| `jenisKegiatan`        | string    | ✅       | Jenis: `kajian`, `kegiatan_umum`, `ujian`, `khusus`       | -                   |
| `tanggal`              | timestamp | ✅       | Tanggal kegiatan                                          | -                   |
| `waktuMulai`           | string    | ✅       | Waktu mulai (HH:mm)                                       | -                   |
| `waktuSelesai`         | string    | ✅       | Waktu selesai (HH:mm)                                     | -                   |
| `lokasi`               | string    | ✅       | Lokasi kegiatan                                           | -                   |
| `deskripsi`            | string    | ❌       | Deskripsi kegiatan                                        | -                   |
| `tema`                 | string    | ❌       | Tema kajian (khusus kajian)                               | -                   |
| `pemateri`             | string    | ❌       | Pemateri (khusus kajian)                                  | -                   |
| `kategori`             | string    | ❌       | Kategori: `umum`, `khusus`, `wajib`                       | `umum`              |
| `targetPeserta`        | array     | ❌       | Target peserta: `['santri']`, `['dewan_guru']`, `['all']` | `['all']`           |
| `maxPeserta`           | number    | ❌       | Maksimal peserta (0 = unlimited)                          | `0`                 |
| `jumlahPeserta`        | number    | ❌       | Jumlah peserta terdaftar                                  | `0`                 |
| `requiresPresensi`     | boolean   | ✅       | Apakah memerlukan presensi                                | `true`              |
| `requiresRegistration` | boolean   | ✅       | Apakah memerlukan registrasi                              | `false`             |
| `isAktif`              | boolean   | ✅       | Status aktif jadwal                                       | `true`              |
| `isPublished`          | boolean   | ✅       | Status publish                                            | `true`              |
| `poinKehadiran`        | number    | ❌       | Poin untuk kehadiran                                      | `10`                |
| `reminderSent`         | boolean   | ❌       | Status reminder sudah dikirim                             | `false`             |
| `createdBy`            | string    | ✅       | User ID pembuat                                           | -                   |
| `createdByName`        | string    | ❌       | Nama pembuat                                              | -                   |
| `createdAt`            | timestamp | ✅       | Waktu pembuatan                                           | `serverTimestamp()` |
| `updatedAt`            | timestamp | ✅       | Waktu update                                              | `serverTimestamp()` |

**Indexes:**

- `tanggal` (Ascending)
- `isAktif` (Ascending)
- `jenisKegiatan` (Ascending)
- Composite: `isAktif` + `tanggal`

**Jenis Kegiatan:**

- `kajian` - Kajian/pengajian rutin
- `kegiatan_umum` - Kegiatan umum pondok
- `ujian` - Ujian/evaluasi
- `khusus` - Kegiatan khusus

---

## 3. Presensi

**Collection:** `presensi`

Data presensi santri untuk setiap jadwal kegiatan.

| Field            | Type      | Required | Description                                            | Default             |
| ---------------- | --------- | -------- | ------------------------------------------------------ | ------------------- |
| `id`             | string    | ✅       | Document ID (auto)                                     | -                   |
| `userId`         | string    | ✅       | User ID santri                                         | -                   |
| `userName`       | string    | ✅       | Nama santri                                            | -                   |
| `jadwalId`       | string    | ✅       | ID jadwal kegiatan                                     | -                   |
| `jadwalNama`     | string    | ❌       | Nama kegiatan                                          | -                   |
| `tanggal`        | timestamp | ✅       | Tanggal presensi                                       | -                   |
| `waktuPresensi`  | timestamp | ❌       | Waktu presensi dilakukan                               | -                   |
| `status`         | string    | ✅       | Status: `hadir`, `izin`, `sakit`, `alpha`, `terlambat` | `alpha`             |
| `keterangan`     | string    | ❌       | Keterangan tambahan                                    | -                   |
| `poin`           | number    | ✅       | Poin yang diperoleh                                    | `0`                 |
| `poinDiperoleh`  | number    | ✅       | Alias untuk poin                                       | `0`                 |
| `method`         | string    | ❌       | Metode presensi: `rfid`, `manual`, `app`               | `manual`            |
| `rfidUid`        | string    | ❌       | UID kartu RFID (jika metode RFID)                      | -                   |
| `deviceId`       | string    | ❌       | ID device RFID reader                                  | -                   |
| `deviceLocation` | string    | ❌       | Lokasi device                                          | -                   |
| `isManualEntry`  | boolean   | ✅       | Apakah input manual                                    | `false`             |
| `manualEntryBy`  | string    | ❌       | User ID yang input manual                              | -                   |
| `isBonus`        | boolean   | ❌       | Apakah mendapat bonus poin                             | `false`             |
| `bonusReason`    | string    | ❌       | Alasan bonus: `streak_weekly`, `perfect_month`         | -                   |
| `photoUrl`       | string    | ❌       | URL foto presensi                                      | -                   |
| `latitude`       | number    | ❌       | Koordinat latitude                                     | -                   |
| `longitude`      | number    | ❌       | Koordinat longitude                                    | -                   |
| `createdAt`      | timestamp | ✅       | Waktu pembuatan                                        | `serverTimestamp()` |
| `updatedAt`      | timestamp | ❌       | Waktu update                                           | `serverTimestamp()` |

**Indexes:**

- `userId` (Ascending)
- `jadwalId` (Ascending)
- `tanggal` (Descending)
- `status` (Ascending)
- Composite: `userId` + `tanggal`
- Composite: `userId` + `jadwalId`

**Status Values:**

- `hadir` - Hadir tepat waktu (poin: 10)
- `terlambat` - Hadir terlambat (poin: 5)
- `izin` - Izin dengan keterangan (poin: 5)
- `sakit` - Sakit dengan keterangan (poin: 5)
- `alpha` - Tidak hadir tanpa keterangan (poin: 0)

---

## 4. Presensi_Aggregates

**Collection:** `presensi_aggregates`

Data agregasi presensi untuk performa query yang lebih baik.

| Field                 | Type      | Required | Description                                                 | Default             |
| --------------------- | --------- | -------- | ----------------------------------------------------------- | ------------------- |
| `id`                  | string    | ✅       | Document ID (auto/generated)                                | -                   |
| `userId`              | string    | ✅       | User ID santri                                              | -                   |
| `periode`             | string    | ✅       | Periode: `daily`, `weekly`, `monthly`, `semester`, `yearly` | -                   |
| `periodeKey`          | string    | ✅       | Key periode (YYYY-MM-DD, YYYY-Www, dll)                     | -                   |
| `totalHadir`          | number    | ✅       | Total hadir                                                 | `0`                 |
| `totalTerlambat`      | number    | ✅       | Total terlambat                                             | `0`                 |
| `totalIzin`           | number    | ✅       | Total izin                                                  | `0`                 |
| `totalSakit`          | number    | ✅       | Total sakit                                                 | `0`                 |
| `totalAlpha`          | number    | ✅       | Total alpha                                                 | `0`                 |
| `totalPoin`           | number    | ✅       | Total poin periode ini                                      | `0`                 |
| `startDate`           | timestamp | ✅       | Tanggal mulai periode                                       | -                   |
| `endDate`             | timestamp | ✅       | Tanggal akhir periode                                       | -                   |
| `persentaseKehadiran` | number    | ❌       | Persentase kehadiran (%)                                    | `0`                 |
| `detailPerJadwal`     | map       | ❌       | Breakdown per jadwal                                        | `{}`                |
| `lastUpdated`         | timestamp | ✅       | Waktu update terakhir                                       | `serverTimestamp()` |

**Document ID Format:**

- Daily: `{userId}_daily_{YYYY-MM-DD}`
- Weekly: `{userId}_weekly_{YYYY-Www}`
- Monthly: `{userId}_monthly_{YYYY-MM}`
- Semester: `{userId}_semester_{YYYY-S1/S2}`
- Yearly: `{userId}_yearly_{YYYY}`

**Indexes:**

- `userId` (Ascending)
- `periode` (Ascending)
- `periodeKey` (Ascending)
- Composite: `userId` + `periode` + `periodeKey`

---

## 5. Pengumuman

**Collection:** `pengumuman`

Data pengumuman untuk santri dan admin.

| Field            | Type      | Required | Description                                                    | Default             |
| ---------------- | --------- | -------- | -------------------------------------------------------------- | ------------------- |
| `id`             | string    | ✅       | Document ID (auto)                                             | -                   |
| `judul`          | string    | ✅       | Judul pengumuman                                               | -                   |
| `isi`            | string    | ✅       | Isi pengumuman (support markdown)                              | -                   |
| `kategori`       | string    | ✅       | Kategori: `umum`, `akademik`, `keuangan`, `kegiatan`           | `umum`              |
| `isPenting`      | boolean   | ✅       | Apakah pengumuman penting                                      | `false`             |
| `priority`       | number    | ❌       | Prioritas tampilan (1-5)                                       | `3`                 |
| `targetAudience` | array     | ✅       | Target: `['all']`, `['santri']`, `['dewan_guru']`, `['admin']` | `['all']`           |
| `gambarUrl`      | array     | ❌       | Array URL gambar                                               | `[]`                |
| `attachmentUrl`  | array     | ❌       | Array URL attachment                                           | `[]`                |
| `tags`           | array     | ❌       | Tags untuk pencarian                                           | `[]`                |
| `viewCount`      | number    | ❌       | Jumlah views                                                   | `0`                 |
| `likeCount`      | number    | ❌       | Jumlah likes                                                   | `0`                 |
| `commentCount`   | number    | ❌       | Jumlah komentar                                                | `0`                 |
| `publishAt`      | timestamp | ❌       | Waktu publish (scheduled)                                      | -                   |
| `expireAt`       | timestamp | ❌       | Waktu kadaluarsa                                               | -                   |
| `isActive`       | boolean   | ✅       | Status aktif                                                   | `true`              |
| `isPublished`    | boolean   | ✅       | Status published                                               | `true`              |
| `createdBy`      | string    | ✅       | User ID pembuat                                                | -                   |
| `authorName`     | string    | ✅       | Nama pembuat                                                   | -                   |
| `authorRole`     | string    | ❌       | Role pembuat                                                   | -                   |
| `tanggal`        | timestamp | ✅       | Tanggal pengumuman                                             | `serverTimestamp()` |
| `createdAt`      | timestamp | ✅       | Waktu pembuatan                                                | `serverTimestamp()` |
| `updatedAt`      | timestamp | ✅       | Waktu update                                                   | `serverTimestamp()` |

**Indexes:**

- `tanggal` (Descending)
- `isActive` (Ascending)
- `isPenting` (Descending)
- `kategori` (Ascending)
- Composite: `isActive` + `tanggal`

---

## 6. Materi

**Collection:** `materi`

Data materi pembelajaran untuk santri.

| Field             | Type      | Required | Description                                                       | Default             |
| ----------------- | --------- | -------- | ----------------------------------------------------------------- | ------------------- |
| `id`              | string    | ✅       | Document ID (auto)                                                | -                   |
| `judul`           | string    | ✅       | Judul materi                                                      | -                   |
| `deskripsi`       | string    | ✅       | Deskripsi materi                                                  | -                   |
| `jenis`           | string    | ✅       | Jenis: `alquran`, `hadits`, `fiqih`, `akhlak`, `tafsir`, `tajwid` | -                   |
| `level`           | string    | ✅       | Level: `pemula`, `menengah`, `lanjutan`                           | `pemula`            |
| `konten`          | string    | ✅       | Konten materi (markdown/HTML)                                     | -                   |
| `videoUrl`        | string    | ❌       | URL video pembelajaran                                            | -                   |
| `audioUrl`        | string    | ❌       | URL audio                                                         | -                   |
| `pdfUrl`          | string    | ❌       | URL file PDF                                                      | -                   |
| `thumbnailUrl`    | string    | ❌       | URL thumbnail                                                     | -                   |
| `estimasiWaktu`   | number    | ❌       | Estimasi waktu belajar (menit)                                    | `30`                |
| `poinSelesai`     | number    | ❌       | Poin untuk menyelesaikan                                          | `20`                |
| `urutan`          | number    | ❌       | Urutan materi dalam jenis                                         | `0`                 |
| `prerequisite`    | array     | ❌       | Array ID materi prerequisite                                      | `[]`                |
| `tags`            | array     | ❌       | Tags untuk pencarian                                              | `[]`                |
| `viewCount`       | number    | ❌       | Jumlah views                                                      | `0`                 |
| `completionCount` | number    | ❌       | Jumlah yang selesai                                               | `0`                 |
| `isActive`        | boolean   | ✅       | Status aktif                                                      | `true`              |
| `isPublished`     | boolean   | ✅       | Status published                                                  | `true`              |
| `createdBy`       | string    | ✅       | User ID pembuat                                                   | -                   |
| `createdAt`       | timestamp | ✅       | Waktu pembuatan                                                   | `serverTimestamp()` |
| `updatedAt`       | timestamp | ✅       | Waktu update                                                      | `serverTimestamp()` |

**Indexes:**

- `jenis` (Ascending)
- `level` (Ascending)
- `urutan` (Ascending)
- `isActive` (Ascending)
- Composite: `jenis` + `level` + `urutan`

**Jenis Materi:**

- `alquran` - Materi Al-Qur'an
- `hadits` - Materi Hadits
- `fiqih` - Materi Fiqih
- `akhlak` - Materi Akhlak
- `tafsir` - Materi Tafsir
- `tajwid` - Materi Tajwid

---

## 7. Progress_Santri

**Collection:** `progress_santri`

Progress belajar santri untuk setiap materi.

| Field           | Type      | Required | Description                                        | Default             |
| --------------- | --------- | -------- | -------------------------------------------------- | ------------------- |
| `id`            | string    | ✅       | Document ID (auto)                                 | -                   |
| `santriId`      | string    | ✅       | User ID santri                                     | -                   |
| `materiId`      | string    | ✅       | ID materi                                          | -                   |
| `status`        | string    | ✅       | Status: `belum_mulai`, `sedang_belajar`, `selesai` | `belum_mulai`       |
| `persentase`    | number    | ✅       | Persentase progress (0-100)                        | `0`                 |
| `waktuMulai`    | timestamp | ❌       | Waktu mulai belajar                                | -                   |
| `waktuSelesai`  | timestamp | ❌       | Waktu selesai                                      | -                   |
| `durasiTotal`   | number    | ❌       | Total durasi belajar (detik)                       | `0`                 |
| `nilaiTest`     | number    | ❌       | Nilai test/quiz (0-100)                            | -                   |
| `jumlahUlangan` | number    | ❌       | Jumlah mengulang materi                            | `0`                 |
| `catatan`       | string    | ❌       | Catatan santri                                     | -                   |
| `lastPosition`  | number    | ❌       | Posisi terakhir (untuk video)                      | `0`                 |
| `poinDiperoleh` | number    | ❌       | Poin yang sudah diperoleh                          | `0`                 |
| `createdAt`     | timestamp | ✅       | Waktu pembuatan                                    | `serverTimestamp()` |
| `updatedAt`     | timestamp | ✅       | Waktu update                                       | `serverTimestamp()` |

**Indexes:**

- `santriId` (Ascending)
- `materiId` (Ascending)
- `status` (Ascending)
- Composite: `santriId` + `status`

---

## 8. Sesi_Kajian

**Collection:** `sesi_kajian`

Sesi kajian/pembelajaran untuk tracking per pertemuan.

| Field           | Type      | Required | Description              | Default             |
| --------------- | --------- | -------- | ------------------------ | ------------------- |
| `id`            | string    | ✅       | Document ID (auto)       | -                   |
| `santriId`      | string    | ✅       | User ID santri           | -                   |
| `materiId`      | string    | ✅       | ID materi                | -                   |
| `tanggal`       | timestamp | ✅       | Tanggal sesi             | `serverTimestamp()` |
| `durasi`        | number    | ✅       | Durasi sesi (detik)      | `0`                 |
| `catatan`       | string    | ❌       | Catatan sesi             | -                   |
| `poinDiperoleh` | number    | ❌       | Poin sesi ini            | `0`                 |
| `aktifitas`     | array     | ❌       | Log aktivitas dalam sesi | `[]`                |
| `createdAt`     | timestamp | ✅       | Waktu pembuatan          | `serverTimestamp()` |

**Indexes:**

- `santriId` (Ascending)
- `materiId` (Ascending)
- `tanggal` (Descending)

---

## 9. RFID_Cards

**Collection:** `rfid_cards`

Data kartu RFID santri untuk presensi.

| Field          | Type      | Required | Description                                           | Default             |
| -------------- | --------- | -------- | ----------------------------------------------------- | ------------------- |
| `id`           | string    | ✅       | Document ID (cardId/UID)                              | -                   |
| `cardId`       | string    | ✅       | UID kartu RFID                                        | -                   |
| `userId`       | string    | ❌       | User ID santri (jika sudah terdaftar)                 | -                   |
| `userName`     | string    | ❌       | Nama santri                                           | -                   |
| `status`       | string    | ✅       | Status: `active`, `inactive`, `blocked`, `unassigned` | `unassigned`        |
| `isRegistered` | boolean   | ✅       | Apakah sudah didaftarkan                              | `false`             |
| `lastUsed`     | timestamp | ❌       | Waktu penggunaan terakhir                             | -                   |
| `totalScans`   | number    | ❌       | Total scan                                            | `0`                 |
| `registeredAt` | timestamp | ❌       | Waktu pendaftaran                                     | -                   |
| `registeredBy` | string    | ❌       | User ID pendaftar                                     | -                   |
| `notes`        | string    | ❌       | Catatan                                               | -                   |
| `createdAt`    | timestamp | ✅       | Waktu pembuatan                                       | `serverTimestamp()` |
| `updatedAt`    | timestamp | ✅       | Waktu update                                          | `serverTimestamp()` |

**Indexes:**

- `cardId` (Ascending) - UNIQUE
- `userId` (Ascending)
- `status` (Ascending)

---

## 10. RFID_Scan_Requests

**Collection:** `rfid_scan_requests`

Request untuk scan kartu RFID baru (real-time).

| Field         | Type      | Required | Description                                          | Default             |
| ------------- | --------- | -------- | ---------------------------------------------------- | ------------------- |
| `id`          | string    | ✅       | Document ID (auto)                                   | -                   |
| `requestId`   | string    | ✅       | Unique request ID                                    | -                   |
| `requestedBy` | string    | ✅       | User ID yang request                                 | -                   |
| `status`      | string    | ✅       | Status: `pending`, `scanned`, `cancelled`, `expired` | `pending`           |
| `cardId`      | string    | ❌       | UID kartu (setelah di-scan)                          | -                   |
| `purpose`     | string    | ✅       | Tujuan: `register`, `verify`, `check`                | `register`          |
| `expiresAt`   | timestamp | ✅       | Waktu kadaluarsa request                             | -                   |
| `scannedAt`   | timestamp | ❌       | Waktu di-scan                                        | -                   |
| `deviceId`    | string    | ❌       | ID device yang scan                                  | -                   |
| `createdAt`   | timestamp | ✅       | Waktu pembuatan                                      | `serverTimestamp()` |

**Indexes:**

- `requestId` (Ascending) - UNIQUE
- `status` (Ascending)
- `expiresAt` (Ascending)

---

## 11. Activities

**Collection:** `activities`

Log aktivitas sistem untuk audit trail.

| Field         | Type      | Required | Description                                                 | Default             |
| ------------- | --------- | -------- | ----------------------------------------------------------- | ------------------- |
| `id`          | string    | ✅       | Document ID (auto)                                          | -                   |
| `userId`      | string    | ✅       | User ID pelaku                                              | -                   |
| `userName`    | string    | ❌       | Nama pelaku                                                 | -                   |
| `userRole`    | string    | ❌       | Role pelaku                                                 | -                   |
| `action`      | string    | ✅       | Jenis aksi: `create`, `update`, `delete`, `login`, `logout` | -                   |
| `module`      | string    | ✅       | Module: `presensi`, `jadwal`, `pengumuman`, `user`, dll     | -                   |
| `targetId`    | string    | ❌       | ID target/objek                                             | -                   |
| `targetName`  | string    | ❌       | Nama target                                                 | -                   |
| `description` | string    | ✅       | Deskripsi aktivitas                                         | -                   |
| `metadata`    | map       | ❌       | Data tambahan                                               | `{}`                |
| `ipAddress`   | string    | ❌       | IP address                                                  | -                   |
| `userAgent`   | string    | ❌       | User agent                                                  | -                   |
| `timestamp`   | timestamp | ✅       | Waktu aktivitas                                             | `serverTimestamp()` |

**Indexes:**

- `userId` (Ascending)
- `action` (Ascending)
- `module` (Ascending)
- `timestamp` (Descending)
- Composite: `userId` + `timestamp`

---

## 📈 Relationship Diagram

```
users (1) ──────────── (*) presensi
  │                         │
  │                         │
  └── (1) ────────── (*) presensi_aggregates
  │
  └── (1) ────────── (*) progress_santri
  │                         │
  │                         └── (*) ───── (1) materi
  │
  └── (1) ────────── (*) sesi_kajian
  │                         │
  │                         └── (*) ───── (1) materi
  │
  └── (1:1) ───────── (1) rfid_cards


jadwal (1) ─────────── (*) presensi


pengumuman (standalone)


activities (log)
```

---

## 🔐 Security Rules

Berikut adalah Firebase Security Rules yang direkomendasikan:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function isDewaGuru() {
      return isSignedIn() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'dewan_guru';
    }

    function isSantri() {
      return isSignedIn() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'santri';
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isAdmin();
      allow update: if isAdmin() || isOwner(userId);
      allow delete: if isAdmin();
    }

    // Jadwal collection
    match /jadwal/{jadwalId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isDewaGuru();
    }

    // Presensi collection
    match /presensi/{presensiId} {
      allow read: if isSignedIn();
      allow create: if isAdmin() || isDewaGuru() || isSantri();
      allow update: if isAdmin() || isDewaGuru();
      allow delete: if isAdmin();
    }

    // Presensi aggregates
    match /presensi_aggregates/{aggregateId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isDewaGuru();
    }

    // Pengumuman
    match /pengumuman/{pengumumanId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isDewaGuru();
    }

    // Materi
    match /materi/{materiId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isDewaGuru();
    }

    // Progress santri
    match /progress_santri/{progressId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isAdmin() || isDewaGuru() ||
                    (isSantri() && resource.data.santriId == request.auth.uid);
      allow delete: if isAdmin();
    }

    // Sesi kajian
    match /sesi_kajian/{sesiId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isAdmin() || isDewaGuru() ||
                    (isSantri() && resource.data.santriId == request.auth.uid);
      allow delete: if isAdmin();
    }

    // RFID cards
    match /rfid_cards/{cardId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isDewaGuru();
    }

    // RFID scan requests
    match /rfid_scan_requests/{requestId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isAdmin();
    }

    // Activities log
    match /activities/{activityId} {
      allow read: if isAdmin();
      allow create: if isSignedIn();
      allow update, delete: if false; // Activities are immutable
    }
  }
}
```

---

## 📝 Notes

1. **Timestamp Fields**: Gunakan `FieldValue.serverTimestamp()` untuk semua field timestamp
2. **Array Fields**: Pastikan array tidak melebihi 20,000 items
3. **String Length**: Maksimal 1MB per field
4. **Document Size**: Maksimal 1MB per document
5. **Indexes**: Buat composite index untuk query yang kompleks
6. **Aggregation**: Gunakan `presensi_aggregates` untuk menghindari query berulang ke collection `presensi`

---

## 🔄 Migration Notes

Jika melakukan perubahan schema:

1. Backup data dengan Firebase Export
2. Jalankan migration script
3. Update indexes di Firebase Console
4. Update Security Rules
5. Test di development environment
6. Deploy ke production

---

**Last Updated:** 10 Desember 2025
**Version:** 1.0.0
