import 'package:flutter/services.dart';

/// Native AlarmManager implementation untuk scheduled notifications
/// Workaround untuk Android yang blocking flutter_local_notifications
class NativeNotificationService {
  static const platform = MethodChannel('com.example.sisantri/notification');

  /// Schedule notification menggunakan AlarmManager langsung
  /// Lebih reliable daripada flutter_local_notifications untuk short intervals
  static Future<bool> scheduleExactNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final triggerAtMillis = scheduledTime.millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;

      print('🔔 Native AlarmManager scheduling:');
      print('   - Notification ID: $id');
      print('   - Title: $title');
      print('   - Trigger at: $scheduledTime');
      print('   - Trigger millis: $triggerAtMillis');
      print('   - Now millis: $now');
      print('   - Delay: ${triggerAtMillis - now}ms');

      final result = await platform.invokeMethod('scheduleExactNotification', {
        'id': id,
        'title': title,
        'body': body,
        'triggerAtMillis': triggerAtMillis,
      });

      print('✅ Native scheduling result: $result');
      return result as bool;
    } catch (e) {
      print('❌ Native scheduling error: $e');
      return false;
    }
  }

  /// Cancel notification
  static Future<bool> cancelNotification(int id) async {
    try {
      final result = await platform.invokeMethod('cancelNotification', {
        'id': id,
      });
      print('🗑️ Native notification cancelled: ID $id');
      return result as bool;
    } catch (e) {
      print('❌ Native cancel error: $e');
      return false;
    }
  }
}
