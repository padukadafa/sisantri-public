import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sisantri/firebase_options.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

/// Script untuk migrate presensi data ke aggregate system
///
/// Usage:
/// flutter run lib/scripts/migrate_aggregates.dart
///
/// Script ini akan:
/// 1. Membaca semua users dengan role santri atau dewan_guru
/// 2. Untuk setiap user, rebuild aggregates dari presensi yang ada
/// 3. Generate 5 aggregate documents per user (daily, weekly, monthly, semester, yearly)
///
/// ⚠️ Warning:
/// - Script ini membaca SEMUA presensi documents
/// - Untuk database besar, akan consume banyak reads
/// - Ada rate limiting 500ms per user untuk avoid throttling

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🚀 Firebase initialized');
    print('📊 Starting Aggregate Migration...\n');

    await migrateAllUsersAggregates();
  } catch (e) {
    print('❌ Fatal error: $e');
  }
}

Future<void> migrateAllUsersAggregates() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Configuration
    final startDate = DateTime(2024, 1, 1); // Adjust sesuai kebutuhan
    final endDate = DateTime.now();

    print('⚙️  Configuration:');
    print('   Start Date: ${startDate.toIso8601String().split('T')[0]}');
    print('   End Date: ${endDate.toIso8601String().split('T')[0]}');
    print('');

    // Get all users dengan role santri atau dewan_guru
    print('🔍 Fetching users...');
    final usersSnapshot = await firestore
        .collection('users')
        .where('role', whereIn: ['santri', 'dewan_guru'])
        .get();

    final totalUsers = usersSnapshot.docs.length;
    print('✅ Found $totalUsers users to migrate\n');

    if (totalUsers == 0) {
      print('⚠️  No users found with role santri or dewan_guru');
      return;
    }

    int successCount = 0;
    int errorCount = 0;
    final errors = <String, String>{};

    // Process each user
    for (var i = 0; i < usersSnapshot.docs.length; i++) {
      final userDoc = usersSnapshot.docs[i];
      final userId = userDoc.id;
      final userName = userDoc.data()['name'] ?? 'Unknown';
      final userRole = userDoc.data()['role'] ?? 'Unknown';

      try {
        print('[$successCount/$totalUsers] Processing: $userName ($userRole)');
        print('   User ID: $userId');

        // Check if user has presensi data
        final presensiSnapshot = await firestore
            .collection('presensi')
            .where('userId', isEqualTo: userId)
            .where(
              'tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .limit(1)
            .get();

        if (presensiSnapshot.docs.isEmpty) {
          print('   ⚠️  No presensi data found - skipping');
          successCount++;
          print('');
          continue;
        }

        // Rebuild aggregates
        await PresensiAggregateService.rebuildAggregates(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );

        successCount++;
        print('   ✅ Aggregates rebuilt successfully');
        print('');

        // Rate limiting: tunggu 500ms antar user untuk avoid throttling
        if (i < usersSnapshot.docs.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        errorCount++;
        errors[userId] = e.toString();
        print('   ❌ Error: $e');
        print('');
      }
    }

    // Print summary
    print('\n═══════════════════════════════════════════════');
    print('📊 MIGRATION SUMMARY');
    print('═══════════════════════════════════════════════');
    print('✅ Success: $successCount users');
    print('❌ Errors: $errorCount users');
    print(
      '📈 Success Rate: ${(successCount / totalUsers * 100).toStringAsFixed(1)}%',
    );

    if (errors.isNotEmpty) {
      print('\n❌ Failed Users:');
      errors.forEach((userId, error) {
        print('   - $userId: $error');
      });
    }

    print('\n🏁 Migration complete!');
    print('═══════════════════════════════════════════════\n');
  } catch (e) {
    print('❌ Fatal error in batch migration: $e');
    rethrow;
  }
}

/// Migrate single user (untuk testing atau manual migration)
Future<void> migrateSingleUser(String userId) async {
  try {
    print('🔄 Migrating aggregates for user: $userId');

    await PresensiAggregateService.rebuildAggregates(
      userId: userId,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime.now(),
    );

    print('✅ Migration complete for user: $userId');
  } catch (e) {
    print('❌ Error migrating user $userId: $e');
    rethrow;
  }
}
