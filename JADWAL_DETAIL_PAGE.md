# Halaman Detail Jadwal

## Overview

Halaman detail jadwal menampilkan informasi lengkap tentang sebuah jadwal termasuk informasi pemateri, materi, statistik presensi, dan daftar santri yang hadir.

## Fitur

### 1. **Header dengan Gradient**

- Menampilkan nama jadwal
- Background gradient sesuai kategori
- Icon kategori sebagai watermark

### 2. **Informasi Jadwal**

- **Kategori Badge**: Badge yang menunjukkan tipe jadwal (Pengajian, Tahfidz, Bacaan, Olahraga, Kegiatan)
- **Tanggal & Waktu**: Menampilkan tanggal lengkap dan range waktu pelaksanaan
- **Lokasi**: Tempat pelaksanaan jadwal
- **Poin**: Informasi poin yang didapat jika hadir

### 3. **Informasi Pemateri** (Jika Ada)

- Foto profil pemateri
- Nama lengkap
- Email pemateri
- Card dengan design khusus

### 4. **Informasi Materi** (Jika Ada)

- Range ayat (untuk materi Al-Quran)
- Range halaman (untuk materi hadist/lainnya)

### 5. **Deskripsi**

- Deskripsi lengkap tentang jadwal
- Ditampilkan dalam card terpisah

### 6. **Statistik Presensi**

- Total kehadiran (Hadir)
- Total izin
- Total sakit
- Total alpha
- Total presensi keseluruhan
- Visualisasi dengan circle badge berwarna

### 7. **Daftar Presensi Santri**

- List semua santri yang telah presensi
- Foto profil santri
- Nama santri
- Status kehadiran (badge berwarna)
- Waktu presensi
- Poin yang didapat
- Counter jumlah santri

## Providers

### `jadwalDetailProvider`

Stream provider untuk mendapatkan data jadwal secara realtime dari Firestore.

```dart
final jadwalAsync = ref.watch(jadwalDetailProvider(jadwalId));
```

### `pemateriProvider`

Future provider untuk mendapatkan data pemateri berdasarkan pemateriId.

```dart
final pemateriAsync = ref.watch(pemateriProvider(jadwal.pemateriId));
```

### `jadwalPresensiProvider`

Stream provider untuk mendapatkan daftar presensi santri untuk jadwal tertentu.

```dart
final presensiAsync = ref.watch(jadwalPresensiProvider(jadwalId));
```

## Navigasi

Dari halaman jadwal utama (`JadwalPage`), klik pada card jadwal untuk membuka detail:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => JadwalDetailPage(jadwalId: jadwal.id),
  ),
);
```

## Warna Kategori

- **Pengajian**: Hijau (`Colors.green`)
- **Tahfidz**: Ungu (`Colors.purple`)
- **Bacaan**: Biru (`Colors.blue`)
- **Olahraga**: Orange (`Colors.orange`)
- **Kegiatan**: Primary Color (`AppTheme.primaryColor`)

## Warna Status Presensi

- **Hadir**: Hijau (`Colors.green`)
- **Izin**: Orange (`Colors.orange`)
- **Sakit**: Biru (`Colors.blue`)
- **Alpha**: Merah (`Colors.red`)

## File Struktur

```
lib/features/shared/jadwal/presentation/
├── jadwal_page.dart              # Halaman list jadwal
└── jadwal_detail_page.dart       # Halaman detail jadwal (BARU)
```

## Dependencies

- `flutter_riverpod`: State management
- `cloud_firestore`: Realtime database
- `intl`: Format tanggal
- `sisantri/core/theme/app_theme.dart`: Theme constants
- `sisantri/shared/models/jadwal_model.dart`: Model jadwal
- `sisantri/shared/models/user_model.dart`: Model user
- `sisantri/shared/services/auth_service.dart`: Service untuk get user data

## Realtime Updates

Halaman ini menggunakan `StreamProvider` sehingga:

- Data jadwal update otomatis jika ada perubahan
- Daftar presensi update realtime ketika ada santri baru presensi
- Statistik presensi update otomatis

## Loading & Error Handling

- **Loading State**: Menampilkan circular progress indicator
- **Error State**: Menampilkan icon error dengan pesan dan tombol kembali
- **Empty State**: Menampilkan "Belum ada presensi" jika belum ada yang presensi

## Responsive Design

- Menggunakan `CustomScrollView` dengan `SliverAppBar` untuk scroll yang smooth
- Card dengan shadow untuk depth
- Padding dan spacing yang konsisten
- Icon dan badge untuk visual feedback
