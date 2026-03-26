import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_laundry_app/core/widgets/branded_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnap = ref.watch(notificationsQueryProvider);
    final readIds = ref.watch(readNotificationIdsProvider).valueOrNull ?? <String>{};

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: asyncSnap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (snap) {
          if (snap.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: snap.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = snap.docs[i];
              final data = doc.data();

              final title = (data['title'] ?? '').toString();
              final body = (data['body'] ?? '').toString();
              final imageUrl = (data['imageUrl'] ?? '').toString();
              final ts = data['createdAt'];
              final createdAt = ts is Timestamp ? ts.toDate() : null;

              final unread = !readIds.contains(doc.id);

              return Card(
                color: unread ? const Color(0xFFEAF4FF) : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await markNotificationRead(ref, doc.id);

                    if (!context.mounted) return;

                    showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // 👈 KEY (flexible height)
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TITLE
                                Text(
                                  title.isEmpty ? '(No title)' : title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                /// BODY
                                Text(
                                  body,
                                  style: const TextStyle(fontSize: 15),
                                ),

                                /// IMAGE (controlled, not dialog)
                                if (imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height * 0.35, // 👈 only limit image
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            alignment: Alignment.center,
                                            color: Colors.grey.shade200,
                                            child: const Text('Could not load image'),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],

                                /// DATE
                                if (createdAt != null) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      DateFormat('EEE, MMM d • HH:mm').format(createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 14),

                                /// BUTTON
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title.isEmpty ? '(No title)' : title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        /// short preview only
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[800],
                            height: 1.25,
                          ),
                        ),

                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 140,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  color: Colors.grey.shade200,
                                  child: const Text('Could not load image'),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        if (createdAt != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              DateFormat('EEE, MMM d • HH:mm').format(createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
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