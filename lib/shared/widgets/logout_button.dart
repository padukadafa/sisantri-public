import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/auth_service.dart';
import '../helpers/messaging_helper.dart';

// Provider imports - diperlukan untuk invalidation
import '../../features/santri/profile/presentation/pages/profile_page.dart';
import '../../features/santri/dashboard/presentation/providers/dashboard_providers.dart';
import '../../core/routing/role_based_navigation.dart';
import '../../features/dewan_guru/navigation/dewan_guru_navigation.dart';
import '../providers/materi_provider.dart';
import '../providers/progress_provider.dart';

/// Widget tombol logout yang dapat ditempatkan di mana saja
class LogoutButton extends ConsumerWidget {
  final VoidCallback? onLogoutSuccess;
  final bool showLabel;
  final IconData icon;
  final Color? color;

  const LogoutButton({
    super.key,
    this.onLogoutSuccess,
    this.showLabel = true,
    this.icon = Icons.logout,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return showLabel
        ? _buildButtonWithLabel(context, ref)
        : _buildIconButton(context, ref);
  }

  Widget _buildButtonWithLabel(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showLogoutDialog(context, ref),
      icon: Icon(icon, size: 18),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? Colors.red).withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.red).withAlpha(50),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => _showLogoutDialog(context, ref),
        icon: Icon(icon, color: color ?? Colors.red, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(50), width: 1),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anda perlu login kembali untuk mengakses aplikasi.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    // Show loading dengan EasyLoading
    EasyLoading.show(
      status: 'Sedang logout...',
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );

    try {
      await Future.any([
        _performLogoutSteps(ref),
        Future.delayed(const Duration(seconds: 8), () {
          throw Exception('Logout timeout - operasi terlalu lama');
        }),
      ]);

      if (onLogoutSuccess != null) {
        onLogoutSuccess!();
      }

      // Dismiss loading dan show success
      EasyLoading.dismiss();
      if (context.mounted) {
        EasyLoading.showSuccess(
          'Berhasil logout',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      try {
        await AuthService.signOut();
        // Clear all Riverpod cache
        _invalidateAllProviders(ref);
      } catch (_) {}

      // Dismiss loading dan show success
      EasyLoading.dismiss();
      if (context.mounted) {
        EasyLoading.showSuccess(
          'Logout berhasil',
          duration: const Duration(seconds: 2),
        );
      }

      if (onLogoutSuccess != null) {
        onLogoutSuccess!();
      }
    }
  }

  Future<void> _performLogoutSteps(WidgetRef ref) async {
    try {
      // Step 1: Cleanup messaging
      await Future.any([
        _cleanupMessagingWithTimeout(),
        Future.delayed(const Duration(seconds: 2)),
      ]).catchError((_) {});

      // Step 2: Sign out
      await Future.any([
        _signOutWithTimeout(),
        Future.delayed(const Duration(seconds: 5)),
      ]);

      // Step 3: Clear all Riverpod providers cache
      _invalidateAllProviders(ref);
    } catch (e) {
      try {
        await AuthService.signOut();
        _invalidateAllProviders(ref);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _cleanupMessagingWithTimeout() async {
    try {
      await MessagingHelper.unsubscribeFromAllTopics();
    } catch (e) {}
  }

  Future<void> _signOutWithTimeout() async {
    try {
      await AuthService.signOut();
    } catch (e) {}
  }

  /// Invalidate semua providers untuk clear cache setelah logout
  void _invalidateAllProviders(WidgetRef ref) {
    try {
      // Invalidate semua providers agar data ter-refresh saat login ulang
      // Profile providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(userTotalPointsProvider);

      // Dashboard providers (Santri)
      ref.invalidate(dashboardUserProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(todayPresensiProvider);
      ref.invalidate(upcomingKegiatanProvider);
      ref.invalidate(recentPengumumanProvider);

      // Navigation & Auth providers
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(authStateProvider);

      // Dewan Guru providers
      ref.invalidate(dewaGuruUserProvider);
      ref.invalidate(dewaGuruDashboardStatsProvider);
      ref.invalidate(todayPresensiStreamProvider);
      ref.invalidate(dewaGuruTabProvider);
      ref.invalidate(dewaGuruNotificationsProvider);

      // Shared providers
      ref.invalidate(materiProvider);
      ref.invalidate(filteredMateriProvider);
      ref.invalidate(progressSummaryProvider);
      ref.invalidate(selectedSantriProvider);
      ref.invalidate(selectedMateriProvider);
    } catch (e) {
      // Ignore invalidate errors - beberapa provider mungkin tidak ada
    }
  }
}

/// Widget untuk quick logout di pojok kanan atas
class QuickLogoutButton extends StatelessWidget {
  const QuickLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: LogoutButton(showLabel: false, color: Colors.red.withAlpha(200)),
      ),
    );
  }
}

/// Widget untuk logout dalam menu
class MenuLogoutTile extends ConsumerWidget {
  final VoidCallback? onLogoutSuccess;

  const MenuLogoutTile({super.key, this.onLogoutSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(50), width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
        ),
        subtitle: const Text(
          'Keluar dari aplikasi',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.red,
          size: 16,
        ),
        onTap: () => _showLogoutDialog(context, ref),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(50), width: 1),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anda perlu login kembali untuk mengakses aplikasi.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    // Show loading dengan EasyLoading
    EasyLoading.show(
      status: 'Sedang logout...',
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );

    try {
      await Future.any([
        _performLogoutSteps(ref),
        Future.delayed(const Duration(seconds: 8), () {
          throw Exception('Logout timeout - operasi terlalu lama');
        }),
      ]);

      if (onLogoutSuccess != null) {
        onLogoutSuccess!();
      }

      // Dismiss loading dan show success
      EasyLoading.dismiss();
      if (context.mounted) {
        EasyLoading.showSuccess(
          'Berhasil logout',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      try {
        await AuthService.signOut();
        // Clear all Riverpod cache
        _invalidateAllProviders(ref);
      } catch (_) {}

      // Dismiss loading dan show success
      EasyLoading.dismiss();
      if (context.mounted) {
        EasyLoading.showSuccess(
          'Logout berhasil',
          duration: const Duration(seconds: 2),
        );
      }

      if (onLogoutSuccess != null) {
        onLogoutSuccess!();
      }
    }
  }

  Future<void> _performLogoutSteps(WidgetRef ref) async {
    try {
      // Step 1: Cleanup messaging
      await Future.any([
        _cleanupMessagingWithTimeout(),
        Future.delayed(const Duration(seconds: 2)),
      ]).catchError((_) {});

      // Step 2: Sign out
      await Future.any([
        _signOutWithTimeout(),
        Future.delayed(const Duration(seconds: 5)),
      ]);

      // Step 3: Clear all Riverpod providers cache
      _invalidateAllProviders(ref);
    } catch (e) {
      try {
        await AuthService.signOut();
        _invalidateAllProviders(ref);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _cleanupMessagingWithTimeout() async {
    try {
      await MessagingHelper.unsubscribeFromAllTopics();
    } catch (e) {}
  }

  Future<void> _signOutWithTimeout() async {
    try {
      await AuthService.signOut();
    } catch (e) {}
  }

  /// Invalidate semua providers untuk clear cache setelah logout
  void _invalidateAllProviders(WidgetRef ref) {
    try {
      // Invalidate semua providers agar data ter-refresh saat login ulang
      // Profile providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(userTotalPointsProvider);

      // Dashboard providers (Santri)
      ref.invalidate(dashboardUserProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(todayPresensiProvider);
      ref.invalidate(upcomingKegiatanProvider);
      ref.invalidate(recentPengumumanProvider);

      // Navigation & Auth providers
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(authStateProvider);

      // Dewan Guru providers
      ref.invalidate(dewaGuruUserProvider);
      ref.invalidate(dewaGuruDashboardStatsProvider);
      ref.invalidate(todayPresensiStreamProvider);
      ref.invalidate(dewaGuruTabProvider);
      ref.invalidate(dewaGuruNotificationsProvider);

      // Shared providers
      ref.invalidate(materiProvider);
      ref.invalidate(filteredMateriProvider);
      ref.invalidate(progressSummaryProvider);
      ref.invalidate(selectedSantriProvider);
      ref.invalidate(selectedMateriProvider);
    } catch (e) {
      // Ignore invalidate errors - beberapa provider mungkin tidak ada
    }
  }
}
