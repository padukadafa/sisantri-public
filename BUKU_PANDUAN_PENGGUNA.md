# 📚 Buku Panduan Pengguna SiSantri

## Sistem Gamifikasi Pondok Pesantren Modern

**Versi 1.0.0**  
**Pondok Pesantren Mahasiswa Al-Awwabin Sukarame – Bandar Lampung**  
**Tanggal: Desember 2025**

---

## 📖 Daftar Isi

1. [Pengenalan Sistem](#pengenalan-sistem)
2. [Memulai Aplikasi](#memulai-aplikasi)
3. [Panduan untuk Santri](#panduan-untuk-santri)
4. [Panduan untuk Dewan Guru](#panduan-untuk-dewan-guru)
5. [Panduan untuk Admin](#panduan-untuk-admin)
6. [Panduan Penggunaan Alat RFID](#panduan-penggunaan-alat-rfid)
7. [FAQ & Troubleshooting](#faq--troubleshooting)
8. [Kontak & Dukungan](#kontak--dukungan)

---

## 🌟 Pengenalan Sistem

### Apa itu SiSantri?

SiSantri adalah sistem gamifikasi digital yang dirancang khusus untuk Pondok Pesantren modern. Aplikasi ini membantu santri dalam:

- ✅ Melakukan presensi kehadiran secara otomatis dengan kartu RFID
- 📅 Melihat jadwal pengajian dan kegiatan pondok
- 🏆 Mengikuti sistem poin dan ranking leaderboard
- 📢 Menerima pengumuman penting dari pengurus
- 📊 Memantau progres dan pencapaian pribadi

### Fitur Utama

| Fitur              | Deskripsi                                   |
| ------------------ | ------------------------------------------- |
| **Presensi RFID**  | Tap kartu RFID untuk presensi otomatis      |
| **Jadwal Digital** | Lihat jadwal pengajian dan kegiatan lengkap |
| **Sistem Poin**    | Kumpulkan poin dari kehadiran dan aktivitas |
| **Leaderboard**    | Kompetisi sehat antar santri                |
| **Level System**   | 10 level dari Pemula hingga Legend          |
| **Pengumuman**     | Notifikasi real-time pengumuman penting     |
| **Dashboard**      | Statistik dan analisis personal             |

### Arsitektur Sistem

```
┌─────────────────┐
│  Mobile App     │ ← Santri, Guru, Admin
│  (Flutter)      │
└────────┬────────┘
         │
┌────────▼────────┐
│  Firebase       │
│  - Auth         │
│  - Firestore    │
│  - Storage      │
│  - FCM          │
└────────┬────────┘
         │
┌────────▼────────┐
│  IoT RFID       │ ← Alat Scanner
│  (ESP32)        │
└─────────────────┘
```

---

## 🚀 Memulai Aplikasi

### Instalasi Aplikasi

#### Android

1. Download file APK dari link yang diberikan admin
2. Buka file APK di smartphone Android
3. Izinkan instalasi dari sumber tidak dikenal jika diminta
4. Tap "Install" dan tunggu hingga selesai
5. Buka aplikasi SiSantri

**📸 Lokasi Screenshot:**

- `assets/images/panduan/instalasi_android_01.png` - Download APK
- `assets/images/panduan/instalasi_android_02.png` - Proses instalasi
- `assets/images/panduan/instalasi_android_03.png` - Aplikasi terinstal

#### iOS

1. Download aplikasi dari App Store (jika sudah tersedia)
2. Atau gunakan TestFlight untuk versi beta
3. Tap "Get" / "Install"
4. Buka aplikasi SiSantri

**📸 Lokasi Screenshot:**

- `assets/images/panduan/instalasi_ios_01.png` - App Store
- `assets/images/panduan/instalasi_ios_02.png` - Proses download

### Login Pertama Kali

#### Langkah Login

1. **Buka Aplikasi SiSantri**

   - Anda akan melihat halaman login dengan logo masjid hijau
   - Terdapat tombol "Login dengan Google"

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/login_01_splash.png` - Splash screen
   - `assets/images/panduan/login_02_page.png` - Halaman login

2. **Tap Tombol "Login dengan Google"**

   - Pilih akun Google yang terdaftar di perangkat Anda
   - Atau masukkan email dan password Google jika diminta

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/login_03_google.png` - Google Sign-In

3. **Izinkan Akses**

   - Aplikasi akan meminta izin akses akun Google
   - Tap "Izinkan" atau "Allow"

4. **Tunggu Verifikasi**

   - Sistem akan memverifikasi akun Anda
   - Jika akun sudah terdaftar, Anda akan masuk ke dashboard
   - Jika belum terdaftar, hubungi admin untuk registrasi

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/login_04_verifikasi.png` - Loading verifikasi

#### Troubleshooting Login

| Masalah                    | Solusi                              |
| -------------------------- | ----------------------------------- |
| "Pengguna tidak terdaftar" | Hubungi admin untuk registrasi akun |
| "Akun tidak aktif"         | Hubungi admin untuk aktivasi        |
| Gagal connect internet     | Periksa koneksi internet Anda       |
| Error Google Sign-In       | Coba logout Google lalu login ulang |

---

## 👤 Panduan untuk Santri

### Dashboard Santri

Setelah login, Anda akan melihat **Dashboard Santri** dengan informasi:

#### Welcome Card

- Foto profil Anda
- Nama lengkap
- **Level Badge** (misal: 🌱 Santri Pemula)
- Total poin yang dikumpulkan
- Progress bar menuju level berikutnya

**📸 Lokasi Screenshot:**

- `assets/images/panduan/santri_dashboard_01.png` - Dashboard utama
- `assets/images/panduan/santri_dashboard_02_welcome.png` - Welcome card detail

#### Statistik Presensi

- Total kehadiran bulan ini
- Persentase kehadiran
- Streak (hari berturut-turut hadir)
- Status presensi hari ini

**📸 Lokasi Screenshot:**

- `assets/images/panduan/santri_dashboard_03_stats.png` - Statistik presensi

#### Kegiatan Hari Ini

- Daftar jadwal pengajian dan kegiatan hari ini
- Waktu pelaksanaan
- Lokasi kegiatan
- Status presensi (sudah/belum)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/santri_dashboard_04_kegiatan.png` - Kegiatan hari ini

### Presensi dengan Kartu RFID

#### Cara Melakukan Presensi

1. **Persiapkan Kartu RFID**

   - Pastikan Anda sudah memiliki kartu RFID yang terdaftar
   - Kartu berbentuk kartu seperti KTP atau gantungan kunci

2. **Temukan Alat Scanner RFID**

   - Alat scanner biasanya berada di:
     - Pintu masuk masjid/aula
     - Ruang kajian
     - Area kegiatan pondok
   - Alat akan menampilkan status "Ready" atau "Siap Scan"

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/alat_rfid_01.png` - Tampilan alat RFID
   - `assets/images/panduan/alat_rfid_02_lokasi.png` - Lokasi pemasangan

3. **Tempelkan Kartu ke Scanner**

   - Dekatkan kartu RFID ke area scanner (biasanya ada logo 📡)
   - Jarak ideal: 1-5 cm dari reader
   - Tunggu hingga LED berkedip atau bunyi "beep"

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/presensi_rfid_01_tap.png` - Cara tap kartu
   - `assets/images/panduan/presensi_rfid_02_jarak.png` - Jarak ideal

4. **Lihat Konfirmasi**

   - **Sukses**: LED hijau menyala, bunyi "beep" 1x

     - LCD menampilkan: "Sukses! [Nama Anda]"
     - Status: "Hadir" atau "Terlambat" (sesuai waktu)

   - **Gagal**: LED merah menyala, bunyi "beep" 2x
     - LCD menampilkan: "Kartu Tidak Terdaftar"
     - Hubungi admin untuk registrasi kartu

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/presensi_rfid_03_sukses.png` - Konfirmasi sukses
   - `assets/images/panduan/presensi_rfid_04_gagal.png` - Konfirmasi gagal

5. **Cek di Aplikasi**

   - Buka aplikasi SiSantri
   - Data presensi akan muncul dalam 1-2 detik
   - Poin otomatis bertambah

   **📸 Lokasi Screenshot:**

   - `assets/images/panduan/presensi_rfid_05_notif.png` - Notifikasi di app
   - `assets/images/panduan/presensi_rfid_06_poin.png` - Poin bertambah

#### Status Presensi

| Status        | Kondisi                                | Poin     |
| ------------- | -------------------------------------- | -------- |
| **Hadir**     | Scan sebelum waktu mulai               | +10 poin |
| **Terlambat** | Scan setelah 15 menit dari waktu mulai | +5 poin  |
| **Izin**      | Sudah mengajukan izin ke admin         | +5 poin  |
| **Sakit**     | Ada surat/konfirmasi sakit             | +5 poin  |
| **Alpha**     | Tidak hadir tanpa keterangan           | 0 poin   |

#### Bonus Poin Streak

- **Streak 7 hari**: +20 bonus poin
- **Streak 14 hari**: +50 bonus poin
- **Streak 30 hari**: +100 bonus poin

### Melihat Jadwal

#### Menu Jadwal Pengajian

1. Tap menu **"Jadwal"** di bottom navigation
2. Anda akan melihat daftar jadwal pengajian/kegiatan

**📸 Lokasi Screenshot:**

- `assets/images/panduan/jadwal_01_list.png` - Daftar jadwal

#### Filter Jadwal

- **Tab Hari Ini**: Jadwal hari ini saja
- **Tab Minggu Ini**: Jadwal 7 hari ke depan
- **Tab Bulan Ini**: Semua jadwal bulan ini

**📸 Lokasi Screenshot:**

- `assets/images/panduan/jadwal_02_filter.png` - Filter jadwal

#### Detail Jadwal

Tap salah satu jadwal untuk melihat detail:

- **Header Gradient** dengan nama kegiatan
- **Badge Kategori** (Pengajian/Tahfidz/Bacaan/Olahraga/Kegiatan)
- **Tanggal & Waktu** lengkap
- **Lokasi** pelaksanaan
- **Poin** yang didapat jika hadir
- **Pemateri** (jika ada) dengan foto dan kontak
- **Materi Kajian** (jika ada):
  - Nama kitab/materi
  - Jenis materi (Quran/Hadist/Lainnya)
  - Range ayat atau halaman
  - Pengarang (jika ada)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/jadwal_03_detail_header.png` - Header detail jadwal
- `assets/images/panduan/jadwal_04_detail_info.png` - Info jadwal lengkap
- `assets/images/panduan/jadwal_05_detail_pemateri.png` - Card pemateri
- `assets/images/panduan/jadwal_06_detail_materi.png` - Info materi kajian

### Leaderboard & Ranking

#### Melihat Ranking

1. Tap menu **"Ranking"** di bottom navigation
2. Lihat posisi Anda di antara santri lain

**📸 Lokasi Screenshot:**

- `assets/images/panduan/ranking_01_leaderboard.png` - Halaman leaderboard

#### Filter Periode

- **Mingguan**: Ranking minggu ini
- **Bulanan**: Ranking bulan ini
- **Tahunan**: Ranking sepanjang tahun

**📸 Lokasi Screenshot:**

- `assets/images/panduan/ranking_02_filter.png` - Filter periode

#### Podium Top 3

Top 3 santri ditampilkan dengan podium khusus:

- 🥇 Juara 1: Podium emas dengan badge level
- 🥈 Juara 2: Podium perak dengan badge level
- 🥉 Juara 3: Podium perunggu dengan badge level

**📸 Lokasi Screenshot:**

- `assets/images/panduan/ranking_03_podium.png` - Podium top 3

#### Daftar Ranking

Semua santri ditampilkan dengan:

- Nomor urut
- Foto profil dengan **Level Badge Overlay**
- Nama lengkap
- **Level Badge** (emoji dan nama level)
- Total poin
- Progress bar level

**📸 Lokasi Screenshot:**

- `assets/images/panduan/ranking_04_list.png` - Daftar ranking santri

### Sistem Level

#### 10 Level Progresif

| Level | Nama               | Poin Required | Badge | Warna       |
| ----- | ------------------ | ------------- | ----- | ----------- |
| 1     | Santri Pemula      | 0-99          | 🌱    | Light Green |
| 2     | Santri Rajin       | 100-249       | 🌿    | Green       |
| 3     | Santri Tekun       | 250-499       | 🍃    | Teal        |
| 4     | Santri Istiqomah   | 500-799       | ⭐    | Cyan        |
| 5     | Santri Berprestasi | 800-1199      | 🌟    | Blue        |
| 6     | Santri Teladan     | 1200-1699     | 💎    | Indigo      |
| 7     | Santri Juara       | 1700-2299     | 🏆    | Purple      |
| 8     | Santri Master      | 2300-2999     | 👑    | Deep Purple |
| 9     | Santri Expert      | 3000-3999     | 🔥    | Red         |
| 10    | Santri Legend      | 4000+         | ⚡    | Amber       |

**📸 Lokasi Screenshot:**

- `assets/images/panduan/level_01_pemula.png` - Badge Level 1
- `assets/images/panduan/level_02_rajin.png` - Badge Level 2
- `assets/images/panduan/level_10_legend.png` - Badge Level 10

#### Melihat Progress Level

1. Buka **Dashboard** atau **Profil**
2. Lihat **Level Card** yang menampilkan:
   - Badge level saat ini
   - Nama level
   - Total poin Anda
   - Progress bar menuju level berikutnya
   - Poin yang dibutuhkan untuk naik level

**📸 Lokasi Screenshot:**

- `assets/images/panduan/level_progress_01.png` - Level card di dashboard
- `assets/images/panduan/level_progress_02.png` - Progress bar detail

### Pengumuman

#### Melihat Pengumuman

1. Tap menu **"Pengumuman"** di bottom navigation
2. Lihat daftar pengumuman terbaru

**📸 Lokasi Screenshot:**

- `assets/images/panduan/pengumuman_01_list.png` - Daftar pengumuman

#### Detail Pengumuman

Tap pengumuman untuk melihat:

- Judul lengkap
- Isi pengumuman
- Tanggal publikasi
- Nama pembuat (admin)
- Gambar/foto lampiran (jika ada)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/pengumuman_03_detail.png` - Detail pengumuman
- `assets/images/panduan/pengumuman_04_image.png` - Pengumuman dengan gambar

### Profil & Pengaturan

#### Melihat Profil

1. Tap menu **"Profil"** di bottom navigation
2. Lihat informasi lengkap profil Anda

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_01_overview.png` - Halaman profil

#### Informasi Profil

- **Foto Profil** (tap untuk ganti foto)
- **Nama Lengkap**
- **Email**
- **NIM** (jika mahasiswa)
- **Role**: Santri
- **Status**: Aktif/Tidak Aktif
- **Level Badge** lengkap dengan progress
- **Total Poin**
- **RFID Card ID** (jika sudah terdaftar)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_02_info.png` - Info profil lengkap
- `assets/images/panduan/profil_03_level_card.png` - Level card di profil

#### Edit Profil

1. Tap tombol **"Edit Profil"**
2. Ubah informasi yang bisa diubah:
   - Foto profil
   - Nama lengkap
   - Nomor HP (opsional)
3. Tap **"Simpan"** untuk menyimpan perubahan

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_04_edit.png` - Form edit profil
- `assets/images/panduan/profil_05_upload_foto.png` - Upload foto profil

#### Ganti Foto Profil

1. Tap foto profil atau tombol kamera
2. Pilih sumber foto:
   - **Kamera**: Ambil foto baru
   - **Galeri**: Pilih dari galeri
3. Crop foto sesuai keinginan
4. Tap **"Selesai"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_06_choose_photo.png` - Pilih sumber foto
- `assets/images/panduan/profil_07_crop_photo.png` - Crop foto

#### Statistik Pribadi

Di halaman profil, scroll ke bawah untuk melihat:

- **Total Presensi**:
  - Hadir: X kali
  - Izin: X kali
  - Sakit: X kali
  - Alpha: X kali
- **Persentase Kehadiran**
- **Streak Terpanjang**
- **Total Kegiatan Diikuti**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_08_stats.png` - Statistik pribadi

#### Riwayat Presensi

1. Di halaman profil, tap **"Lihat Riwayat Presensi"**
2. Lihat daftar presensi lengkap:
   - Tanggal dan waktu
   - Nama kegiatan
   - Status presensi (dengan badge warna)
   - Poin yang didapat

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_09_history.png` - Riwayat presensi

#### Logout

1. Scroll ke bawah di halaman profil
2. Tap tombol **"Logout"** berwarna merah
3. Konfirmasi logout
4. Anda akan kembali ke halaman login

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil_10_logout.png` - Tombol logout
- `assets/images/panduan/profil_11_logout_confirm.png` - Konfirmasi logout

---

## 👨‍🏫 Panduan untuk Dewan Guru

### Dashboard Dewan Guru

Dashboard dewan guru memiliki akses lebih luas untuk monitoring:

#### Statistik Umum

- Total santri aktif
- Kehadiran hari ini
- Persentase kehadiran rata-rata
- Kegiatan hari ini

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_dashboard_01.png` - Dashboard dewan guru

#### Monitoring Presensi Real-time

1. Lihat **Presensi Hari Ini** di dashboard
2. Daftar santri yang sudah presensi
3. Status presensi (Hadir/Terlambat/Izin/Sakit)
4. Waktu presensi

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_presensi_01.png` - Monitoring presensi

#### Filter & Analisis

- Filter berdasarkan periode (hari/minggu/bulan)
- Export data ke Excel
- Lihat tren kehadiran

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_analisis_01.png` - Filter dan analisis

### Manajemen Santri

#### Melihat Daftar Santri

1. Tap menu **"Santri"**
2. Lihat daftar semua santri

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_santri_01_list.png` - Daftar santri

#### Detail Santri

Tap santri untuk melihat:

- Profil lengkap
- Statistik presensi
- Level dan poin
- Riwayat kehadiran
- Performa akademik

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_santri_02_detail.png` - Detail santri

### Laporan

#### Generate Laporan

1. Tap menu **"Laporan"**
2. Pilih jenis laporan:
   - Laporan Kehadiran Harian
   - Laporan Kehadiran Bulanan
   - Laporan per Santri
   - Laporan per Kegiatan
3. Pilih periode
4. Tap **"Generate"**
5. Laporan akan di-download dalam format Excel

**📸 Lokasi Screenshot:**

- `assets/images/panduan/guru_laporan_01.png` - Menu laporan
- `assets/images/panduan/guru_laporan_02_generate.png` - Generate laporan

---

## 🔧 Panduan untuk Admin

### Dashboard Admin

Dashboard admin memiliki kontrol penuh atas sistem:

#### Statistik Sistem

- Total santri (aktif/tidak aktif)
- Total guru
- Total admin
- Presensi hari ini
- Persentase kehadiran
- Device status (RFID)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_dashboard_01.png` - Dashboard admin lengkap

### Manajemen Pengguna

#### Tambah Pengguna Baru

1. Tap menu **"Pengguna"**
2. Tap tombol **"Tambah Pengguna"** (ikon +)
3. Isi form:
   - Nama lengkap
   - Email (harus email Google yang valid)
   - Role (Santri/Dewan Guru/Admin)
   - NIM (opsional)
   - Status (Aktif/Tidak Aktif)
4. Tap **"Simpan"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_user_01_list.png` - Daftar pengguna
- `assets/images/panduan/admin_user_02_add.png` - Form tambah pengguna

#### Edit Pengguna

1. Tap pengguna yang ingin diedit
2. Tap tombol **"Edit"**
3. Ubah informasi
4. Tap **"Simpan"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_user_03_detail.png` - Detail pengguna
- `assets/images/panduan/admin_user_04_edit.png` - Form edit pengguna

#### Registrasi Kartu RFID

1. Di detail pengguna, tap **"Daftarkan RFID"**
2. Dialog akan muncul dengan instruksi
3. Pengguna diminta menempelkan kartu ke scanner
4. Scanner akan membaca UID kartu
5. Sistem akan validasi dan menyimpan RFID
6. Konfirmasi sukses akan muncul

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_rfid_01_register.png` - Tombol register RFID
- `assets/images/panduan/admin_rfid_02_dialog.png` - Dialog instruksi
- `assets/images/panduan/admin_rfid_03_scan.png` - Proses scan
- `assets/images/panduan/admin_rfid_04_success.png` - Konfirmasi sukses

#### Hapus/Nonaktifkan Pengguna

1. Tap pengguna
2. Tap tombol **"Nonaktifkan"** atau **"Hapus"**
3. Konfirmasi aksi
4. Pengguna akan dinonaktifkan/dihapus

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_user_05_deactivate.png` - Nonaktifkan pengguna

### Manajemen Jadwal

#### Tambah Jadwal Baru

1. Tap menu **"Jadwal"**
2. Tap tombol **"Tambah Jadwal"** (ikon +)
3. Isi form jadwal:
   - **Nama kegiatan**
   - **Kategori**: Pilih dari dropdown
     - Pengajian
     - Tahfidz
     - Bacaan
     - Olahraga
     - Kegiatan
   - **Tanggal**: Pilih dari calendar
   - **Waktu Mulai & Selesai**
   - **Lokasi**
   - **Deskripsi**
   - **Poin**: Poin yang didapat jika hadir
   - **Status**: Aktif/Tidak Aktif

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_jadwal_01_list.png` - Daftar jadwal
- `assets/images/panduan/admin_jadwal_02_add_form.png` - Form tambah jadwal bagian 1

4. **Informasi Materi** (untuk Pengajian/Kajian/Tahfidz):
   - **Pilih Materi Kajian**: Dropdown dari database materi
     - Sistem akan menampilkan materi dengan badge jenis (Quran/Hadist/Lainnya)
     - Icon sesuai jenis materi
   - **Pilih Pemateri/Ustadz**: Dropdown dari dewan guru
   - **Tema/Judul Kajian**: Input text
   - **Range Materi** (tergantung jenis materi yang dipilih):
     - Jika materi jenis **Quran**:
       - Ayat Mulai & Ayat Selesai
     - Jika materi jenis **Hadist**:
       - Hadist Mulai & Hadist Selesai
     - Jika materi jenis **Lainnya**:
       - Halaman Mulai & Halaman Selesai

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_jadwal_03_materi_section.png` - Section informasi materi
- `assets/images/panduan/admin_jadwal_04_materi_dropdown.png` - Dropdown materi kajian
- `assets/images/panduan/admin_jadwal_05_pemateri_dropdown.png` - Dropdown pemateri
- `assets/images/panduan/admin_jadwal_06_range_quran.png` - Input range ayat Quran
- `assets/images/panduan/admin_jadwal_07_range_hadist.png` - Input range hadist
- `assets/images/panduan/admin_jadwal_08_range_halaman.png` - Input range halaman

5. Tap **"Simpan"**
6. Jadwal akan tersimpan dan muncul di aplikasi

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_jadwal_09_save_success.png` - Konfirmasi sukses

#### Edit Jadwal

1. Tap jadwal yang ingin diedit
2. Tap tombol **"Edit"**
3. Ubah informasi
4. Tap **"Simpan"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_jadwal_10_edit.png` - Form edit jadwal

#### Hapus Jadwal

1. Tap jadwal
2. Tap tombol **"Hapus"**
3. Konfirmasi hapus
4. Jadwal akan dihapus

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_jadwal_11_delete.png` - Konfirmasi hapus

### Manajemen Materi Kajian

#### Tambah Materi Kajian Baru

1. Tap menu **"Materi"**
2. Tap tombol **"Tambah Materi"** (ikon +)
3. Isi form:
   - **Nama Materi/Kitab** (contoh: Al-Quran, Shahih Bukhari, Riyadhus Shalihin)
   - **Jenis Materi**:
     - Quran (untuk kajian Al-Quran)
     - Hadist (untuk kitab hadist)
     - Lainnya (untuk kitab umum/fiqih/tafsir/dll)
   - **Pengarang** (opsional)
   - **Deskripsi** (opsional)
   - **Status**: Aktif/Tidak Aktif
4. Tap **"Simpan"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_materi_01_list.png` - Daftar materi kajian
- `assets/images/panduan/admin_materi_02_add.png` - Form tambah materi

#### Badge Jenis Materi

Setiap materi memiliki badge dan icon sesuai jenisnya:

- **📖 Quran** - Badge hijau
- **📚 Hadist** - Badge biru
- **📕 Lainnya** - Badge orange

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_materi_03_badges.png` - Badge jenis materi

### Manajemen Pengumuman

#### Buat Pengumuman Baru

1. Tap menu **"Pengumuman"**
2. Tap tombol **"Buat Pengumuman"** (ikon +)
3. Isi form:
   - **Judul**: Judul pengumuman
   - **Isi**: Konten pengumuman
   - **Tandai sebagai Penting**: Switch on/off
   - **Tambah Gambar** (opsional): Upload foto/gambar
4. Tap **"Publikasikan"**
5. Pengumuman akan terkirim dan notifikasi push dikirim ke semua pengguna

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_announcement_01_list.png` - Daftar pengumuman
- `assets/images/panduan/admin_announcement_02_create.png` - Form buat pengumuman
- `assets/images/panduan/admin_announcement_03_upload_image.png` - Upload gambar

#### Edit/Hapus Pengumuman

1. Tap pengumuman yang ingin diubah
2. Tap tombol **"Edit"** atau **"Hapus"**
3. Ubah dan simpan, atau konfirmasi hapus

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_announcement_04_edit.png` - Edit pengumuman

### Presensi Manual

Admin dapat melakukan presensi manual jika:

- Alat RFID bermasalah
- Santri lupa kartu RFID
- Presensi retrospektif

#### Cara Presensi Manual

1. Tap menu **"Presensi Manual"**
2. Pilih **Jadwal Kegiatan** dari dropdown
3. Pilih **Santri** dari daftar
4. Pilih **Status**:
   - Hadir
   - Izin (beri keterangan)
   - Sakit (beri keterangan)
   - Alpha
5. Tap **"Simpan Presensi"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_presensi_01_manual.png` - Form presensi manual
- `assets/images/panduan/admin_presensi_02_select_jadwal.png` - Pilih jadwal
- `assets/images/panduan/admin_presensi_03_select_santri.png` - Pilih santri
- `assets/images/panduan/admin_presensi_04_select_status.png` - Pilih status

### Monitoring Device RFID

#### Status Device

1. Tap menu **"Devices"** atau **"IoT"**
2. Lihat status semua device RFID:
   - Device ID
   - Lokasi pemasangan
   - Status: Online/Offline
   - Last seen (waktu terakhir aktif)
   - Total scan hari ini

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_device_01_status.png` - Status device RFID

#### Troubleshooting Device

Jika device offline:

1. Periksa koneksi WiFi device
2. Restart device (cabut dan colok ulang power)
3. Periksa kabel koneksi RFID reader
4. Lihat log error di backend (jika ada akses)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_device_02_troubleshoot.png` - Troubleshooting device

### Laporan & Export Data

#### Generate Laporan Excel

1. Tap menu **"Laporan"**
2. Pilih jenis laporan:
   - **Laporan Kehadiran Harian**
   - **Laporan Kehadiran Bulanan**
   - **Laporan per Santri**
   - **Laporan per Kegiatan**
   - **Laporan Poin & Ranking**
3. Pilih periode/filter:
   - Tanggal mulai & akhir
   - Kategori kegiatan
   - Santri tertentu (opsional)
4. Tap **"Generate Excel"**
5. File akan di-download ke perangkat

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_report_01_menu.png` - Menu laporan
- `assets/images/panduan/admin_report_02_filter.png` - Filter laporan
- `assets/images/panduan/admin_report_03_download.png` - Download Excel

#### Format Laporan Excel

Laporan akan berisi:

- Header: Nama pondok, periode, tanggal generate
- Tabel data dengan kolom:
  - No, Nama, NIM, Tanggal, Kegiatan, Status, Poin, dll
- Summary: Total hadir, izin, sakit, alpha, persentase
- Footer: Tanda tangan digital dan cap

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_report_04_excel_sample.png` - Contoh laporan Excel

---

## 🔧 Panduan Penggunaan Alat RFID

### Spesifikasi Hardware

#### Komponen Utama

1. **ESP32 Microcontroller**

   - Prosesor utama
   - WiFi built-in
   - GPIO pins untuk koneksi

2. **MFRC522 RFID Reader Module**

   - Frekuensi: 13.56 MHz
   - Jarak baca: 1-5 cm
   - Interface: SPI

3. **LCD Display 16x2**

   - Menampilkan status dan feedback
   - Interface: I2C

4. **LED Indicator**

   - LED Hijau: Sukses scan
   - LED Merah: Gagal scan
   - LED Biru: Standby

5. **Buzzer/Speaker**
   - Feedback suara saat scan
   - Beep 1x: Sukses
   - Beep 2x: Gagal

**📸 Lokasi Screenshot:**

- `assets/images/panduan/hardware_01_esp32.jpg` - ESP32 board
- `assets/images/panduan/hardware_02_rfid_module.jpg` - RFID reader module
- `assets/images/panduan/hardware_03_lcd.jpg` - LCD display
- `assets/images/panduan/hardware_04_assembled.jpg` - Alat terakit lengkap

### Instalasi Hardware

#### Wiring Diagram

```
ESP32          MFRC522 RFID
------         ------------
3.3V     -->   3.3V
GND      -->   GND
GPIO 18  -->   SCK
GPIO 23  -->   MOSI
GPIO 19  -->   MISO
GPIO 5   -->   SDA/SS
GPIO 4   -->   RST

ESP32          LCD 16x2 (I2C)
------         --------------
3.3V     -->   VCC
GND      -->   GND
GPIO 21  -->   SDA
GPIO 22  -->   SCL

ESP32          LED & Buzzer
------         -------------
GPIO 25  -->   LED Hijau (+)
GPIO 26  -->   LED Merah (+)
GPIO 27  -->   Buzzer (+)
GND      -->   LED & Buzzer (-)
```

**📸 Lokasi Screenshot:**

- `assets/images/panduan/wiring_01_diagram.png` - Diagram wiring lengkap
- `assets/images/panduan/wiring_02_esp32_pins.jpg` - ESP32 pinout
- `assets/images/panduan/wiring_03_connection.jpg` - Koneksi kabel

#### Langkah Instalasi

1. **Siapkan Komponen**
   - ESP32 board
   - MFRC522 module
   - LCD 16x2 dengan I2C adapter
   - LED (hijau, merah, biru)
   - Buzzer
   - Kabel jumper
   - Breadboard atau PCB

**📸 Lokasi Screenshot:**

- `assets/images/panduan/install_01_components.jpg` - Komponen yang dibutuhkan

2. **Hubungkan RFID Reader**
   - Ikuti wiring diagram di atas
   - Pastikan koneksi SPI benar
   - Periksa koneksi 3.3V dan GND

**📸 Lokasi Screenshot:**

- `assets/images/panduan/install_02_rfid_connect.jpg` - Koneksi RFID

3. **Hubungkan LCD Display**
   - Hubungkan I2C (SDA, SCL)
   - Set alamat I2C (biasanya 0x27 atau 0x3F)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/install_03_lcd_connect.jpg` - Koneksi LCD

4. **Hubungkan LED dan Buzzer**
   - LED hijau ke GPIO 25
   - LED merah ke GPIO 26
   - Buzzer ke GPIO 27
   - Gunakan resistor 220Ω untuk LED

**📸 Lokasi Screenshot:**

- `assets/images/panduan/install_04_led_buzzer.jpg` - Koneksi LED dan buzzer

5. **Power Supply**
   - Gunakan power supply 5V 2A
   - Atau power bank dengan output stabil
   - Sambungkan ke port USB ESP32

**📸 Lokasi Screenshot:**

- `assets/images/panduan/install_05_power.jpg` - Power supply

### Setup Software

#### Upload Arduino Code

1. **Install Arduino IDE**

   - Download dari arduino.cc
   - Install driver ESP32

2. **Install Library yang Dibutuhkan**
   - MFRC522 (by GithubCommunity)
   - LiquidCrystal_I2C
   - WiFi (built-in ESP32)
   - FirebaseESP32 (by Mobizt)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/software_01_arduino_ide.png` - Arduino IDE
- `assets/images/panduan/software_02_library.png` - Install library

3. **Konfigurasi WiFi**
   - Buka file: `iot/rfid_device_code.ino`
   - Edit baris:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```

**📸 Lokasi Screenshot:**

- `assets/images/panduan/software_03_config_wifi.png` - Konfigurasi WiFi

4. **Konfigurasi Firebase**
   - Edit Firebase URL dan Auth
   ```cpp
   #define FIREBASE_HOST "your-project.firebaseio.com"
   #define FIREBASE_AUTH "your-database-secret"
   ```

**📸 Lokasi Screenshot:**

- `assets/images/panduan/software_04_config_firebase.png` - Konfigurasi Firebase

5. **Upload Code**
   - Hubungkan ESP32 ke komputer via USB
   - Pilih Board: "ESP32 Dev Module"
   - Pilih Port yang sesuai
   - Klik Upload (→)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/software_05_upload.png` - Upload code
- `assets/images/panduan/software_06_success.png` - Upload sukses

### Penggunaan Alat

#### Status Indikator

| LCD Display             | LED                   | Buzzer  | Arti                   |
| ----------------------- | --------------------- | ------- | ---------------------- |
| "RFID Scanner Ready"    | Biru berkedip         | -       | Standby, siap scan     |
| "Tempelkan Kartu"       | Biru menyala          | -       | Menunggu kartu         |
| "Sukses! [Nama]"        | Hijau menyala 2 detik | Beep 1x | Presensi sukses        |
| "Kartu Tidak Terdaftar" | Merah berkedip        | Beep 2x | Kartu tidak dikenal    |
| "Connecting WiFi..."    | Kuning berkedip       | -       | Connecting ke WiFi     |
| "Error Server"          | Merah menyala         | Beep 3x | Error koneksi Firebase |

**📸 Lokasi Screenshot:**

- `assets/images/panduan/status_01_ready.jpg` - Status ready
- `assets/images/panduan/status_02_success.jpg` - Scan sukses
- `assets/images/panduan/status_03_error.jpg` - Scan gagal

#### Cara Penggunaan untuk Santri

1. **Lihat Status LCD**

   - Pastikan LCD menampilkan "Ready" atau "Tempelkan Kartu"
   - LED biru menyala/berkedip

2. **Tempelkan Kartu RFID**
   - Dekatkan kartu 1-5 cm dari reader
   - Posisi kartu sejajar dengan reader
   - Tahan 1-2 detik

**📸 Lokasi Screenshot:**

- `assets/images/panduan/usage_01_position.jpg` - Posisi kartu yang benar
- `assets/images/panduan/usage_02_distance.jpg` - Jarak ideal

3. **Tunggu Konfirmasi**

   - **Sukses**: LED hijau + beep 1x + LCD tampil nama
   - **Gagal**: LED merah + beep 2x + LCD tampil error

4. **Lihat di Aplikasi**
   - Buka aplikasi SiSantri
   - Presensi akan muncul dalam 1-2 detik
   - Notifikasi push akan diterima

### Troubleshooting Alat

#### Kartu Tidak Terbaca

**Gejala**: Kartu ditempelkan tapi tidak ada respons

**Solusi**:

1. Pastikan jarak kartu 1-5 cm dari reader
2. Coba ubah posisi/orientasi kartu
3. Pastikan kartu adalah RFID 13.56 MHz (Mifare/NTAG)
4. Bersihkan permukaan kartu dan reader
5. Restart alat (cabut-colok power)

**📸 Lokasi Screenshot:**

- `assets/images/panduan/troubleshoot_01_card_position.jpg` - Posisi kartu alternatif

#### "Kartu Tidak Terdaftar"

**Gejala**: Kartu terbaca tapi LCD tampil "Tidak Terdaftar"

**Solusi**:

1. Kartu belum didaftarkan ke sistem
2. Hubungi admin untuk registrasi kartu
3. Admin akan gunakan fitur "Daftarkan RFID" di aplikasi

#### LED Merah Terus Menyala

**Gejala**: LED merah menyala terus, LCD blank/error

**Solusi**:

1. Cek koneksi kabel RFID reader
2. Cek power supply (minimal 5V 2A)
3. Restart alat
4. Cek wiring sesuai diagram

**📸 Lokasi Screenshot:**

- `assets/images/panduan/troubleshoot_02_wiring_check.jpg` - Cek wiring

#### "Connecting WiFi..." Terus

**Gejala**: LCD stuck di "Connecting WiFi..."

**Solusi**:

1. Pastikan WiFi aktif dan sinyal kuat
2. Cek kredensial WiFi di code benar
3. Restart router WiFi
4. Restart alat
5. Upload ulang code dengan SSID/password benar

#### "Error Server"

**Gejala**: Kartu terbaca, tapi LCD tampil "Error Server"

**Solusi**:

1. Cek koneksi internet WiFi
2. Cek Firebase configuration benar
3. Cek Firebase database rules (harus allow write)
4. Restart alat
5. Hubungi admin sistem

### Maintenance Rutin

#### Pembersihan Alat

- **Mingguan**:

  - Bersihkan permukaan RFID reader dengan kain lembut
  - Bersihkan LCD dari debu
  - Periksa LED berfungsi normal

- **Bulanan**:
  - Periksa semua koneksi kabel
  - Periksa solder joints (jika pakai PCB)
  - Test scan dengan multiple kartu
  - Update firmware jika ada versi baru

**📸 Lokasi Screenshot:**

- `assets/images/panduan/maintenance_01_cleaning.jpg` - Pembersihan alat

#### Monitoring Performa

Admin dapat monitoring dari aplikasi:

- Total scan per hari
- Success rate
- Error rate
- Uptime device

**📸 Lokasi Screenshot:**

- `assets/images/panduan/maintenance_02_monitoring.png` - Dashboard monitoring

---

## ❓ FAQ & Troubleshooting

### Pertanyaan Umum

#### Q: Bagaimana cara mendapatkan kartu RFID?

**A**: Hubungi admin pondok. Admin akan memberikan kartu dan mendaftarkannya ke sistem Anda.

#### Q: Apakah bisa pakai smartphone untuk presensi (tanpa kartu RFID)?

**A**: Saat ini sistem dirancang untuk RFID only. Namun admin dapat melakukan presensi manual jika diperlukan.

#### Q: Berapa poin yang didapat dari presensi?

**A**:

- Hadir tepat waktu: +10 poin
- Terlambat: +5 poin
- Izin/Sakit: +5 poin
- Bonus streak 7 hari: +20 poin
- Bonus streak 30 hari: +100 poin

#### Q: Bagaimana cara naik level?

**A**: Kumpulkan poin dari presensi dan kegiatan. Setiap level memiliki threshold poin tertentu (lihat tabel level system).

#### Q: Apakah poin bisa berkurang?

**A**: Tidak. Poin hanya bertambah, tidak pernah berkurang. Tapi streak bisa reset jika tidak hadir berturut-turut.

#### Q: Bagaimana jika lupa membawa kartu RFID?

**A**: Hubungi admin atau dewan guru untuk melakukan presensi manual.

#### Q: Apakah bisa ganti foto profil?

**A**: Ya. Masuk ke menu Profil > Tap foto profil > Pilih foto baru dari kamera/galeri.

#### Q: Bagaimana cara reset password?

**A**: Gunakan fitur "Forgot Password" di halaman login, atau hubungi admin.

#### Q: Apakah data presensi aman?

**A**: Ya. Semua data tersimpan di Firebase dengan enkripsi dan authentication. Hanya user authorized yang bisa akses.

### Troubleshooting Aplikasi

#### Aplikasi Force Close / Crash

**Solusi**:

1. Restart aplikasi
2. Clear cache aplikasi (Settings > Apps > SiSantri > Storage > Clear Cache)
3. Pastikan aplikasi versi terbaru
4. Reinstall aplikasi jika masih crash
5. Hubungi admin jika masih bermasalah

#### Tidak Bisa Login

**Solusi**:

1. Pastikan koneksi internet aktif
2. Pastikan menggunakan email Google yang sudah terdaftar
3. Coba logout dari Google account lalu login ulang
4. Clear data aplikasi dan login ulang
5. Hubungi admin jika muncul error "Pengguna tidak terdaftar"

#### Presensi Tidak Muncul di Aplikasi

**Solusi**:

1. Tunggu 5-10 detik, refresh dengan swipe down
2. Pastikan koneksi internet stabil
3. Logout dan login ulang
4. Cek di menu Profil > Riwayat Presensi
5. Jika tetap tidak muncul, hubungi admin

#### Notifikasi Tidak Masuk

**Solusi**:

1. Pastikan notifikasi diizinkan di Settings HP
2. Settings > Apps > SiSantri > Notifications > Allow all
3. Pastikan mode "Do Not Disturb" tidak aktif
4. Logout dan login ulang
5. Reinstall aplikasi

#### Data Tidak Sync / Loading Terus

**Solusi**:

1. Pastikan koneksi internet stabil
2. Coba pindah dari WiFi ke data seluler atau sebaliknya
3. Restart aplikasi
4. Clear cache aplikasi
5. Hubungi admin jika Firebase bermasalah

### Troubleshooting RFID

#### Kartu Tidak Terdaftar

**Solusi**:

1. Kartu memang belum didaftarkan ke akun Anda
2. Hubungi admin untuk registrasi kartu
3. Admin akan gunakan fitur "Daftarkan RFID"
4. Tempelkan kartu saat diminta
5. Tunggu konfirmasi sukses

#### Kartu Sudah Didaftarkan di Akun Lain

**Solusi**:

1. Setiap kartu hanya bisa didaftarkan ke 1 akun
2. Hubungi admin untuk cek siapa pemilik kartu saat ini
3. Admin akan remove RFID dari akun lain
4. Daftarkan ulang ke akun Anda

#### Alat RFID Offline

**Solusi**:

1. Cek apakah alat menyala (LED berkedip)
2. Cek WiFi aktif dan sinyal kuat
3. Hubungi admin untuk restart alat
4. Gunakan alat RFID di lokasi lain
5. Atau minta presensi manual ke admin

---

## 📞 Kontak & Dukungan

### Tim Support

#### Admin Sistem

- **Nama**: [Nama Admin]
- **WhatsApp**: [Nomor WA]
- **Email**: admin@sisantri.id
- **Jam Kerja**: 08:00 - 17:00 WIB

#### Support Teknis

- **WhatsApp**: [Nomor WA Support]
- **Email**: support@sisantri.id
- **Telegram**: @sisantri_support

### Jam Operasional Support

| Hari          | Jam               |
| ------------- | ----------------- |
| Senin - Jumat | 08:00 - 20:00 WIB |
| Sabtu         | 08:00 - 15:00 WIB |
| Minggu        | 13:00 - 17:00 WIB |

### Cara Melaporkan Masalah

1. **Via WhatsApp**:

   - Kirim screenshot error (jika ada)
   - Jelaskan masalah secara detail
   - Sebutkan kapan masalah terjadi
   - Cantumkan nama dan NIM Anda

2. **Via Email**:

   - Subject: [URGENT] atau [BUG] atau [QUESTION]
   - Lampirkan screenshot
   - Jelaskan langkah-langkah yang sudah dicoba

3. **Via Aplikasi**:
   - Menu Profil > Bantuan > Laporkan Masalah
   - Isi form keluhan
   - Kirim

### Update & Maintenance

#### Update Aplikasi

- Aplikasi akan auto-check update saat dibuka
- Jika ada update, akan muncul notifikasi
- Download dan install update terbaru
- Atau download manual dari link yang diberikan admin

#### Jadwal Maintenance

- **Maintenance Rutin**: Setiap Sabtu malam 23:00 - 01:00 WIB
- **Emergency Maintenance**: Akan diinfokan via pengumuman
- Selama maintenance, aplikasi mungkin tidak bisa diakses

### Saran & Feedback

Kami sangat menghargai saran dan feedback Anda:

- **Form Feedback**: Menu Profil > Kirim Feedback
- **Email**: feedback@sisantri.id
- **WhatsApp**: [Nomor WA]

---

## 📄 Lampiran

### Glosarium

| Istilah         | Definisi                                                                                  |
| --------------- | ----------------------------------------------------------------------------------------- |
| **RFID**        | Radio-Frequency Identification - teknologi untuk identifikasi menggunakan gelombang radio |
| **UID**         | Unique Identifier - nomor unik setiap kartu RFID                                          |
| **Scanner**     | Alat pembaca kartu RFID                                                                   |
| **Presensi**    | Kehadiran dalam kegiatan                                                                  |
| **Streak**      | Jumlah hari berturut-turut hadir                                                          |
| **Level Badge** | Badge yang menunjukkan level santri                                                       |
| **Leaderboard** | Papan peringkat santri berdasarkan poin                                                   |
| **Dashboard**   | Halaman utama aplikasi                                                                    |
| **Firebase**    | Platform backend untuk database dan authentication                                        |
| **ESP32**       | Microcontroller untuk IoT device                                                          |
| **LCD**         | Layar display di alat RFID                                                                |

### Versi Dokumen

- **Versi 1.0.0** - Desember 2025 - Dokumen awal
- Update akan dilakukan berkala sesuai fitur baru

### Copyright & Lisensi

© 2025 SiSantri - Pondok Pesantren Mahasiswa Al-Awwabin Sukarame, Bandar Lampung  
Dokumen ini untuk penggunaan internal pondok pesantren.

---

## 📝 Catatan Penting

### Keamanan & Privasi

1. **Jangan bagikan kredensial login** ke orang lain
2. **Logout setelah selesai** menggunakan aplikasi di perangkat publik
3. **Jaga kartu RFID** dengan baik, jangan hilang atau dipinjamkan
4. **Segera lapor ke admin** jika kartu hilang atau dicuri
5. **Ganti password secara berkala** (minimal 3 bulan sekali)

### Etika Penggunaan

1. Gunakan aplikasi sesuai tujuan (presensi dan pembelajaran)
2. Tidak menyalahgunakan sistem poin atau leaderboard
3. Tidak melakukan presensi untuk orang lain (titip absen)
4. Lapor kepada admin jika menemukan bug atau celah keamanan
5. Hormati privasi pengguna lain

### Tips & Trik

1. **Aktifkan Notifikasi** untuk mendapat reminder kegiatan
2. **Cek Dashboard setiap hari** untuk pantau progress
3. **Target Streak** untuk bonus poin besar
4. **Baca Pengumuman** secara rutin
5. **Update Aplikasi** agar mendapat fitur terbaru

---

**Terima kasih telah menggunakan SiSantri!**  
Semoga aplikasi ini membantu meningkatkan produktivitas dan kedisiplinan santri.

**Barakallahu fiikum** 🌙

---

_Dokumen ini dibuat dengan ❤️ untuk Pondok Pesantren Al-Awwabin_
