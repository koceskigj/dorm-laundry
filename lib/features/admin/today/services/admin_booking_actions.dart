import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingActions {
  static const int gocePricePerLaundry = 50;

  static Future<void> submitBooking({
    required FirebaseFirestore db,
    required String bookingId,
    required String paidWith, // "coins" | "cash"
  }) async {
    // ---- STEP A: finalize booking + handle payment/stats/history (1 transaction)
    late final String userUid;
    late final DateTime? startAt;
    late final int nextTotal;

    await db.runTransaction((tx) async {
      final bookingRef = db.collection('bookings').doc(bookingId);
      final bookingSnap = await tx.get(bookingRef);
      final b = bookingSnap.data();
      if (b == null) throw Exception('Booking missing');

      if ((b['status'] ?? '') != 'booked') {
        throw Exception('Booking already processed');
      }

      userUid = (b['userUid'] ?? '') as String;
      if (userUid.isEmpty) throw Exception('Booking has no userUid');

      final userRef = db.collection('users').doc(userUid);
      final userSnap = await tx.get(userRef);
      final u = userSnap.data();
      if (u == null) throw Exception('User missing');

      final currentBalance = ((u['pointsBalance'] ?? 0) as num).toInt();
      final currentTotal = ((u['totalLaundries'] ?? 0) as num).toInt();
      nextTotal = currentTotal + 1;

      // Parse startAt
      final ts = b['startAt'];
      startAt = ts is Timestamp ? ts.toDate() : null;

      // Deduct coins if needed
      if (paidWith == 'coins') {
        if (currentBalance < gocePricePerLaundry) {
          throw Exception('NOT_ENOUGH_COINS');
        }
        tx.update(userRef, {
          'pointsBalance': FieldValue.increment(-gocePricePerLaundry),
        });
      }

      // Mark booking completed
      tx.update(bookingRef, {
        'status': 'completed',
        'paidWith': paidWith,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user stats
      tx.update(userRef, {
        'totalLaundries': FieldValue.increment(1),
      });

      // History row
      final histRef = userRef.collection('history').doc();
      tx.set(histRef, {
        'type': 'laundry',
        'bookingId': bookingId,
        'paidWith': paidWith,
        'createdAt': FieldValue.serverTimestamp(),
        'dayKey': b['dayKey'],
        'startAt': b['startAt'],
        'machineNumber': b['machineNumber'],
      });
    });

    // ---- STEP B: unlock achievements AFTER the booking transaction completes
    await _unlockAchievementsAfterLaundry(
      db: db,
      userUid: userUid,
      startAt: startAt,
      nextTotal: nextTotal,
    );
  }

  static Future<void> _unlockAchievementsAfterLaundry({
    required FirebaseFirestore db,
    required String userUid,
    required DateTime? startAt,
    required int nextTotal,
  }) async {
    final userRef = db.collection('users').doc(userUid);

    // Determine candidate achievements
    final Set<String> candidates = {};

    // total-based
    if (nextTotal == 1) candidates.add('first_laundry');
    if (nextTotal == 5) candidates.add('five_washes');
    if (nextTotal == 10) candidates.add('ten_washes');
    if (nextTotal == 20) candidates.add('twenty_washes');

    // early bird (8:xx)
    if (startAt != null && startAt.hour == 8) {
      candidates.add('early_bird');
    }

    // month-based
    if (startAt != null) {
      switch (startAt.month) {
        case 9:
          candidates.add('september_wash');
          break;
        case 10:
          candidates.add('october_wash');
          break;
        case 11:
          candidates.add('november_wash');
          break;
        case 12:
          candidates.add('december_wash');
          break;
      }
    }

    // Unlock each candidate in its own transaction (simple + safe + idempotent)
    for (final achId in candidates) {
      await db.runTransaction((tx) async {
        final userAchRef = userRef.collection('achievements').doc(achId);
        final userAchSnap = await tx.get(userAchRef);

        if (userAchSnap.exists) {
          final d = userAchSnap.data();
          final unlocked = (d?['unlocked'] ?? false) as bool;
          if (unlocked) return; // already unlocked
        }

        final achRef = db.collection('achievements').doc(achId);
        final achSnap = await tx.get(achRef);
        final a = achSnap.data();
        if (a == null) return; // catalog doc missing -> skip safely

        final title = (a['title'] ?? achId) as String;
        final rewardCoins = ((a['rewardCoins'] ?? 0) as num).toInt();

        // Mark unlocked
        tx.set(
          userAchRef,
          {
            'unlocked': true,
            'unlockedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Reward coins
        if (rewardCoins > 0) {
          tx.update(userRef, {
            'pointsBalance': FieldValue.increment(rewardCoins),
          });
        }

        // Inbox item for popup
        final inboxRef = userRef.collection('inbox').doc();
        tx.set(inboxRef, {
          'type': 'achievement',
          'achievementId': achId,
          'title': title,
          'rewardCoins': rewardCoins,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      });
    }
  }

  static Future<void> suspendBooking({
    required FirebaseFirestore db,
    required String bookingId,
    required String userUid,
    required int days,
  }) async {
    final until = DateTime.now().add(Duration(days: days));

    await db.runTransaction((tx) async {
      final bookingRef = db.collection('bookings').doc(bookingId);
      final bookingSnap = await tx.get(bookingRef);
      final b = bookingSnap.data();
      if (b == null) throw Exception('Booking missing');

      if ((b['status'] ?? '') != 'booked') {
        throw Exception('Booking already processed');
      }

      tx.update(bookingRef, {
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = db.collection('users').doc(userUid);
      tx.update(userRef, {
        'status': 'suspended',
        'suspendedUntil': Timestamp.fromDate(until),
      });
    });
  }
}