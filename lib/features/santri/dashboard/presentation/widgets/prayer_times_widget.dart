import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:sisantri/shared/services/prayer_times_service.dart';

/// Widget untuk menampilkan waktu sholat berikutnya di dashboard
class NextPrayerCard extends StatefulWidget {
  const NextPrayerCard({super.key});

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard> {
  Timer? _timer;
  Map<String, dynamic>? _nextPrayer;
  Duration? _timeUntilPrayer;

  @override
  void initState() {
    super.initState();
    _updatePrayerTime();
    // Update setiap menit
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePrayerTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updatePrayerTime() {
    final nextPrayer = PrayerTimesService.getNextPrayerTime();
    if (nextPrayer != null) {
      final prayerTime = nextPrayer['time'] as DateTime;
      final timeUntil = prayerTime.difference(DateTime.now());

      if (mounted) {
        setState(() {
          _nextPrayer = nextPrayer;
          _timeUntilPrayer = timeUntil;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Sekarang';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '${seconds}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nextPrayer == null) {
      return const SizedBox.shrink();
    }

    final prayerName = _nextPrayer!['name'] as String;
    final prayerTime = _nextPrayer!['time'] as DateTime;
    final displayName = PrayerTimesService.getPrayerDisplayName(prayerName);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.mosque,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sholat Berikutnya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(prayerTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_timeUntilPrayer != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDuration(_timeUntilPrayer!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'lagi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan semua waktu sholat hari ini
class PrayerTimesCard extends StatelessWidget {
  const PrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final prayerTimes = PrayerTimesService.getAllPrayerTimesForDisplay();
    final now = DateTime.now();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Jadwal Sholat Hari Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prayerTimes.map((prayer) {
              final prayerTime = prayer['time'] as DateTime;
              final isPassed = prayerTime.isBefore(now);
              final isCurrent =
                  !isPassed && prayerTime.difference(now).inMinutes.abs() <= 5;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prayer['displayName'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isPassed
                            ? Colors.grey
                            : (isCurrent ? Colors.green : Colors.black87),
                      ),
                    ),
                    Row(
                      children: [
                        if (isCurrent)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          prayer['formattedTime'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isPassed
                                ? Colors.grey
                                : (isCurrent ? Colors.green : Colors.black87),
                          ),
                        ),
                        if (isPassed)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
