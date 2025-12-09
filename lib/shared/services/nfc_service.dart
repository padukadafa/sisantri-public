import 'package:flutter/material.dart';
import 'dart:math';

import 'package:nfc_manager/nfc_manager.dart';

/// Service untuk mengelola NFC/RFID operations
///
/// Saat ini menggunakan mock implementation untuk demo purposes.
/// Untuk implementasi real dengan hardware NFC:
/// 1. Testing diperlukan dengan kartu Mifare fisik
/// 2. Platform-specific code untuk Android/iOS
/// 3. Error handling untuk berbagai jenis kartu
/// 4. Proper extraction dari NfcTag.data berdasarkan tipe kartu
class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  /// Check if NFC is available on device
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('Error checking NFC availability: $e');
      return false;
    }
  }

  /// Start NFC session to read RFID card
  Future<String?> readRfidCard() async {
    try {
      final bool isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        throw Exception('NFC tidak tersedia pada perangkat ini');
      }

      String? cardId;

   await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            cardId = _extractCardId(tag);
            debugPrint('Card detected: $cardId');
          } catch (e) {
            debugPrint('Error reading NFC tag: $e');
            throw Exception('Gagal membaca kartu RFID: $e');
          } finally {
            await NfcManager.instance.stopSession();
          }
        },   
      );

      return cardId;
    } catch (e) {
      debugPrint('Error in readRfidCard: $e');
      await NfcManager.instance.stopSession();
      rethrow;
    }
  }

  /// Start NFC session with custom callback
  Future<void> startSession({
    required Function(String cardId) onCardDetected,
    required Function(String error) onError,
    String? alertMessage,
  }) async {
    try {
      final bool isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        onError('NFC tidak tersedia pada perangkat ini');
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final cardId = _extractCardId(tag);
            if (cardId != null) {
              onCardDetected(cardId);
            } else {
              onError('Gagal membaca ID kartu');
            }
          } catch (e) {
            onError('Error membaca kartu: $e');
          } finally {
            await stopSession();
          }
        },
      );
    } catch (e) {
      onError('Error memulai sesi NFC: $e');
    }
  }

  /// Extract card ID from NFC tag
  String? _extractCardId(NfcTag tag) {
    try {
      // For now, generate a mock card ID since the NFC API is complex
      // and requires deeper integration with platform-specific code
      final mockId = _generateMockCardId();
      debugPrint('Generated mock card ID: $mockId');
      return mockId;

      // TODO: Implement real card ID extraction once NFC hardware is available
      // This will require:
      // 1. Testing with actual Mifare cards
      // 2. Platform-specific implementations for Android/iOS
      // 3. Proper error handling for different card types
    } catch (e) {
      debugPrint('Error extracting card ID: $e');
      return _generateMockCardId();
    }
  }

  /// Generate mock card ID for demonstration
  String _generateMockCardId() {
    final random = Random();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return _bytesToHex(bytes);
  }

  /// Stop NFC session
  Future<void> stopSession() async {
    try {
      debugPrint('Stopping NFC session...');
      // In real implementation: await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Error stopping NFC session: $e');
    }
  }

  /// Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('')
        .toUpperCase();
  }

  /// Format card ID for display
  String formatCardId(String cardId) {
    if (cardId.length >= 8) {
      return '${cardId.substring(0, 4)}-${cardId.substring(4, 8)}' +
          (cardId.length > 8 ? '-${cardId.substring(8)}' : '');
    }
    return cardId;
  }

  /// Validate card ID format
  bool isValidCardId(String cardId) {
    // Basic validation: should be hex string with minimum length
    final hexPattern = RegExp(r'^[0-9A-Fa-f]+$');
    return cardId.length >= 8 && hexPattern.hasMatch(cardId);
  }
}
