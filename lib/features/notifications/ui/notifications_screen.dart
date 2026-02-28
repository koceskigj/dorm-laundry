import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_laundry_app/core/widgets/branded_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';

final notificationsQueryProvider =
StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);

  // Pinned first, then newest
  return db
      .collection('notifications')
      .orderBy('pinned', descending: true)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnap = ref.watch(notificationsQueryProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: asyncSnap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (snap) {
          if (snap.docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: snap.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = snap.docs[i].data();

              final title = (data['title'] ?? '').toString();
              final body = (data['body'] ?? '').toString();
              final pinned = (data['pinned'] ?? false) as bool;
              final priority = (data['priority'] ?? 'info').toString();
              final ts = data['createdAt'];
              final createdAt = ts is Timestamp ? ts.toDate() : null;

              final icon = priority == 'warning'
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title.isEmpty ? '(No title)' : title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (pinned) const Icon(Icons.push_pin),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(body),
                      const SizedBox(height: 10),
                      if (createdAt != null)
                        Text(
                          createdAt.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}