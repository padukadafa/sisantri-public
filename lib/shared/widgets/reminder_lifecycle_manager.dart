import 'package:flutter/material.dart';
import 'dart:async';

import 'package:sisantri/shared/services/reminder_service.dart';

/// Widget untuk mengelola lifecycle reminder service
/// Ensures reminders are refreshed when app is active
class ReminderLifecycleManager extends StatefulWidget {
  final Widget child;

  const ReminderLifecycleManager({super.key, required this.child});

  @override
  State<ReminderLifecycleManager> createState() =>
      _ReminderLifecycleManagerState();
}

class _ReminderLifecycleManagerState extends State<ReminderLifecycleManager>
    with WidgetsBindingObserver {
  Timer? _dailyRefreshTimer;
  DateTime? _lastRefreshDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupDailyRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dailyRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshIfNeeded();
    }
  }

  /// Setup timer untuk refresh reminder setiap tengah malam
  void _setupDailyRefresh() {
    final now = DateTime.now();
    _lastRefreshDate = DateTime(now.year, now.month, now.day);

    // Hitung waktu sampai tengah malam berikutnya
    final tomorrow = now.add(const Duration(days: 1));
    final midnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final timeUntilMidnight = midnight.difference(now);

    // Schedule refresh di tengah malam
    _dailyRefreshTimer = Timer(timeUntilMidnight, () {
      _refreshReminders();
      // Setup timer berikutnya (setiap 24 jam)
      _dailyRefreshTimer = Timer.periodic(
        const Duration(days: 1),
        (_) => _refreshReminders(),
      );
    });
  }

  /// Check apakah perlu refresh (jika hari sudah berganti)
  void _checkAndRefreshIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastRefreshDate == null || today.isAfter(_lastRefreshDate!)) {
      _refreshReminders();
      _lastRefreshDate = today;
    }
  }

  /// Refresh semua reminders
  Future<void> _refreshReminders() async {
    try {
      await ReminderService.refreshReminders();
      debugPrint('✅ Reminders refreshed at ${DateTime.now()}');
    } catch (e) {
      debugPrint('❌ Error refreshing reminders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
