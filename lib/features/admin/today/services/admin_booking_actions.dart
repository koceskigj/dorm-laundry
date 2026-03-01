import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingActions {
  static const int gocePricePerLaundry = 50;

  static Future<void> submitBooking({
    required FirebaseFirestore db,
    required String bookingId,
    required String paidWith, // "coins" | "cash"
  }) async {
    if (paidWith == 'coins') {
      await _completeWithCoins(db: db, bookingId: bookingId);
    } else {
      await _completeWithCash(db: db, bookingId: bookingId);
    }
  }

  static Future<void> _completeWithCoins({
    required FirebaseFirestore db,
    required String bookingId,
  }) async {
    await db.runTransaction((tx) async {
      final bookingRef = db.collection('bookings').doc(bookingId);
      final bookingSnap = await tx.get(bookingRef);
      final b = bookingSnap.data();
      if (b == null) throw Exception('Booking missing');

      if ((b['status'] ?? '') != 'booked') {
        throw Exception('Booking already processed');
      }

      final userUid = b['userUid'] as String;
      final userRef = db.collection('users').doc(userUid);
      final userSnap = await tx.get(userRef);
      final u = userSnap.data();
      if (u == null) throw Exception('User missing');

      final balance = (u['pointsBalance'] ?? 0) as num;
      if (balance < gocePricePerLaundry) {
        throw Exception('NOT_ENOUGH_COINS');
      }

      tx.update(bookingRef, {
        'status': 'completed',
        'paidWith': 'coins',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'pointsBalance': FieldValue.increment(-gocePricePerLaundry),
      });

      final histRef = userRef.collection('history').doc();
      tx.set(histRef, {
        'type': 'laundry',
        'bookingId': bookingId,
        'paidWith': 'coins',
        'coins': gocePricePerLaundry,
        'createdAt': FieldValue.serverTimestamp(),
        'dayKey': b['dayKey'],
        'startAt': b['startAt'],
        'machineNumber': b['machineNumber'],
      });
    });
  }

  static Future<void> _completeWithCash({
    required FirebaseFirestore db,
    required String bookingId,
  }) async {
    await db.runTransaction((tx) async {
      final bookingRef = db.collection('bookings').doc(bookingId);
      final bookingSnap = await tx.get(bookingRef);
      final b = bookingSnap.data();
      if (b == null) throw Exception('Booking missing');

      if ((b['status'] ?? '') != 'booked') {
        throw Exception('Booking already processed');
      }

      final userUid = b['userUid'] as String;
      final userRef = db.collection('users').doc(userUid);

      tx.update(bookingRef, {
        'status': 'completed',
        'paidWith': 'cash',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final histRef = userRef.collection('history').doc();
      tx.set(histRef, {
        'type': 'laundry',
        'bookingId': bookingId,
        'paidWith': 'cash',
        'createdAt': FieldValue.serverTimestamp(),
        'dayKey': b['dayKey'],
        'startAt': b['startAt'],
        'machineNumber': b['machineNumber'],
      });
    });
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