import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase_providers.dart';
import '../models/laundry_partner.dart';

final partnersProvider = StreamProvider<List<LaundryPartner>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db.collection('partners').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => LaundryPartner.fromDoc(doc.id, doc.data()))
        .toList();
  });
});