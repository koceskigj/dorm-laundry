import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinTransferService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CoinTransferService(this._db, this._auth);

  /// UNSAFE MVP:
  /// Transfers [amount] coins from current user -> user found by [recipientEmail].
  ///
  /// Rules required (unsafe):
  /// - signed-in users can read users collection (or at least query by email)
  /// - signed-in users can update their own pointsBalance
  /// - signed-in users can update recipient pointsBalance (VERY UNSAFE)
  Future<void> transferCoins({
    required String recipientEmail,
    required int amount,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) throw Exception('Not logged in.');

    final email = recipientEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Enter a valid email.');
    }
    if (amount <= 0) {
      throw Exception('Enter a valid amount.');
    }

    // Find recipient by email
    final recipientQuery = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (recipientQuery.docs.isEmpty) {
      throw Exception('Recipient not found.');
    }

    final recipientDoc = recipientQuery.docs.first;
    final recipientUid = recipientDoc.id;

    if (recipientUid == sender.uid) {
      throw Exception('You cannot gift coins to yourself.');
    }

    final senderRef = _db.collection('users').doc(sender.uid);
    final recipientRef = _db.collection('users').doc(recipientUid);

    await _db.runTransaction((tx) async {
      final senderSnap = await tx.get(senderRef);
      if (!senderSnap.exists) {
        throw Exception('Your profile is missing.');
      }

      final senderData = senderSnap.data() as Map<String, dynamic>? ?? {};
      final senderBalanceNum = (senderData['pointsBalance'] ?? 0) as num;
      final senderBalance = senderBalanceNum.toInt();

      if (senderBalance < amount) {
        throw Exception('Not enough Goce coins.');
      }

      // (Optional) safety: ensure recipient still exists inside txn
      final recipientSnap = await tx.get(recipientRef);
      if (!recipientSnap.exists) {
        throw Exception('Recipient not found.');
      }

      // Update balances
      tx.update(senderRef, {
        'pointsBalance': FieldValue.increment(-amount),
      });

      tx.update(recipientRef, {
        'pointsBalance': FieldValue.increment(amount),
      });

      // Optional audit record (you can remove if you want)
      final transferRef = _db.collection('transfers').doc();
      tx.set(transferRef, {
        'fromUid': sender.uid,
        'toUid': recipientUid,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}