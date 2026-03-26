import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';

final currentUidProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.asData?.value?.uid;
});

final userDocProvider =
StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots();
});

final notificationsQueryProvider =
StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// Set of notification IDs already read by the current user
final readNotificationIdsProvider =
StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);

  return db
      .collection('users')
      .doc(uid)
      .collection('readNotifications')
      .snapshots()
      .map((q) => q.docs.map((d) => d.id).toSet());
});

/// Red dot on bottom nav: true if there exists at least one unread notification
final hasUnreadNotificationsProvider =
Provider.autoDispose<bool>((ref) {
  final notificationsSnap = ref.watch(notificationsQueryProvider).valueOrNull;
  final readIds = ref.watch(readNotificationIdsProvider).valueOrNull ?? <String>{};

  if (notificationsSnap == null) return false;

  for (final doc in notificationsSnap.docs) {
    if (!readIds.contains(doc.id)) return true;
  }
  return false;
});

Future<void> markNotificationRead(WidgetRef ref, String notificationId) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;

  final db = ref.read(firestoreProvider);

  await db
      .collection('users')
      .doc(uid)
      .collection('readNotifications')
      .doc(notificationId)
      .set({
    'readAt': Timestamp.fromDate(DateTime.now()),
  });
}