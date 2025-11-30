import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sisantri/core/theme/app_theme.dart';
import 'package:sisantri/shared/models/user_model.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisantri/features/admin/user_management/presentation/widgets/rfid_management_dialog.dart';
import 'package:sisantri/features/admin/user_management/presentation/widgets/edit_user_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Halaman Detail User
class UserDetailPage extends ConsumerStatefulWidget {
  final UserModel user;

  const UserDetailPage({super.key, required this.user});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail User')),
            body: const Center(child: Text('User tidak ditemukan')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromJson({'id': snapshot.data!.id, ...userData});

        return _buildContent(user);
      },
    );
  }

  Widget _buildContent(UserModel user) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Detail User'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E2E2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
            tooltip: 'Edit User',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: user.statusAktif ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      user.statusAktif ? Icons.block : Icons.check_circle,
                      size: 18,
                      color: user.statusAktif ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.statusAktif ? 'Non-aktifkan' : 'Aktifkan',
                      style: TextStyle(
                        color: user.statusAktif ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Reset Password',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
              if (!user.isAdmin)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(user),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Informasi'),
                Tab(text: 'Aktivitas'),
                Tab(text: 'Statistik'),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(user),
                _buildActivityTab(user),
                _buildStatisticsTab(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header Section dengan foto profil dan info utama
  Widget _buildHeaderSection(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user).withOpacity(0.1),
                radius: 50,
                child: Text(
                  user.nama.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(user),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.statusAktif ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    user.statusAktif ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nama
          Text(
            user.nama,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2E2E),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(user).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRoleColor(user).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(user),
                      color: _getRoleColor(user),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRoleText(user),
                      style: TextStyle(
                        color: _getRoleColor(user),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // RFID Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: user.hasRfidSetup
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user.hasRfidSetup
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.hasRfidSetup ? Icons.nfc : Icons.nfc_outlined,
                      color: user.hasRfidSetup ? Colors.blue : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.hasRfidSetup ? 'RFID Aktif' : 'No RFID',
                      style: TextStyle(
                        color: user.hasRfidSetup ? Colors.blue : Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tab Informasi
  Widget _buildInformationTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informasi Pribadi
          _buildSectionCard(
            title: 'Informasi Pribadi',
            icon: Icons.person,
            children: [
              _buildInfoItem('Nama Lengkap', user.nama),
              _buildInfoItem('Email', user.email),
              if (user.nim != null) _buildInfoItem('NIM', user.nim!),
              _buildInfoItem('Role', _getRoleText(user)),
              _buildInfoItem(
                'Status',
                user.statusAktif ? 'Aktif' : 'Non-Aktif',
                valueColor: user.statusAktif ? Colors.green : Colors.red,
              ),
              FutureBuilder<int>(
                future: PresensiAggregateService.getAggregate(
                  userId: user.id,
                  periode: 'yearly',
                  date: DateTime.now(),
                ).then((agg) => agg?.totalPoin ?? 0),
                builder: (context, snapshot) {
                  return _buildInfoItem(
                    'Poin',
                    snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : (snapshot.data ?? 0).toString(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informasi Akademik (untuk santri)
          if (user.isSantri) ...[
            _buildSectionCard(
              title: 'Informasi Akademik',
              icon: Icons.school,
              children: [
                if (user.kampus != null) _buildInfoItem('Kampus', user.kampus!),
                if (user.tempatKos != null)
                  _buildInfoItem('Tempat Kos', user.tempatKos!),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Informasi RFID
          _buildSectionCard(
            title: 'Informasi RFID',
            icon: Icons.nfc,
            children: [
              _buildInfoItem(
                'Status RFID',
                user.hasRfidSetup ? 'Aktif' : 'Tidak Aktif',
                valueColor: user.hasRfidSetup ? Colors.green : Colors.red,
              ),
              if (user.rfidCardId != null)
                _buildInfoItem('ID Kartu', user.rfidCardId!),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRfidManagementDialog(context),
                  icon: const Icon(Icons.nfc, size: 20),
                  label: Text(
                    user.hasRfidSetup ? 'Kelola RFID' : 'Assign RFID',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informasi Sistem
          _buildSectionCard(
            title: 'Informasi Sistem',
            icon: Icons.info_outline,
            children: [
              if (user.createdAt != null)
                _buildInfoItem(
                  'Tanggal Dibuat',
                  _formatDateTime(user.createdAt!),
                ),
              if (user.updatedAt != null)
                _buildInfoItem(
                  'Terakhir Diupdate',
                  _formatDateTime(user.updatedAt!),
                ),
              _buildInfoItem('User ID', user.id),
            ],
          ),
        ],
      ),
    );
  }

  /// Tab Aktivitas
  Widget _buildActivityTab(UserModel user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('presensi')
          .where('userId', isEqualTo: user.id)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final activities = snapshot.data?.docs ?? [];

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada aktivitas',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            return _buildActivityItem(activity);
          },
        );
      },
    );
  }

  /// Tab Statistik menggunakan Aggregate
  Widget _buildStatisticsTab(UserModel user) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PresensiAggregateService.getAggregateSummary(userId: user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final aggregates = snapshot.data ?? {};
        final weekly = aggregates['weekly'];
        final monthly = aggregates['monthly'];
        final semester = aggregates['semester'];
        final yearly = aggregates['yearly'];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              title: 'Statistik Mingguan',
              icon: Icons.calendar_view_week,
              color: Colors.blue,
              hadir: weekly?.totalHadir ?? 0,
              izin: weekly?.totalIzin ?? 0,
              sakit: weekly?.totalSakit ?? 0,
              alpha: weekly?.totalAlpha ?? 0,
              poin: weekly?.totalPoin ?? 0,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Statistik Bulanan',
              icon: Icons.calendar_month,
              color: Colors.green,
              hadir: monthly?.totalHadir ?? 0,
              izin: monthly?.totalIzin ?? 0,
              sakit: monthly?.totalSakit ?? 0,
              alpha: monthly?.totalAlpha ?? 0,
              poin: monthly?.totalPoin ?? 0,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Statistik Semester',
              icon: Icons.school,
              color: Colors.orange,
              hadir: semester?.totalHadir ?? 0,
              izin: semester?.totalIzin ?? 0,
              sakit: semester?.totalSakit ?? 0,
              alpha: semester?.totalAlpha ?? 0,
              poin: semester?.totalPoin ?? 0,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Statistik Tahunan',
              icon: Icons.calendar_today,
              color: Colors.purple,
              hadir: yearly?.totalHadir ?? 0,
              izin: yearly?.totalIzin ?? 0,
              sakit: yearly?.totalSakit ?? 0,
              alpha: yearly?.totalAlpha ?? 0,
              poin: yearly?.totalPoin ?? 0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required int hadir,
    required int izin,
    required int sakit,
    required int alpha,
    required int poin,
  }) {
    final total = hadir + izin + sakit + alpha;
    final percentage = total > 0
        ? (hadir / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    Text(
                      'Total: $total presensi',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Hadir', hadir, Colors.green)),
              Expanded(child: _buildStatItem('Izin', izin, Colors.blue)),
              Expanded(child: _buildStatItem('Sakit', sakit, Colors.orange)),
              Expanded(child: _buildStatItem('Alpha', alpha, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Poin: $poin',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Widget Section Card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Widget Info Item
  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF2E2E2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget Activity Item
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final status = activity['status'] ?? 'unknown';
    final timestamp = activity['timestamp'] != null
        ? (activity['timestamp'] as Timestamp).toDate()
        : null;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'hadir':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'alpha':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'izin':
        statusColor = Colors.blue;
        statusIcon = Icons.event_available;
        break;
      case 'sakit':
        statusColor = Colors.orange;
        statusIcon = Icons.local_hospital;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (timestamp != null)
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                if (activity['keterangan'] != null &&
                    activity['keterangan'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      activity['keterangan'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper methods
  Color _getRoleColor(UserModel user) {
    if (user.isAdmin) return Colors.red;
    if (user.isDewaGuru) return Colors.orange;
    if (user.isSantri) return Colors.blue;
    return Colors.grey;
  }

  IconData _getRoleIcon(UserModel user) {
    if (user.isAdmin) return Icons.admin_panel_settings;
    if (user.isDewaGuru) return Icons.person_outline;
    if (user.isSantri) return Icons.school;
    return Icons.person;
  }

  String _getRoleText(UserModel user) {
    if (user.isAdmin) return 'ADMIN';
    if (user.isDewaGuru) return 'DEWAN GURU';
    if (user.isSantri) return 'SANTRI';
    return 'USER';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Actions
  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(context);
        break;
      case 'reset_password':
        _resetUserPassword(context);
        break;
      case 'delete':
        _deleteUser(context);
        break;
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: widget.user),
    );

    // Refresh handled by StreamBuilder automatically
    if (result == true && mounted) {
      // StreamBuilder will automatically update
    }
  }

  Future<void> _showRfidManagementDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RfidManagementDialog(user: widget.user),
    );

    // Refresh handled by StreamBuilder automatically
    if (result == true && mounted) {
      // StreamBuilder will automatically update
    }
  }

  Future<void> _toggleUserStatus(BuildContext context) async {
    final user = widget.user;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.statusAktif ? 'Non-aktifkan' : 'Aktifkan'} User'),
        content: Text(
          'Apakah Anda yakin ingin ${user.statusAktif ? 'menonaktifkan' : 'mengaktifkan'} user "${user.nama}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.statusAktif ? Colors.red : Colors.green,
            ),
            child: Text(user.statusAktif ? 'Non-aktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
              'statusAktif': !user.statusAktif,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Log activity
        await FirebaseFirestore.instance.collection('activities').add({
          'type': user.statusAktif ? 'user_deactivated' : 'user_activated',
          'title': user.statusAktif ? 'User Dinonaktifkan' : 'User Diaktifkan',
          'description':
              'User "${user.nama}" berhasil ${user.statusAktif ? 'dinonaktifkan' : 'diaktifkan'}',
          'timestamp': FieldValue.serverTimestamp(),
          'recordedBy': 'Admin',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${user.nama} berhasil ${user.statusAktif ? 'dinonaktifkan' : 'diaktifkan'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _resetUserPassword(BuildContext context) async {
    final user = widget.user;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Apakah Anda yakin ingin mereset password untuk user "${user.nama}"?\n\nEmail reset password akan dikirim ke: ${user.email}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);

        // Log activity
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'password_reset',
          'title': 'Password Reset',
          'description': 'Email reset password dikirim ke ${user.email}',
          'timestamp': FieldValue.serverTimestamp(),
          'recordedBy': 'Admin',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email reset password berhasil dikirim ke ${user.email}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    final user = widget.user;

    if (user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User dengan role Admin tidak dapat dihapus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Apakah Anda yakin ingin menghapus user "${user.nama}"?\n\nPeringatan: Tindakan ini tidak dapat dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete user from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .delete();

        // Log activity
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'user_deleted',
          'title': 'User Dihapus',
          'description': 'User "${user.nama}" berhasil dihapus dari sistem',
          'timestamp': FieldValue.serverTimestamp(),
          'recordedBy': 'Admin',
        });

        if (mounted) {
          // Go back to user list
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${user.nama} berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
