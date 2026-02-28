import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinTransferService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CoinTransferService(this._db, this._auth);

  /// Transfers [amount] coins from current user -> user with [recipientEmail].
  /// Checks:
  /// - recipient exists
  /// - amount > 0
  /// - sender has enough balance
  Future<void> transferCoins({
    required String recipientEmail,
    required int amount,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) {
      throw Exception('Not logged in.');
    }

    final trimmedEmail = recipientEmail.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      throw Exception('Recipient email is empty.');
    }
    if (amount <= 0) {
      throw Exception('Amount must be greater than 0.');
    }

    final senderRef = _db.collection('users').doc(sender.uid);

    // Find recipient by email
    final recipientQuery = await _db
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (recipientQuery.docs.isEmpty) {
      throw Exception('Recipient not found.');
    }

    final recipientDoc = recipientQuery.docs.first;
    final recipientRef = recipientDoc.reference;

    if (recipientRef.id == sender.uid) {
      throw Exception('You cannot gift coins to yourself.');
    }

    await _db.runTransaction((tx) async {
      final senderSnap = await tx.get(senderRef);
      if (!senderSnap.exists) {
        throw Exception('Your user profile does not exist in Firestore.');
      }

      final senderData = senderSnap.data() as Map<String, dynamic>? ?? {};
      final senderBalance = (senderData['goceBalance'] ?? 0) as int;

      if (senderBalance < amount) {
        throw Exception('Not enough Goce coins.');
      }

      // Update balances atomically
      tx.update(senderRef, {'goceBalance': FieldValue.increment(-amount)});
      tx.update(recipientRef, {'goceBalance': FieldValue.increment(amount)});

      // Optional: create transfer record (audit/history)
      final transferRef = _db.collection('transfers').doc();
      tx.set(transferRef, {
        'fromUid': sender.uid,
        'toUid': recipientRef.id,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}