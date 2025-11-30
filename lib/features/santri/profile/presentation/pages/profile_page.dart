import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/services/auth_service.dart';
import 'package:sisantri/shared/services/firestore_service.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/widgets/logout_button.dart';
import 'package:sisantri/features/santri/profile/presentation/pages/edit_profile_page.dart';
import 'package:sisantri/features/santri/profile/presentation/pages/security_settings_page.dart';

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = AuthService.currentUser;
  if (currentUser == null) return null;

  return await AuthService.getUserData(currentUser.uid);
});

final userTotalPointsProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  // Gunakan aggregate yearly untuk total poin
  final yearlyAggregate = await PresensiAggregateService.getAggregate(
    userId: userId,
    periode: 'yearly',
    date: DateTime.now(),
  );

  return yearlyAggregate?.totalPoin ?? 0;
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),

                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsCards(user, ref),

                  const SizedBox(height: 24),

                  // Menu Items
                  _buildMenuItems(context, ref, user),

                  const SizedBox(height: 16),

                  // Logout Section
                  const MenuLogoutTile(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withAlpha(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: user.fotoProfil != null
                    ? ClipOval(
                        child: Image.network(
                          user.fotoProfil!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Name & Email
          Text(
            user.nama,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: user.isAdmin
                  ? Colors.red.withAlpha(15)
                  : user.isDewaGuru
                  ? Colors.purple.withAlpha(15)
                  : AppTheme.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isAdmin
                    ? Colors.red.withAlpha(50)
                    : user.isDewaGuru
                    ? Colors.purple.withAlpha(50)
                    : AppTheme.primaryColor.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isAdmin
                      ? Icons.admin_panel_settings
                      : user.isDewaGuru
                      ? Icons.school
                      : Icons.person,
                  size: 16,
                  color: user.isAdmin
                      ? Colors.red
                      : user.isDewaGuru
                      ? Colors.purple
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  user.isAdmin
                      ? 'Admin'
                      : user.isDewaGuru
                      ? 'Dewan Guru'
                      : 'Santri',
                  style: TextStyle(
                    color: user.isAdmin
                        ? Colors.red
                        : user.isDewaGuru
                        ? Colors.purple
                        : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(UserModel user, WidgetRef ref) {
    return Row(
      children: [
        if (user.isSantri) ...[
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final totalPointsAsync = ref.watch(
                  userTotalPointsProvider(user.id),
                );
                return totalPointsAsync.when(
                  loading: () => _buildStatCard(
                    icon: Icons.star,
                    title: 'Total Poin',
                    value: '...',
                    color: Colors.amber,
                  ),
                  error: (_, __) => _buildStatCard(
                    icon: Icons.star,
                    title: 'Total Poin',
                    value: '0',
                    color: Colors.amber,
                  ),
                  data: (totalPoints) => _buildStatCard(
                    icon: Icons.star,
                    title: 'Total Poin',
                    value: '$totalPoints',
                    color: Colors.amber,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_month,
            title: 'Bergabung',
            value: user.createdAt != null
                ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                : '-',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, WidgetRef ref, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            subtitle: 'Ubah informasi profil Anda',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
              );

              // Refresh data if profile was updated
              if (result == true) {
                ref.invalidate(userProfileProvider);
              }
            },
          ),
          const Divider(height: 1),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.security_outlined,
            title: 'Keamanan',
            subtitle: 'Ubah password dan pengaturan keamanan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan',
            subtitle: 'FAQ dan dukungan',
            onTap: () {
              // TODO: Navigate to help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur bantuan akan segera hadir'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0.0',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.bar_chart, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? Colors.grey).withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (textColor ?? Colors.grey).withAlpha(30),
            width: 1,
          ),
        ),
        child: Icon(icon, color: textColor ?? Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withAlpha(180) ?? Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? Colors.grey[400],
        size: 18,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SiSantri',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mosque, color: Colors.white, size: 30),
      ),
      children: [
        const Text(
          'Aplikasi gamifikasi untuk Pondok Pesantren Mahasiswa Al-Awwabin Sukarame – Bandar Lampung.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Dikembangkan untuk memudahkan santri dalam mengakses jadwal, presensi, dan informasi pondok pesantren.',
        ),
      ],
    );
  }
}
