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

- `assets/images/panduan/instalasi/Screenshot_1765335257.png` - Download APK
- `assets/images/panduan/instalasi/Screenshot_1765335269.png` - Proses instalasi
- `assets/images/panduan/instalasi/Screenshot_1765335275.png` - Aplikasi terinstal

### Login Pertama Kali

#### Langkah Login

1. **Buka Aplikasi SiSantri**
   - Anda akan melihat halaman login
   - Terdapat tombol "Isi email dan password"
   - Klik tombol login

   **📸 Lokasi Screenshot:**
   - `assets/images/panduan/login/Screenshot_1765335607.png` - Halaman login

2. **Izinkan Akses**
   - Aplikasi akan meminta izin notifikasi
   - Tap "Izinkan" atau "Allow"

## 👤 Panduan untuk Santri

### Dashboard Santri

Setelah login, Anda akan melihat **Dashboard Santri** dengan informasi:

#### Welcome Card

- **Level Badge** (misal: 🌱 Santri Pemula)
- Total poin yang dikumpulkan
- Progress bar menuju level berikutnya

#### Statistik Presensi

- Total kehadiran bulan ini
- Persentase kehadiran
- Status presensi hari ini

#### Pengumuman Terbaru

- Pengumuman terbaru terkait pondok pesantren

**📸 Lokasi Screenshot:**

- `assets/images/panduan/dashboard_santri/Screenshot_1765336059.png` - Dashboard

### Presensi dengan Kartu RFID

#### Cara Melakukan Presensi

1. **Persiapkan Kartu RFID**
   - Pastikan Anda sudah memiliki kartu RFID yang terdaftar
   - Kartu berbentuk kartu seperti KTP atau gantungan kunci

2. **Temukan Alat Scanner RFID**
   - Alat scanner berada di:
     - Pintu masuk masjid/aula
     - Ruang kajian
     - Area kegiatan pondok
   - Alat akan menampilkan status "Tempelkan Kartu"

3. **Tempelkan Kartu ke Scanner**
   - Dekatkan kartu RFID ke area scanner (biasanya ada logo 📡)
   - Jarak ideal: 1 cm dari reader
   - Tunggu hingga Tulisan di layar berubah

4. **Lihat Konfirmasi**
   - **Sukses**:
     - LCD menampilkan: "Sukses! [Nama Anda]"
     - Status: "Hadir" atau "Terlambat" (sesuai status)

   - **Gagal**:
     - LCD menampilkan: "Gagal"
     - Status tergantung apa masalahnya

5. **Cek di Aplikasi**
   - Buka aplikasi SiSantri
   - Data presensi akan muncul dalam 1-2 detik
   - Poin otomatis bertambah

   **📸 Screenshot:**
   - `assets/images/panduan/presensi_santri/Screenshot_1765336327.png` - Status Presensi

#### Status Presensi

| Status    | Kondisi                        | Poin    |
| --------- | ------------------------------ | ------- |
| **Hadir** | Scan sebelum waktu mulai       | +1 poin |
| **Izin**  | Sudah mengajukan izin ke admin | 0 poin  |
| **Sakit** | Ada surat/konfirmasi sakit     | 0 poin  |
| **Alpha** | Tidak hadir tanpa keterangan   | 0 poin  |

### Melihat Jadwal

#### Menu Jadwal Pengajian

1. Tap menu **"Jadwal"** di bottom navigation
2. Anda akan melihat daftar jadwal pengajian/kegiatan

**📸 Lokasi Screenshot:**

- `assets/images/panduan/jadwal_santri/Screenshot_1765336396.png` - Daftar jadwal

#### Filter Jadwal

- **Tab Kegiatan**: Jadwal Kegiatan
- **Tab Pengajian**: Jadwal Pengajian
- **Tab Bacaan**: Jadwal Bacaan
- **Tab Tahfidz**: Jadwal Tahfidz

#### Detail Jadwal

Terdapat detail:

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

- `assets/images/panduan/detail_jadwa/Screenshot_1765336518.png` - Detail Jadwal

### Leaderboard & Ranking

#### Melihat Ranking

1. Tap menu **"Ranking"** di bottom navigation
2. Lihat posisi Anda di antara santri lain

**📸 Lokasi Screenshot:**

- `assets/images/panduan/leaderboard/Screenshot_1765339103.png` - Halaman leaderboard

#### Filter Periode

- **Bulanan ini**: Ranking bulan ini
- **Semester ini**: Ranking semester ini
- **Tahunan ini**: Ranking sepanjang tahun

#### Podium Top 3

Top 3 santri ditampilkan dengan podium khusus:

- 🥇 Juara 1: Podium emas dengan badge level
- 🥈 Juara 2: Podium perak dengan badge level
- 🥉 Juara 3: Podium perunggu dengan badge level

#### Daftar Ranking

Semua santri ditampilkan dengan:

- Nomor urut
- Foto profil dengan **Level Badge Overlay**
- Nama lengkap
- **Level Badge** (emoji dan nama level)
- Total poin
- Progress bar level

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

#### Melihat Progress Level

1. Buka **Dashboard** atau **Profil**
2. Lihat **Level Card** yang menampilkan:
   - Badge level saat ini
   - Nama level
   - Total poin Anda
   - Progress bar menuju level berikutnya
   - Poin yang dibutuhkan untuk naik level

### Profil & Pengaturan

#### Melihat Profil

1. Tap menu **"Profil"** di bottom navigation
2. Lihat informasi lengkap profil Anda

**📸 Lokasi Screenshot:**

- `assets/images/panduan/profil/Screenshot_1765339312.png` - Halaman profil

#### Informasi Profil

- **Nama Lengkap**
- **Email**
- **NIM** (jika mahasiswa)
- **Role**: Santri
- **Status**: Aktif/Tidak Aktif
- **Level Badge** lengkap dengan progress
- **Total Poin**
- **RFID Card ID** (jika sudah terdaftar)

#### Edit Profil

1. Tap tombol **"Edit Profil"**
2. Ubah informasi yang bisa diubah:
   - Nama lengkap
   - Nomor HP (opsional)
3. Tap **"Simpan"** untuk menyimpan perubahan

#### Logout

1. Scroll ke bawah di halaman profil
2. Tap tombol **"Logout"** berwarna merah
3. Konfirmasi logout
4. Anda akan kembali ke halaman login

## 👨‍🏫 Panduan untuk Dewan Guru

### Dashboard Dewan Guru

Dashboard dewan guru memiliki akses lebih luas untuk monitoring:

#### Statistik Umum

- Total santri aktif
- Kehadiran hari ini
- Persentase kehadiran rata-rata
- Jadwal hari ini

#### Monitoring Presensi Real-time

1. Lihat **Presensi** di dashboard
2. Daftar santri yang sudah presensi
3. Status presensi (Hadir/Terlambat/Izin/Sakit)
4. Waktu presensi

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

#### Edit Pengguna

1. Tap pengguna yang ingin diedit
2. Tap tombol **"Edit"**
3. Ubah informasi
4. Tap **"Simpan"**

**📸 Lokasi Screenshot:**

- `assets/images/panduan/admin_edit_pengguna/Screenshot_1765339656.png` - Edit pengguna

#### Registrasi Kartu RFID

1. Di detail pengguna, tap **"Daftarkan RFID"**
2. Dialog akan muncul dengan instruksi
3. Pengguna diminta menempelkan kartu ke scanner
4. Scanner akan membaca UID kartu
5. Sistem akan validasi dan menyimpan RFID
6. Konfirmasi sukses akan muncul

**📸 Lokasi Screenshot:**

- `assets/images/panduan/register_rfid/Screenshot_1765339718.png` - register RFID

#### Hapus/Nonaktifkan Pengguna

1. Tap pengguna
2. Tap tombol **"Nonaktifkan"** atau **"Hapus"**
3. Konfirmasi aksi
4. Pengguna akan dinonaktifkan/dihapus

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

5. Tap **"Simpan"**
6. Jadwal akan tersimpan dan muncul di aplikasi

**📸 Screenshot:**

- `assets/images/panduan/tambah_jadwal/Screenshot_1765340089.png` - Daftar jadwal

#### Edit Jadwal

1. Tap jadwal yang ingin diedit
2. Tap tombol **"Edit"**
3. Ubah informasi
4. Tap **"Simpan"**

#### Hapus Jadwal

1. Tap jadwal
2. Tap tombol **"Hapus"**
3. Konfirmasi hapus
4. Jadwal akan dihapus

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

- `assets/images/panduan/manajemen_materi/Screenshot_1765340146.png` - Daftar materi kajian
- `assets/images/panduan/manajemen_materi/Screenshot_1765340147.png` - Form tambah materi

#### Badge Jenis Materi

Setiap materi memiliki badge dan icon sesuai jenisnya:

- **📖 Quran** - Badge hijau
- **📚 Hadist** - Badge biru
- **📕 Lainnya** - Badge orange

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

- `assets/images/panduan/manajemen_pengumuman/Screenshot_1765340199.png` - Daftar pengumuman
- `assets/images/panduan/manajemen_pengumuman/Screenshot_1765340201.png` - Form buat pengumuman

#### Edit/Hapus Pengumuman

1. Tap pengumuman yang ingin diubah
2. Tap tombol **"Edit"** atau **"Hapus"**
3. Ubah dan simpan, atau konfirmasi hapus

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

**📸 Screenshot:**

- `assets/images/panduan/presensi_manual/Screenshot_1765340275.png` - Form presensi manual

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

- `assets/images/panduan/laporan_presensi/Screenshot_1765340342.png` - Menu laporan

#### Format Laporan Excel

Laporan akan berisi:

- Header: Nama pondok, periode, tanggal generate
- Tabel data dengan kolom:
  - No, Nama, NIM, Tanggal, Kegiatan, Status, Poin, dll
- Summary: Total hadir, izin, sakit, alpha, persentase
- Footer: Tanda tangan digital dan cap

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

3. **Konfigurasi WiFi**
   - Buka file: `iot/rfid_device_code.ino`
   - Edit baris:

   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```

4. **Konfigurasi Firebase**
   - Edit Firebase URL dan Auth

   ```cpp
   #define FIREBASE_HOST "your-project.firebaseio.com"
   #define FIREBASE_AUTH "your-database-secret"
   ```

5. **Upload Code**
   - Hubungkan ESP32 ke komputer via USB
   - Pilih Board: "ESP32 Dev Module"
   - Pilih Port yang sesuai
   - Klik Upload (→)

### Penggunaan Alat

#### Cara Penggunaan untuk Santri

1. **Lihat Status LCD**
   - Pastikan LCD menampilkan "Ready" atau "Tempelkan Kartu"
   - LED biru menyala/berkedip

2. **Tempelkan Kartu RFID**
   - Dekatkan kartu 1 cm dari reader
   - Posisi kartu sejajar dengan reader
   - Tahan 500 mili detik

3. **Tunggu Konfirmasi**
   - **Sukses**: LCD tampil sukses
   - **Gagal**: LCD tampil error

4. **Lihat di Aplikasi**
   - Buka aplikasi SiSantri
   - Presensi akan muncul dalam 1-2 detik
   - Notifikasi push akan diterima

### Troubleshooting Alat

#### Kartu Tidak Terbaca

**Gejala**: Kartu ditempelkan tapi tidak ada respons

**Solusi**:

1. Pastikan jarak kartu maksimal 1 cm dari reader
2. Coba ubah posisi/orientasi kartu
3. Pastikan kartu adalah RFID 13.56 MHz (Mifare/NTAG)
4. Bersihkan permukaan kartu dan reader
5. Restart alat (cabut-colok power)

#### "Kartu Tidak Terdaftar"

**Gejala**: Kartu terbaca tapi LCD tampil "Tidak Terdaftar"

**Solusi**:

1. Kartu belum didaftarkan ke sistem
2. Hubungi admin untuk registrasi kartu
3. Admin akan gunakan fitur "Daftarkan RFID" di aplikasi

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
  - Periksa solder joints
  - Test scan dengan multiple kartu
  - Update firmware jika ada versi baru
