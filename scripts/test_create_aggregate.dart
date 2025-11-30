import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sisantri/firebase_options.dart';
import 'package:sisantri/shared/services/presensi_aggregate_service.dart';

/// Test script to manually create aggregate for one user
///
/// Usage: flutter run scripts/test_create_aggregate.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🚀 Firebase initialized\n');

    await testCreateAggregate();
  } catch (e, stackTrace) {
    print('❌ Fatal error: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testCreateAggregate() async {
  final firestore = FirebaseFirestore.instance;

  print('═══════════════════════════════════════════════');
  print('🧪 TEST CREATE AGGREGATE');
  print('═══════════════════════════════════════════════\n');

  try {
    // Step 1: Get one santri
    print('1️⃣ Fetching one santri...');
    final usersSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'santri')
        .limit(1)
        .get();

    if (usersSnapshot.docs.isEmpty) {
      print('❌ No santri found! Please add users with role "santri" first.');
      return;
    }

    final user = usersSnapshot.docs.first;
    final userId = user.id;
    final userName = user.data()['name'] ?? 'Unknown';

    print('✅ Found: $userName ($userId)\n');

    // Step 2: Check existing presensi
    print('2️⃣ Checking existing presensi...');
    final presensiSnapshot = await firestore
        .collection('presensi')
        .where('userId', isEqualTo: userId)
        .get();

    print('✅ Found ${presensiSnapshot.docs.length} presensi records\n');

    if (presensiSnapshot.docs.isEmpty) {
      print('⚠️  User has no presensi data!');
      print('📝 Creating test presensi...\n');

      // Create test presensi
      await _createTestPresensi(firestore, userId);

      print('✅ Test presensi created!\n');
    }

    // Step 3: Call updateAggregates manually
    print('3️⃣ Creating aggregates manually...');

    await PresensiAggregateService.updateAggregates(
      userId: userId,
      tanggal: DateTime.now(),
      status: 'hadir',
      poin: 10,
    );

    print('✅ Aggregate update called!\n');

    // Step 4: Verify aggregates created
    print('4️⃣ Verifying aggregates...');
    final today = DateTime.now();
    final dailyKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final aggregateSnapshot = await firestore
        .collection('presensi_aggregates')
        .where('userId', isEqualTo: userId)
        .where('periode', isEqualTo: 'daily')
        .where('periodeKey', isEqualTo: dailyKey)
        .limit(1)
        .get();

    if (aggregateSnapshot.docs.isNotEmpty) {
      print('✅ Aggregate document found!');
      final doc = aggregateSnapshot.docs.first;
      final data = doc.data();
      print('   Document ID: ${doc.id}');
      print('   Total Hadir: ${data['totalHadir']}');
      print('   Total Poin: ${data['totalPoin']}');
    } else {
      print('❌ Aggregate document NOT found!');
      print('   Expected doc ID: ${userId}_daily_$dailyKey');
    }

    print('\n5️⃣ Checking all aggregates for this user...');
    final allAggregates = await firestore
        .collection('presensi_aggregates')
        .where('userId', isEqualTo: userId)
        .get();

    print('✅ Total aggregates: ${allAggregates.docs.length}');
    for (var doc in allAggregates.docs) {
      final data = doc.data();
      print('   - ${doc.id} (${data['periode']}: ${data['periodeKey']})');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }

  print('\n═══════════════════════════════════════════════');
  print('✅ TEST COMPLETE');
  print('═══════════════════════════════════════════════\n');

  print('📋 Next steps:');
  print('   1. Check Firestore Console → presensi_aggregates collection');
  print('   2. If no documents → Check console for errors');
  print('   3. Verify security rules allow admin writes');
  print('   4. Check indexes are ready (not "Building")');
}

Future<void> _createTestPresensi(
  FirebaseFirestore firestore,
  String userId,
) async {
  // Create a test presensi for today
  final now = DateTime.now();

  await firestore.collection('presensi').add({
    'userId': userId,
    'tanggal': Timestamp.fromDate(now),
    'status': 'hadir',
    'poinDiperoleh': 10,
    'jadwalId': 'test_jadwal',
    'keterangan': 'Test presensi for aggregate',
    'createdAt': Timestamp.now(),
  });

  print('   ✅ Created test presensi: hadir, 10 poin');
}
