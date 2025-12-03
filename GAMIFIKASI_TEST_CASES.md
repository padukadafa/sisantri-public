# Test Cases - Fitur Gamifikasi

## Daftar Test Case

| No | Id | Test Case | Langkah | Expected Result | Severity | Actual Result | Status | Platform |
|----|----|-----------|---------|-----------------|-----------| --------------|--------|----------|
| 1 | AGM001 | Cek Total Poin | 1. Login sebagai santri<br>2. Lihat widget poin di Home | Jumlah poin sinkron dengan data presensi terakhir dari aggregate yearly | High | - | Pending | Aplikasi |
| 2 | AGM002 | Update Poin Setelah Presensi Hadir | 1. Login sebagai santri<br>2. Lihat total poin awal<br>3. Scan RFID untuk presensi hadir<br>4. Refresh halaman home | Poin bertambah sesuai nilai poin jadwal | High | - | Pending | Aplikasi |
| 3 | AGM003 | Poin Tidak Bertambah Saat Alpha | 1. Login sebagai santri<br>2. Lihat total poin awal<br>3. Admin tandai sebagai alpha<br>4. Refresh halaman home | Poin tidak bertambah | Medium | - | Pending | Aplikasi |
| 4 | AGM004 | Poin Tidak Bertambah Saat Izin | 1. Login sebagai santri<br>2. Lihat total poin awal<br>3. Admin tandai sebagai izin<br>4. Refresh halaman home | Poin tidak bertambah | Medium | - | Pending | Aplikasi |
| 5 | AGM005 | Poin Tidak Bertambah Saat Sakit | 1. Login sebagai santri<br>2. Lihat total poin awal<br>3. Admin tandai sebagai sakit<br>4. Refresh halaman home | Poin tidak bertambah | Medium | - | Pending | Aplikasi |
| 6 | AGM006 | Statistik Mingguan | 1. Login sebagai santri<br>2. Buka halaman Profile<br>3. Lihat tab Statistik<br>4. Cek data mingguan | Menampilkan total hadir, izin, sakit, alpha, dan poin untuk minggu ini | Medium | - | Pending | Aplikasi |
| 7 | AGM007 | Statistik Bulanan | 1. Login sebagai santri<br>2. Buka halaman Profile<br>3. Lihat tab Statistik<br>4. Cek data bulanan | Menampilkan total hadir, izin, sakit, alpha, dan poin untuk bulan ini | Medium | - | Pending | Aplikasi |
| 8 | AGM008 | Statistik Semester | 1. Login sebagai santri<br>2. Buka halaman Profile<br>3. Lihat tab Statistik<br>4. Cek data semester | Menampilkan total hadir, izin, sakit, alpha, dan poin untuk semester ini | Medium | - | Pending | Aplikasi |
| 9 | AGM009 | Statistik Tahunan | 1. Login sebagai santri<br>2. Buka halaman Profile<br>3. Lihat tab Statistik<br>4. Cek data tahunan | Menampilkan total hadir, izin, sakit, alpha, dan poin untuk tahun ini | Medium | - | Pending | Aplikasi |
| 10 | AGM010 | Leaderboard Tampil | 1. Login sebagai santri<br>2. Buka halaman Leaderboard | Menampilkan daftar ranking santri berdasarkan poin dari tertinggi | High | - | Pending | Aplikasi |
| 11 | AGM011 | Leaderboard Update Real-time | 1. Login sebagai santri A<br>2. Buka halaman Leaderboard<br>3. Santri B scan presensi<br>4. Pull to refresh leaderboard | Ranking terupdate sesuai perubahan poin | Medium | - | Pending | Aplikasi |
| 12 | AGM012 | Filter Leaderboard Harian | 1. Login sebagai santri<br>2. Buka halaman Leaderboard<br>3. Pilih filter "Hari Ini" | Menampilkan ranking berdasarkan poin hari ini saja | Medium | - | Pending | Aplikasi |
| 13 | AGM013 | Filter Leaderboard Mingguan | 1. Login sebagai santri<br>2. Buka halaman Leaderboard<br>3. Pilih filter "Minggu Ini" | Menampilkan ranking berdasarkan poin minggu ini | Medium | - | Pending | Aplikasi |
| 14 | AGM014 | Filter Leaderboard Bulanan | 1. Login sebagai santri<br>2. Buka halaman Leaderboard<br>3. Pilih filter "Bulan Ini" | Menampilkan ranking berdasarkan poin bulan ini | Medium | - | Pending | Aplikasi |
| 15 | AGM015 | Filter Leaderboard All Time | 1. Login sebagai santri<br>2. Buka halaman Leaderboard<br>3. Pilih filter "Semua" | Menampilkan ranking berdasarkan total poin keseluruhan | Medium | - | Pending | Aplikasi |
| 16 | AGM016 | Admin Lihat Detail User | 1. Login sebagai admin<br>2. Buka User Management<br>3. Pilih salah satu santri<br>4. Lihat tab Statistik | Menampilkan breakdown statistik mingguan, bulanan, semester, dan tahunan | High | - | Pending | Aplikasi |
| 17 | AGM017 | Sinkronisasi Aggregate Harian | 1. Login sebagai admin<br>2. Buat jadwal hari ini<br>3. Tandai santri hadir<br>4. Cek database aggregate daily | Data aggregate daily terupdate dengan increment totalHadir dan totalPoin | High | - | Pending | Backend |
| 18 | AGM018 | Sinkronisasi Aggregate Mingguan | 1. Login sebagai admin<br>2. Buat jadwal minggu ini<br>3. Tandai santri hadir<br>4. Cek database aggregate weekly | Data aggregate weekly terupdate dengan increment totalHadir dan totalPoin | High | - | Pending | Backend |
| 19 | AGM019 | Sinkronisasi Aggregate Bulanan | 1. Login sebagai admin<br>2. Buat jadwal bulan ini<br>3. Tandai santri hadir<br>4. Cek database aggregate monthly | Data aggregate monthly terupdate dengan increment totalHadir dan totalPoin | High | - | Pending | Backend |
| 20 | AGM020 | Sinkronisasi Aggregate Semester | 1. Login sebagai admin<br>2. Buat jadwal semester ini<br>3. Tandai santri hadir<br>4. Cek database aggregate semester | Data aggregate semester terupdate dengan increment totalHadir dan totalPoin | High | - | Pending | Backend |
| 21 | AGM021 | Sinkronisasi Aggregate Tahunan | 1. Login sebagai admin<br>2. Buat jadwal tahun ini<br>3. Tandai santri hadir<br>4. Cek database aggregate yearly | Data aggregate yearly terupdate dengan increment totalHadir dan totalPoin | High | - | Pending | Backend |
| 22 | AGM022 | Update Status Presensi | 1. Login sebagai admin<br>2. Ubah status presensi dari hadir ke izin<br>3. Cek aggregate semua periode | totalHadir berkurang 1, totalIzin bertambah 1, totalPoin berkurang sesuai nilai | High | - | Pending | Backend |
| 23 | AGM023 | Batch Attendance Update Aggregate | 1. Login sebagai admin<br>2. Pilih 10 santri dalam mode batch<br>3. Tandai semua sebagai hadir<br>4. Cek aggregate | Semua aggregate terupdate untuk 10 santri sekaligus | High | - | Pending | Backend |
| 24 | AGM024 | Delete Jadwal Update Aggregate | 1. Login sebagai admin<br>2. Hapus jadwal yang sudah ada presensi<br>3. Cek aggregate semua periode | Aggregate decrement sesuai status dan poin yang dihapus | High | - | Pending | Backend |
| 25 | AGM025 | RFID Scan Update Aggregate | 1. Scan RFID di device<br>2. Cek response API<br>3. Cek database aggregate | Aggregate terupdate untuk semua periode (daily, weekly, monthly, semester, yearly) | High | - | Pending | IoT Backend |
| 26 | AGM026 | Performance 100 User | 1. Jalankan k6 load test dengan 100 VU<br>2. Test endpoint scan selama 5 menit | 95% request < 3s, error rate < 30% | Medium | - | Pending | IoT Backend |
| 27 | AGM027 | Performance 300 User | 1. Jalankan k6 load test dengan 300 VU<br>2. Test endpoint scan selama 10 menit | 95% request < 3s, 99% request < 5s, error rate < 30% | High | - | Pending | IoT Backend |
| 28 | AGM028 | Attendance Report Aggregate | 1. Login sebagai admin<br>2. Buka Attendance Report<br>3. Filter rentang tanggal (1-7 hari)<br>4. Lihat statistik | Report menggunakan aggregate data, loading cepat | High | - | Pending | Aplikasi |
| 29 | AGM029 | Persentase Kehadiran | 1. Login sebagai santri<br>2. Buka tab Statistik di Profile<br>3. Lihat persentase kehadiran | Menampilkan persentase hadir dari total kegiatan yang ada | Medium | - | Pending | Aplikasi |
| 30 | AGM030 | Konsistensi Data Cross-Platform | 1. Tandai presensi via RFID<br>2. Cek poin di aplikasi mobile<br>3. Cek poin via admin web | Poin sama di semua platform | High | - | Pending | All Platform |

## Kategori Test Case

### High Severity (Prioritas Tinggi)
- Test case yang berkaitan dengan core functionality gamifikasi
- Sinkronisasi data aggregate
- Akurasi perhitungan poin
- Performance critical path

### Medium Severity (Prioritas Sedang)
- Filter dan tampilan UI
- Statistik detail
- Performance non-critical

### Low Severity (Prioritas Rendah)
- Nice to have features
- UI polish
- Minor bug fixes

## Status Legend

- **Pending**: Belum ditest
- **In Progress**: Sedang dalam proses testing
- **Done**: Test berhasil sesuai expected result
- **Failed**: Test gagal, ada bug yang harus diperbaiki
- **Blocked**: Test terblokir karena dependency

## Platform Legend

- **Aplikasi**: Flutter mobile app (Android/iOS)
- **Backend**: Firebase Firestore + Cloud Functions
- **IoT Backend**: Node.js Express backend untuk RFID
- **All Platform**: Test cross-platform consistency

## Notes

1. Semua test case gamifikasi menggunakan sistem **aggregate** untuk performa optimal
2. Aggregate periods: `daily`, `weekly`, `monthly`, `semester`, `yearly`
3. Poin hanya bertambah untuk status **hadir**
4. Status lain (izin, sakit, alpha) tidak menambah poin
5. Update status presensi harus update aggregate dengan decrement old status dan increment new status
6. Delete jadwal harus cleanup aggregate data

## Test Environment

- **Development**: Local Firebase Emulator + Local IoT Backend
- **Staging**: Firebase Dev Project + Vercel Staging
- **Production**: Firebase Prod Project + Vercel Production

## Test Data

Gunakan data test berikut:
- **Test User**: santri_test_001@test.com
- **Test RFID**: TEST_RFID_001
- **Test Jadwal**: Kajian Test (5 poin)
- **Test Device**: rfid-reader-test-001
