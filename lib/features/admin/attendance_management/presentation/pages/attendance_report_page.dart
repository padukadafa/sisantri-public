import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisantri/features/admin/attendance_management/presentation/widgets/report/filter_dialog.dart';

import '../widgets/report/attendance_report_provider.dart';
import '../widgets/report/statistics_grid.dart';
import '../widgets/report/attendance_distribution.dart';
import '../widgets/report/user_summary_card.dart';
import '../widgets/report/excel_export_service.dart';

/// Halaman Laporan Presensi
class AttendanceReportPage extends ConsumerStatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  ConsumerState<AttendanceReportPage> createState() =>
      _AttendanceReportPageState();
}

class _AttendanceReportPageState extends ConsumerState<AttendanceReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Future<void> _exportToExcel() async {
    final filter = ref.read(attendanceFilterProvider);
    final reportAsync = ref.read(attendanceReportProvider(filter));

    reportAsync.when(
      data: (reportData) async {
        // Show loading
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final filePath = await ExcelExportService.exportToExcel(
            reportData: reportData,
            filter: filter,
          );

          // Close loading
          if (!mounted) return;
          Navigator.pop(context);

          // Show success
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Excel berhasil disimpan!\n📁 Lokasi: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Buka File',
                onPressed: () => ExcelExportService.openExportedFile(filePath),
              ),
            ),
          );
        } catch (e) {
          // Close loading
          if (!mounted) return;
          Navigator.pop(context);

          // Show error
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Export gagal: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      loading: () {},
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data belum dimuat'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(attendanceFilterProvider);
    final reportAsync = ref.watch(attendanceReportProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan', icon: Icon(Icons.analytics)),
            Tab(text: 'Per Santri', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(reportAsync: reportAsync),
          _UserSummaryTab(reportAsync: reportAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "main_export",
        onPressed: _exportToExcel,
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Export Excel',
        child: const Icon(Icons.file_download),
      ),
    );
  }
}

/// Tab Ringkasan
class _SummaryTab extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>> reportAsync;

  const _SummaryTab({required this.reportAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceReportProvider);
      },
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorWidget(error: error.toString()),
        data: (data) {
          final stats = data['statistics'] as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatisticsGrid(statistics: stats),
                const SizedBox(height: 16),
                AttendanceDistribution(statistics: stats),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tab Ringkasan Per Santri
class _UserSummaryTab extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>> reportAsync;

  const _UserSummaryTab({required this.reportAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceReportProvider);
      },
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorWidget(error: error.toString()),
        data: (data) {
          final userSummary =
              data['userSummary'] as Map<String, Map<String, dynamic>>;

          if (userSummary.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada data presensi'),
              ),
            );
          }

          final sortedEntries = userSummary.entries.toList()
            ..sort((a, b) {
              final userA = a.value['user'];
              final userB = b.value['user'];
              return userA.nama.compareTo(userB.nama);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final summary = entry.value;
              return UserSummaryCard(user: summary['user'], summary: summary);
            },
          );
        },
      ),
    );
  }
}

/// Widget untuk menampilkan error
class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
