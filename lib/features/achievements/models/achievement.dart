import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final int order;
  final String? imageUrl;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.order,
    this.imageUrl,
  });

  factory Achievement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Achievement(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      rewardCoins: (data['rewardCoins'] ?? 0) as int,
      order: (data['order'] ?? 9999) as int,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}