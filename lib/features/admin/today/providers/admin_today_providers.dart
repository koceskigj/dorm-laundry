import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/firebase_providers.dart';
import '../models/admin_booking.dart';

final adminSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final adminDayKeyProvider = Provider<String>((ref) {
  final day = ref.watch(adminSelectedDayProvider);
  return DateFormat('yyyy-MM-dd').format(day);
});

final adminBookingsForDayProvider = StreamProvider<List<AdminBooking>>((ref) {
  final db = ref.watch(firestoreProvider);
  final dayKey = ref.watch(adminDayKeyProvider);

  return db
      .collection('bookings')
      .where('dayKey', isEqualTo: dayKey)
      .orderBy('startAt')
      .snapshots()
      .map((q) => q.docs.map((d) => AdminBooking.fromDoc(d)).toList());
});

/// Live single booking doc by id (details screen).
final adminBookingDocProvider =
StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
        (ref, bookingId) {
      final db = ref.watch(firestoreProvider);
      return db.collection('bookings').doc(bookingId).snapshots();
    });

/// Live user doc by uid (for coin balance preview in details sheet).
final adminUserDocProvider =
StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
        (ref, uid) {
      final db = ref.watch(firestoreProvider);
      return db.collection('users').doc(uid).snapshots();
    });