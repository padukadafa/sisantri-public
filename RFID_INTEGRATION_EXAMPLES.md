# RFID Scanner Integration Examples

## 1. Integration dalam User Management (Admin)

File sudah diupdate: `/lib/features/admin/user_management/presentation/widgets/rfid_management_dialog.dart`

### Cara Penggunaan

```dart
// Di user_list_page.dart atau tempat lain
final result = await showDialog(
  context: context,
  builder: (context) => RfidManagementDialog(user: selectedUser),
);

if (result == true) {
  // RFID berhasil diupdate, refresh data user
  ref.refresh(userListProvider);
}
```

## 2. Integration dalam Profile Page (Santri)

### Tambahkan Button Register RFID

```dart
// Di profile_page.dart, dalam _buildMenuItems
Widget _buildMenuItems(BuildContext context, WidgetRef ref, UserModel user) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    ),
    child: Column(
      children: [
        // Menu lain...
        _buildMenuItem(
          icon: Icons.contactless,
          title: user.hasRfidSetup ? 'Ganti Kartu RFID' : 'Daftarkan Kartu RFID',
          subtitle: user.hasRfidSetup
            ? 'Kartu: ${user.rfidCardId}'
            : 'Belum ada kartu terdaftar',
          onTap: () => _registerRfidCard(context, user, ref),
        ),
        // Menu lain...
      ],
    ),
  );
}

Future<void> _registerRfidCard(
  BuildContext context,
  UserModel user,
  WidgetRef ref,
) async {
  await showRfidScanDialog(
    context: context,
    userId: user.id,
    userName: user.nama,
    onSuccess: (rfidCardId) {
      // Update user data
      FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'rfidCardId': rfidCardId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh profile
      ref.invalidate(userProfileProvider);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kartu RFID $rfidCardId berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    },
  );
}

ListTile _buildMenuItem({
  required IconData icon,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF10B981)),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: subtitle != null ? Text(subtitle) : null,
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
```

## 3. Integration dalam Attendance/Presensi Page

### Quick RFID Registration saat Presensi Manual

```dart
// Di manual_attendance_page.dart
class _ManualAttendancePageState extends State<ManualAttendancePage> {
  // ... state lain

  Future<void> _quickRegisterRfid(UserModel user) async {
    await showRfidScanDialog(
      context: context,
      userId: user.id,
      userName: user.nama,
      onSuccess: (rfidCardId) {
        // Auto-update user data
        FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'rfidCardId': rfidCardId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('RFID $rfidCardId berhasil didaftarkan untuk ${user.nama}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  // Di dalam build method, tambahkan icon button di list item user
  Widget _buildUserListItem(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.nama[0].toUpperCase()),
      ),
      title: Text(user.nama),
      subtitle: Text(
        user.hasRfidSetup ? 'RFID: ${user.rfidCardId}' : 'Belum ada RFID',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!user.hasRfidSetup)
            IconButton(
              icon: const Icon(Icons.contactless, color: Colors.blue),
              tooltip: 'Register RFID',
              onPressed: () => _quickRegisterRfid(user),
            ),
          // Button presensi lain...
        ],
      ),
    );
  }
}
```

## 4. Integration dalam Settings Page

### RFID Management Settings

```dart
// Di security_settings_page.dart atau settings_page.dart
class SecuritySettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Keamanan')),
      body: userProfile.when(
        data: (user) {
          if (user == null) return const SizedBox();

          return ListView(
            children: [
              // Section RFID
              const ListTile(
                title: Text(
                  'Kartu RFID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  user.hasRfidSetup ? Icons.contactless : Icons.contactless_outlined,
                  color: user.hasRfidSetup ? Colors.green : Colors.grey,
                ),
                title: Text(user.hasRfidSetup ? 'Kartu Terdaftar' : 'Belum Ada Kartu'),
                subtitle: user.hasRfidSetup
                    ? Text('ID: ${user.rfidCardId}')
                    : const Text('Daftarkan kartu untuk presensi otomatis'),
                trailing: Icon(
                  user.hasRfidSetup ? Icons.edit : Icons.add,
                ),
                onTap: () => _manageRfidCard(context, user, ref),
              ),
              const Divider(),

              // Settings lain...
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _manageRfidCard(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) async {
    if (user.hasRfidSetup) {
      // Show options: Update atau Hapus
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kelola Kartu RFID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Ganti Kartu'),
                onTap: () => Navigator.pop(context, 'update'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Kartu'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      );

      if (action == 'update' && context.mounted) {
        await _scanNewCard(context, user, ref);
      } else if (action == 'delete' && context.mounted) {
        await _deleteCard(context, user, ref);
      }
    } else {
      // Langsung scan
      await _scanNewCard(context, user, ref);
    }
  }

  Future<void> _scanNewCard(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) async {
    await showRfidScanDialog(
      context: context,
      userId: user.id,
      userName: user.nama,
      onSuccess: (rfidCardId) {
        FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'rfidCardId': rfidCardId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ref.invalidate(userProfileProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kartu RFID $rfidCardId berhasil didaftarkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteCard(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kartu RFID'),
        content: const Text('Yakin ingin menghapus kartu RFID? Anda tidak akan bisa presensi otomatis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'rfidCardId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ref.invalidate(userProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartu RFID berhasil dihapus'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
```

## 5. Standalone Usage (Anywhere)

```dart
import 'package:sisantri/shared/widgets/rfid_scan_dialog.dart';

// Cara paling sederhana
await showRfidScanDialog(
  context: context,
  userId: 'user_123',
  userName: 'Ahmad Santri',
  onSuccess: (rfidCardId) {
    print('RFID Card ID: $rfidCardId');
    // Do something with the RFID card ID
  },
);
```

## Import yang Diperlukan

```dart
import 'package:sisantri/shared/widgets/rfid_scan_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
```

## Keuntungan Sistem Ini

1. ✅ **Tidak perlu NFC** - Semua device bisa digunakan
2. ✅ **Centralized** - Satu scanner untuk semua user
3. ✅ **Real-time** - Update langsung via Firestore Stream
4. ✅ **User-friendly** - Visual feedback yang jelas
5. ✅ **Secure** - Validasi duplicate card ID
6. ✅ **Flexible** - Bisa digunakan di mana saja dalam aplikasi

## Catatan Penting

- Pastikan scanner device sudah running dan monitoring `rfid_scan_config` collection
- Request akan auto-cleanup setelah 5 menit jika tidak ada response dari scanner
- User bisa cancel request kapan saja
- Duplicate RFID card ID akan langsung terdeteksi dan ditolak
