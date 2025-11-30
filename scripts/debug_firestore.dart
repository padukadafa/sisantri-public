import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sisantri/firebase_options.dart';

/// Debug script to check Firestore data
///
/// Usage: flutter run scripts/debug_firestore.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🚀 Firebase initialized\n');

    await checkFirestoreData();
  } catch (e, stackTrace) {
    print('❌ Fatal error: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> checkFirestoreData() async {
  final firestore = FirebaseFirestore.instance;

  print('═══════════════════════════════════════════════');
  print('📊 FIRESTORE DATA CHECK');
  print('═══════════════════════════════════════════════\n');

  // Check 1: Users collection
  print('1️⃣ Checking USERS collection...');
  try {
    final usersSnapshot = await firestore.collection('users').limit(5).get();

    print('   Total users fetched: ${usersSnapshot.docs.length}');

    if (usersSnapshot.docs.isNotEmpty) {
      print('   Sample users:');
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        print('   - ${doc.id}: ${data['name']} (${data['role']})');
      }
    } else {
      print('   ⚠️  No users found!');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  // Check 2: Users with role santri/dewan_guru
  print('2️⃣ Checking users with role santri or dewan_guru...');
  try {
    final santriGuruSnapshot = await firestore
        .collection('users')
        .where('role', whereIn: ['santri', 'dewan_guru'])
        .get();

    print('   Total: ${santriGuruSnapshot.docs.length}');

    if (santriGuruSnapshot.docs.isNotEmpty) {
      print('   Sample:');
      for (var doc in santriGuruSnapshot.docs.take(3)) {
        final data = doc.data();
        print('   - ${data['name']} (${data['role']})');
      }
    } else {
      print('   ⚠️  No santri/dewan_guru found!');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  // Check 3: Presensi collection
  print('3️⃣ Checking PRESENSI collection...');
  try {
    final presensiSnapshot = await firestore
        .collection('presensi')
        .limit(5)
        .get();

    print('   Total presensi fetched: ${presensiSnapshot.docs.length}');

    if (presensiSnapshot.docs.isNotEmpty) {
      print('   Sample presensi:');
      for (var doc in presensiSnapshot.docs) {
        final data = doc.data();
        final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
        print(
          '   - User: ${data['userId']}, Status: ${data['status']}, Date: ${tanggal?.toString().split(' ')[0]}',
        );
      }
    } else {
      print('   ⚠️  No presensi found!');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  // Check 4: Presensi for date range
  print('4️⃣ Checking presensi in date range (2024-01-01 to now)...');
  try {
    final startDate = DateTime(2024, 1, 1);
    final endDate = DateTime.now();

    final rangeSnapshot = await firestore
        .collection('presensi')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .limit(10)
        .get();

    print('   Total in range: ${rangeSnapshot.docs.length}');

    if (rangeSnapshot.docs.isEmpty) {
      print('   ⚠️  No presensi in date range!');
      print('   Checking ANY presensi...');

      final anySnapshot = await firestore
          .collection('presensi')
          .orderBy('tanggal', descending: true)
          .limit(5)
          .get();

      print('   Recent presensi: ${anySnapshot.docs.length}');
      for (var doc in anySnapshot.docs) {
        final data = doc.data();
        final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
        print('   - ${tanggal?.toString().split(' ')[0]}: ${data['status']}');
      }
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  // Check 5: Presensi Aggregates collection
  print('5️⃣ Checking PRESENSI_AGGREGATES collection...');
  try {
    final aggregatesSnapshot = await firestore
        .collection('presensi_aggregates')
        .limit(10)
        .get();

    print('   Total aggregates: ${aggregatesSnapshot.docs.length}');

    if (aggregatesSnapshot.docs.isNotEmpty) {
      print('   Sample aggregates:');
      for (var doc in aggregatesSnapshot.docs.take(5)) {
        final data = doc.data();
        print('   - ${doc.id}');
        print('     Periode: ${data['periode']}, Key: ${data['periodeKey']}');
        print('     Hadir: ${data['totalHadir']}, Poin: ${data['totalPoin']}');
      }
    } else {
      print('   ⚠️  No aggregates found! (Need to run migration)');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  // Check 6: Get one user and check their presensi
  print('6️⃣ Testing migration for ONE user...');
  try {
    final oneUserSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'santri')
        .limit(1)
        .get();

    if (oneUserSnapshot.docs.isNotEmpty) {
      final userId = oneUserSnapshot.docs.first.id;
      final userName = oneUserSnapshot.docs.first.data()['name'];

      print('   Selected user: $userName ($userId)');

      // Check their presensi
      final userPresensiSnapshot = await firestore
          .collection('presensi')
          .where('userId', isEqualTo: userId)
          .get();

      print(
        '   Total presensi for this user: ${userPresensiSnapshot.docs.length}',
      );

      if (userPresensiSnapshot.docs.isEmpty) {
        print('   ⚠️  User has no presensi data!');
      } else {
        // Count by status
        final stats = <String, int>{};
        for (var doc in userPresensiSnapshot.docs) {
          final status = doc.data()['status'] as String;
          stats[status] = (stats[status] ?? 0) + 1;
        }
        print('   Stats: $stats');
      }
    } else {
      print('   ⚠️  No santri found!');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');

  print('═══════════════════════════════════════════════');
  print('✅ CHECK COMPLETE');
  print('═══════════════════════════════════════════════\n');

  print('📋 Summary:');
  print('   - If you see "No users" → Check users collection exists');
  print('   - If you see "No presensi" → Need to add presensi data first');
  print('   - If you see "No aggregates" → Run migration script');
  print('   - If you see "Error" → Check Firestore rules & indexes\n');
}
