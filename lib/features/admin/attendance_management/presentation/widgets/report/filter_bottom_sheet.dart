import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'attendance_report_provider.dart';

/// Widget bottom sheet untuk filter laporan
class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(attendanceFilterProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih Periode:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _PresetButtons(filter: filter),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _CustomDateRange(filter: filter),
          const SizedBox(height: 20),
          _FilterSummary(filter: filter),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk tombol preset filter
class _PresetButtons extends ConsumerWidget {
  final AttendanceReportFilter filter;

  const _PresetButtons({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PresetButton(
          label: 'Hari Ini',
          onPressed: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            ref.read(attendanceFilterProvider.notifier).state = filter.copyWith(
              startDate: today,
              endDate: today,
            );
          },
        ),
        _PresetButton(
          label: '7 Hari Terakhir',
          onPressed: () {
            final now = DateTime.now();
            final endDate = DateTime(now.year, now.month, now.day);
            final startDate = endDate.subtract(const Duration(days: 6));
            ref.read(attendanceFilterProvider.notifier).state = filter.copyWith(
              startDate: startDate,
              endDate: endDate,
            );
          },
        ),
        _PresetButton(
          label: '30 Hari Terakhir',
          onPressed: () {
            final now = DateTime.now();
            final endDate = DateTime(now.year, now.month, now.day);
            final startDate = endDate.subtract(const Duration(days: 29));
            ref.read(attendanceFilterProvider.notifier).state = filter.copyWith(
              startDate: startDate,
              endDate: endDate,
            );
          },
        ),
        _PresetButton(
          label: 'Bulan Ini',
          onPressed: () {
            final now = DateTime.now();
            final startDate = DateTime(now.year, now.month, 1);
            final endDate = DateTime(now.year, now.month + 1, 0);
            ref.read(attendanceFilterProvider.notifier).state = filter.copyWith(
              startDate: startDate,
              endDate: endDate,
            );
          },
        ),
        _PresetButton(
          label: 'Bulan Lalu',
          onPressed: () {
            final now = DateTime.now();
            final startDate = DateTime(now.year, now.month - 1, 1);
            final endDate = DateTime(now.year, now.month, 0);
            ref.read(attendanceFilterProvider.notifier).state = filter.copyWith(
              startDate: startDate,
              endDate: endDate,
            );
          },
        ),
        _PresetButton(
          label: 'Semua Data',
          onPressed: () {
            ref.read(attendanceFilterProvider.notifier).state =
                const AttendanceReportFilter();
          },
        ),
      ],
    );
  }
}

/// Tombol preset individual
class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PresetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

/// Widget untuk pilih rentang tanggal custom
class _CustomDateRange extends ConsumerWidget {
  final AttendanceReportFilter filter;

  const _CustomDateRange({required this.filter});

  Future<void> _selectDate(
    BuildContext context,
    WidgetRef ref,
    bool isStartDate,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (filter.startDate ?? DateTime.now())
          : (filter.endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      ref.read(attendanceFilterProvider.notifier).state = isStartDate
          ? filter.copyWith(startDate: pickedDate)
          : filter.copyWith(endDate: pickedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atau pilih rentang tanggal:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, ref, true),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  filter.startDate != null
                      ? DateFormat('dd MMM yyyy').format(filter.startDate!)
                      : 'Dari Tanggal',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, ref, false),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  filter.endDate != null
                      ? DateFormat('dd MMM yyyy').format(filter.endDate!)
                      : 'Sampai Tanggal',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan ringkasan filter
class _FilterSummary extends StatelessWidget {
  final AttendanceReportFilter filter;

  const _FilterSummary({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filter.startDate != null && filter.endDate != null
                  ? 'Menampilkan data dari ${DateFormat('dd MMM yyyy').format(filter.startDate!)} sampai ${DateFormat('dd MMM yyyy').format(filter.endDate!)}'
                  : 'Menampilkan semua data presensi',
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }
}
