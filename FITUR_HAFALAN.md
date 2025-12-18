# Fitur Hafalan - Dokumentasi

## Overview
Fitur hafalan adalah sistem untuk mengelola dan melacak progress hafalan santri, mencakup Al-Quran, doa-doa, dan materi tambahan.

## Alur Fitur

### 1. **Daftar Materi Hafalan**
Ada 3 tipe materi:
- **Al-Quran**: Otomatis terbuat (akan di-generate)
- **Doa**: Ditambahkan manual oleh admin
- **Tambahan**: Hadist, surat pendek, dll - ditambahkan manual oleh admin

### 2. **Flow Hafalan**
1. **Santri** melihat daftar materi hafalan di menu "Hafalan Saya"
2. **Santri** mulai hafalan dengan menekan tombol "Mulai Hafalan"
3. Status berubah menjadi "Proses" (menunggu konfirmasi guru)
4. **Guru** melihat list hafalan pending di menu "Konfirmasi Hafalan"
5. **Guru** mengkonfirmasi hafalan dengan:
   - Status: Lulus atau Perlu Perbaikan
   - Nilai: 0-100
   - Catatan (opsional)
6. Jika **lulus**, status menjadi "Selesai" dan tercatat di progress santri
7. Jika **perlu perbaikan**, santri bisa mencoba lagi

## Struktur Folder

```
lib/features/hafalan/
├── domain/
│   ├── entities/
│   │   ├── hafalan_materi.dart       # Entity materi hafalan
│   │   └── hafalan_progress.dart     # Entity progress santri
│   └── repositories/
│       └── hafalan_repository.dart   # Interface repository
├── data/
│   └── repositories/
│       └── hafalan_repository_impl.dart  # Implementasi repository
└── presentation/
    ├── pages/
    │   ├── admin_hafalan_materi_page.dart      # Halaman admin
    │   ├── guru_konfirmasi_hafalan_page.dart   # Halaman guru
    │   └── santri_hafalan_page.dart            # Halaman santri
    ├── widgets/
    │   ├── materi_form_dialog.dart             # Form tambah/edit materi
    │   ├── konfirmasi_hafalan_dialog.dart      # Dialog konfirmasi guru
    │   └── hafalan_detail_dialog.dart          # Detail hafalan untuk santri
    └── providers/
        └── hafalan_provider.dart               # Riverpod providers
```

## Firestore Collections

### Collection: `hafalan_materi`
```json
{
  "id": "auto-generated",
  "judul": "Doa Sebelum Makan",
  "tipe": "doa", // alquran, doa, tambahan
  "arabText": "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
  "latinText": "Bismillahirrahmanirrahim",
  "translation": "Dengan menyebut nama Allah...",
  "suratName": null, // untuk alquran
  "suratNumber": null,
  "ayatStart": null,
  "ayatEnd": null,
  "createdAt": "timestamp",
  "createdBy": "admin_uid",
  "isActive": true,
  "urutan": 0
}
```

### Collection: `hafalan_progress`
```json
{
  "id": "auto-generated",
  "santriId": "user_uid",
  "materiId": "materi_id",
  "status": "proses", // belum, proses, selesai
  "tanggalMulai": "timestamp",
  "tanggalSelesai": null,
  "guruPengujiId": null,
  "guruPengujiName": null,
  "catatan": null,
  "nilai": null,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Menu Akses

### Admin
- **Dashboard Admin** > **Manajemen Hafalan**
  - Tambah/Edit/Hapus materi doa dan tambahan
  - Lihat daftar semua materi

### Guru (Dewan Guru)
- **Dashboard Guru** > **Konfirmasi Hafalan**
  - Lihat list hafalan pending (status "proses")
  - Konfirmasi hafalan dengan nilai dan catatan
  - Set status: Lulus atau Perlu Perbaikan

### Santri
- **Dashboard Santri** > Card **"Hafalan Saya"**
  - Lihat daftar materi hafalan
  - Lihat progress (statistik: total, selesai, proses)
  - Mulai hafalan
  - Lihat detail materi dan catatan guru

## Features

### Admin Features
✅ CRUD materi doa dan tambahan
✅ Lihat materi berdasarkan tipe (Al-Quran, Doa, Tambahan)
✅ Soft delete materi (isActive = false)
✅ Urutan materi

### Guru Features
✅ Lihat list hafalan pending
✅ Konfirmasi hafalan dengan nilai dan catatan
✅ Approve (Lulus) atau Reject (Perlu Perbaikan)
✅ Filter hafalan by santri

### Santri Features
✅ Lihat daftar semua materi
✅ Statistik progress (total, selesai, proses)
✅ Mulai hafalan
✅ Lihat detail materi (teks arab, latin, terjemahan)
✅ Lihat catatan dari guru
✅ Progress indicator visual

## TODO - Future Enhancements

1. **Generate Al-Quran Automatically**
   - Buat script untuk generate materi Al-Quran otomatis
   - Data surat dan ayat bisa dari API atau JSON file

2. **Audio Recording**
   - Santri bisa merekam hafalan mereka
   - Guru bisa dengarkan rekaman sebelum konfirmasi

3. **Target Hafalan**
   - Admin bisa set target hafalan per santri
   - Dashboard menampilkan progress terhadap target

4. **Reminder**
   - Notifikasi untuk santri yang belum mulai hafalan
   - Notifikasi untuk guru ada hafalan pending

5. **Report & Analytics**
   - Report hafalan per santri
   - Export to PDF
   - Grafik progress hafalan

6. **Gamifikasi**
   - Badge untuk milestones tertentu
   - Leaderboard hafalan

## Notes

- Materi Al-Quran akan di-generate otomatis (belum diimplementasi)
- Admin tidak bisa edit/hapus materi Al-Quran (read-only)
- Santri bisa mulai hafalan kapan saja
- Satu materi bisa memiliki multiple progress entries (untuk re-try)
- Nilai minimum 0, maksimum 100
- Status hafalan: belum, proses, selesai
