import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase_providers.dart';

class AdminStatsData {
  final int totalCompleted;
  final int totalSuspended;
  final int paidWithCoins;
  final int paidWithCash;
  final double averagePerStudent;

  final Map<String, int> timeCounts;
  final Map<String, int> weekdayCounts;

  const AdminStatsData({
    required this.totalCompleted,
    required this.totalSuspended,
    required this.paidWithCoins,
    required this.paidWithCash,
    required this.averagePerStudent,
    required this.timeCounts,
    required this.weekdayCounts,
  });
}

final adminStatsProvider = FutureProvider.autoDispose<AdminStatsData>((ref) async {
  final db = ref.watch(firestoreProvider);

  final bookingsSnap = await db.collection('bookings').get();
  final usersSnap = await db.collection('users').get();

  int totalCompleted = 0;
  int totalSuspended = 0;
  int paidWithCoins = 0;
  int paidWithCash = 0;

  final timeCounts = <String, int>{
    '08:00': 0,
    '09:15': 0,
    '10:30': 0,
    '11:45': 0,
  };

  final weekdayCounts = <String, int>{
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
  };

  for (final doc in bookingsSnap.docs) {
    final d = doc.data();

    final status = (d['status'] ?? '').toString();
    final paidWith = (d['paidWith'] ?? '').toString();

    if (status == 'completed') {
      totalCompleted++;

      if (paidWith == 'coins') {
        paidWithCoins++;
      } else if (paidWith == 'cash') {
        paidWithCash++;
      }

      final ts = d['startAt'];
      final startAt = ts is Timestamp ? ts.toDate() : null;

      if (startAt != null) {
        final timeKey =
            '${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}';
        if (timeCounts.containsKey(timeKey)) {
          timeCounts[timeKey] = (timeCounts[timeKey] ?? 0) + 1;
        }

        final weekday = _weekdayLabel(startAt.weekday);
        if (weekdayCounts.containsKey(weekday)) {
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        }
      }
    }

    if (status == 'suspended') {
      totalSuspended++;
    }
  }

  int studentCount = 0;
  int laundriesSum = 0;

  for (final doc in usersSnap.docs) {
    final d = doc.data();
    final role = (d['role'] ?? '').toString();

    if (role == 'student') {
      studentCount++;
      laundriesSum += ((d['totalLaundries'] ?? 0) as num).toInt();
    }
  }

  final averagePerStudent =
  studentCount == 0 ? 0.0 : laundriesSum / studentCount;

  return AdminStatsData(
    totalCompleted: totalCompleted,
    totalSuspended: totalSuspended,
    paidWithCoins: paidWithCoins,
    paidWithCash: paidWithCash,
    averagePerStudent: averagePerStudent,
    timeCounts: timeCounts,
    weekdayCounts: weekdayCounts,
  );
});

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '?';
  }
}