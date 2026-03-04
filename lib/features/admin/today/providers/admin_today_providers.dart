import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/firebase_providers.dart';
import '../models/admin_booking.dart';

final adminSelectedDayProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final adminDayKeyProvider = Provider<String>((ref) {
  final day = ref.watch(adminSelectedDayProvider);
  return DateFormat('yyyy-MM-dd').format(day);
});


final adminBookingsForDayProvider =
StreamProvider.autoDispose<List<AdminBooking>>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  final dayKey = ref.watch(adminDayKeyProvider);

  return db
      .collection('bookings')
      .where('dayKey', isEqualTo: dayKey)
      .orderBy('startAt')
      .snapshots()
      .map((q) => q.docs.map((d) => AdminBooking.fromDoc(d)).toList());
});

final adminBookingDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, bookingId) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('bookings').doc(bookingId).snapshots();
});


final adminUserDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, uid) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots();
});