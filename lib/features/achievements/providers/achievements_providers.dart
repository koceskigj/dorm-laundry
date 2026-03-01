import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../models/achievement.dart';
import '../services/coin_transfer_service.dart';

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

/// Derived: balance (use the SAME field everywhere)
final pointsBalanceProvider = Provider<int>((ref) {
  final snap = ref.watch(userDocProvider).valueOrNull;
  final data = snap?.data();
  final v = data?['pointsBalance'] ?? 0;
  return (v as num).toInt();
});

/// Global catalog of achievements
final achievementsCatalogProvider =
StreamProvider.autoDispose<List<Achievement>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('achievements')
      .orderBy('order')
      .snapshots()
      .map((q) => q.docs.map((d) => Achievement.fromDoc(d)).toList());
});

/// Map of unlocked achievements for current user: {achievementId -> unlockedAt}
final unlockedAchievementsProvider =
StreamProvider.autoDispose<Map<String, Timestamp>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);

  return db
      .collection('users')
      .doc(uid)
      .collection('achievements')
      .snapshots()
      .map((q) {
    final map = <String, Timestamp>{};
    for (final doc in q.docs) {
      final data = doc.data();
      final unlocked = (data['unlocked'] ?? false) as bool;
      if (unlocked) {
        final ts = data['unlockedAt'];
        map[doc.id] = ts is Timestamp ? ts : Timestamp.now();
      }
    }
    return map;
  });
});

final coinTransferServiceProvider = Provider<CoinTransferService>((ref) {
  return CoinTransferService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});