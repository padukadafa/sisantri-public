// // CONTOH INTEGRASI FITUR PENGINGAT SHOLAT DAN JADWAL

// // ========================================
// // 1. Di Santri Dashboard Page
// // ========================================
// import 'package:sisantri/features/santri/dashboard/presentation/widgets/prayer_times_widget.dart';

// // Contoh implementasi di dashboard_page.dart
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: SingleChildScrollView(
//       child: Column(
//         children: [
//           // ... existing widgets ...
          
//           // Tambahkan Widget Waktu Sholat Berikutnya
//           const NextPrayerCard(),
//           const SizedBox(height: 16),
          
//           // Tambahkan Widget Jadwal Sholat Hari Ini
//           const PrayerTimesCard(),
//           const SizedBox(height: 16),
          
//           // ... existing widgets ...
//         ],
//       ),
//     ),
//   );
// }


// // ========================================
// // 2. Menambahkan Menu Settings di Profile
// // ========================================
// import 'package:sisantri/features/santri/profile/presentation/pages/reminder_settings_page.dart';

// // Contoh implementasi di profile_page.dart
// ListTile(
//   leading: const Icon(Icons.notifications),
//   title: const Text('Pengaturan Pengingat'),
//   subtitle: const Text('Atur pengingat sholat dan jadwal'),
//   trailing: const Icon(Icons.chevron_right),
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const ReminderSettingsPage(),
//       ),
//     );
//   },
// ),


// // ========================================
// // 3. Refresh Reminders Setelah Update Jadwal
// // ========================================
// import 'package:sisantri/shared/services/reminder_service.dart';

// // Di admin jadwal management, setelah add/update/delete jadwal
// Future<void> _saveJadwal() async {
//   // ... save jadwal to Firestore ...
  
//   // Refresh reminders untuk semua user
//   await ReminderService.refreshReminders();
  
//   if (mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('✅ Jadwal disimpan dan pengingat diperbarui'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
// }


// // ========================================
// // 4. Manual Control (Optional)
// // ========================================

// // Enable/disable prayer reminder
// await ReminderService.setPrayerReminderEnabled(true);

// // Set reminder time (5, 10, 15, or 30 minutes before)
// await ReminderService.setPrayerReminderMinutes(10);

// // Enable/disable schedule reminder
// await ReminderService.setScheduleReminderEnabled(true);

// // Set schedule reminder time
// await ReminderService.setScheduleReminderMinutes(15);

// // Check status
// final isPrayerEnabled = await ReminderService.isPrayerReminderEnabled();
// final minutes = await ReminderService.getPrayerReminderMinutes();

// // Manual refresh (jika diperlukan)
// await ReminderService.refreshReminders();


// // ========================================
// // 5. Get Prayer Times Information
// // ========================================
// import 'package:sisantri/shared/services/prayer_times_service.dart';

// // Get next prayer time
// final nextPrayer = PrayerTimesService.getNextPrayerTime();
// if (nextPrayer != null) {
//   final prayerName = nextPrayer['name'] as String;
//   final prayerTime = nextPrayer['time'] as DateTime;
//   print('Next prayer: $prayerName at $prayerTime');
// }

// // Get all prayer times for today
// final prayerTimes = PrayerTimesService.getTodayPrayerTimes();
// prayerTimes.forEach((name, time) {
//   print('$name: ${PrayerTimesService.formatPrayerTime(time)}');
// });

// // Check if it's prayer time now
// final currentPrayer = PrayerTimesService.getCurrentPrayerTime();
// if (currentPrayer != null) {
//   print('It\'s ${currentPrayer['name']} time now!');
// }


// // ========================================
// // 6. Custom Prayer Times (Admin Panel - Future)
// // ========================================

// // Di admin panel, bisa menambahkan fitur untuk update waktu sholat
// // Simpan di Firestore collection 'prayer_times'
// // Lalu update PrayerTimesService untuk fetch dari Firestore

// // Example structure in Firestore:
// /*
// prayer_times/config {
//   subuh: "04:30",
//   dzuhur: "12:00",
//   ashar: "15:15",
//   maghrib: "18:00",
//   isya: "19:15",
//   timezone: "Asia/Jakarta",
//   lastUpdated: Timestamp
// }
// */


// // ========================================
// // 7. Testing Notifications
// // ========================================

// // Test immediate notification
// import 'package:sisantri/shared/services/notification_service.dart';

// await NotificationService.showKegiatanReminder(
//   title: '🕌 Test Pengingat Sholat',
//   body: 'Ini adalah notifikasi test',
//   scheduledTime: DateTime.now(),
// );


// // ========================================
// // 8. Background Task (Already Integrated)
// // ========================================

// // ReminderLifecycleManager sudah wrap MaterialApp di main.dart
// // Ini akan otomatis:
// // - Refresh reminders setiap tengah malam
// // - Refresh reminders saat app di-resume
// // - Handle app lifecycle changes

// // main.dart sudah correct:
// /*
// class SiSantriApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ReminderLifecycleManager(
//       child: MaterialApp(
//         // ...
//       ),
//     );
//   }
// }
// */


// // ========================================
// // 9. Permissions Check (Optional UI)
// // ========================================

// import 'package:permission_handler/permission_handler.dart';

// // Check notification permission
// Future<bool> checkNotificationPermission() async {
//   final status = await Permission.notification.status;
//   if (!status.isGranted) {
//     final result = await Permission.notification.request();
//     return result.isGranted;
//   }
//   return true;
// }

// // Di onboarding atau settings page
// if (!await checkNotificationPermission()) {
//   // Show dialog to explain why permission is needed
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Izin Notifikasi Diperlukan'),
//       content: const Text(
//         'Untuk menerima pengingat sholat dan jadwal, '
//         'mohon aktifkan izin notifikasi.',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             openAppSettings();
//           },
//           child: const Text('Buka Pengaturan'),
//         ),
//       ],
//     ),
//   );
// }


// // ========================================
// // 10. Error Handling
// // ========================================

// try {
//   await ReminderService.refreshReminders();
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('✅ Pengingat berhasil diperbarui'),
//       backgroundColor: Colors.green,
//     ),
//   );
// } catch (e) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text('❌ Gagal memperbarui pengingat: $e'),
//       backgroundColor: Colors.red,
//     ),
//   );
// }
