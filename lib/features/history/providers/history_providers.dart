import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';

final historyCurrentUidProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.asData?.value?.uid;
});

final historyItemsProvider =
StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        (ref) {
      final uid = ref.watch(historyCurrentUidProvider);
      if (uid == null) return const Stream.empty();

      final db = ref.watch(firestoreProvider);

      return db
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs);
    });