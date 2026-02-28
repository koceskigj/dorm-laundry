import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../services/coin_transfer_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUidProvider = Provider<String?>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  return user?.uid;
});

/// Stream: current user's Firestore doc
final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreProvider).collection('users').doc(uid).snapshots();
});

/// Derived: Goce balance
final goceBalanceProvider = Provider<int>((ref) {
  final snap = ref.watch(userDocProvider).valueOrNull;
  final data = snap?.data();
  return (data?['goceBalance'] ?? 0) as int;
});

/// Global catalog of achievements
final achievementsCatalogProvider = StreamProvider<List<Achievement>>((ref) {
  final db = ref.watch(firestoreProvider);
  return db.collection('achievements').orderBy('order').snapshots().map((q) {
    return q.docs.map((d) => Achievement.fromDoc(d)).toList();
  });
});

/// Map of unlocked achievements for current user: {achievementId -> unlockedAt}
final unlockedAchievementsProvider = StreamProvider<Map<String, Timestamp>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).collection('achievements').snapshots().map((q) {
    final map = <String, Timestamp>{};
    for (final doc in q.docs) {
      final data = doc.data();
      final unlocked = (data['unlocked'] ?? false) as bool;
      if (unlocked) {
        final ts = data['unlockedAt'];
        if (ts is Timestamp) {
          map[doc.id] = ts;
        } else {
          map[doc.id] = Timestamp.now();
        }
      }
    }
    return map;
  });
});

final coinTransferServiceProvider = Provider<CoinTransferService>((ref) {
  return CoinTransferService(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider));
});