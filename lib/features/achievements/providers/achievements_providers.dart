import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../../notifications/providers/notification_providers.dart';
import '../models/achievement.dart';
import '../services/coin_transfer_service.dart';



final userDocProvider =
StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots();
});

final pointsBalanceProvider = Provider<int>((ref) {
  final snap = ref.watch(userDocProvider).valueOrNull;
  final data = snap?.data();
  final v = data?['pointsBalance'] ?? 0;
  return (v as num).toInt();
});

final achievementsCatalogProvider =
StreamProvider.autoDispose<List<Achievement>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('achievements')
      .orderBy('order')
      .snapshots()
      .map((q) => q.docs.map((d) => Achievement.fromDoc(d)).toList());
});

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

/// ✅ UNSAFE version: direct Firestore transfer (you said keep it)
final coinTransferServiceProvider = Provider<CoinTransferService>((ref) {
  return CoinTransferService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final myEmailProvider = Provider<AsyncValue<String>>((ref) {
  final snapAsync = ref.watch(userDocProvider);
  return snapAsync.whenData((snap) {
    final data = snap.data() ?? <String, dynamic>{};
    final email = (data['email'] ?? '') as String;
    return email.toLowerCase();
  });
});

/// --------------------
/// Achievement popup inbox
/// --------------------

class AchievementInboxItem {
  final String id; // inbox doc id
  final String achievementId;
  final String title;
  final int rewardCoins;

  AchievementInboxItem({
    required this.id,
    required this.achievementId,
    required this.title,
    required this.rewardCoins,
  });

  factory AchievementInboxItem.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    return AchievementInboxItem(
      id: doc.id,
      achievementId: (d['achievementId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      rewardCoins: ((d['rewardCoins'] ?? 0) as num).toInt(),
    );
  }
}

/// Stream the newest unread "achievement_unlocked" inbox event (or null).
/// IMPORTANT: no orderBy -> avoids needing a composite index.
final unreadAchievementPopupProvider =
StreamProvider.autoDispose<AchievementInboxItem?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);

  return db
      .collection('users')
      .doc(uid)
      .collection('inbox')
      .where('type', isEqualTo: 'achievement_unlocked')
      .where('read', isEqualTo: false)
      .limit(1)
      .snapshots()
      .map((q) {
    if (q.docs.isEmpty) return null;
    return AchievementInboxItem.fromDoc(q.docs.first);
  });
});

Future<void> markAchievementInboxRead({
  required FirebaseFirestore db,
  required String uid,
  required String inboxId,
}) {
  return db
      .collection('users')
      .doc(uid)
      .collection('inbox')
      .doc(inboxId)
      .update({'read': true});
}