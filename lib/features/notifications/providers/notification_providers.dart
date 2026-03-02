import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';

/// Current UID (stable): derived from authStateChangesProvider
final currentUidProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.asData?.value?.uid;
});

/// Stream: current user's Firestore doc
final userDocProvider =
StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots();
});

/// Last time the student opened the News screen (used for unread highlight/badge).
final lastSeenNotificationsAtProvider = Provider<DateTime?>((ref) {
  final snap = ref.watch(userDocProvider).valueOrNull;
  final data = snap?.data();
  final ts = data?['lastSeenNotificationsAt'];
  if (ts is Timestamp) return ts.toDate();
  return null;
});

/// Student News list (newest first).
final notificationsQueryProvider =
StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// True if there exists at least 1 notification newer than lastSeenNotificationsAt.
/// This drives the red dot badge on bottom nav.
final hasUnreadNotificationsProvider = StreamProvider.autoDispose<bool>((ref) {
  final db = ref.watch(firestoreProvider);
  final lastSeen = ref.watch(lastSeenNotificationsAtProvider);

  // If user never opened News yet -> treat as unread if there is any notification at all.
  if (lastSeen == null) {
    return db
        .collection('notifications')
        .limit(1)
        .snapshots()
        .map((q) => q.docs.isNotEmpty);
  }

  return db
      .collection('notifications')
      .where('createdAt', isGreaterThan: Timestamp.fromDate(lastSeen))
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((q) => q.docs.isNotEmpty);
});