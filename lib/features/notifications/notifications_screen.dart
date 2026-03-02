import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_laundry_app/features/notifications/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_providers.dart';
import '../../core/widgets/branded_app_bar.dart';


class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Local “instant UI” read state so the row changes color immediately on tap.
  final Set<String> _locallyReadIds = {};

  @override
  Widget build(BuildContext context) {
    final asyncSnap = ref.watch(notificationsQueryProvider);
    final lastSeen = ref.watch(lastSeenNotificationsAtProvider);

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

              final ts = data['createdAt'];
              final createdAt = ts is Timestamp ? ts.toDate() : null;

              final wasTappedRead = _locallyReadIds.contains(doc.id);

              final isUnreadServer = createdAt != null &&
                  (lastSeen == null || createdAt.isAfter(lastSeen));

              // unread if server says unread AND not already tapped
              final isUnread = isUnreadServer && !wasTappedRead;

              return Card(
                color: isUnread ? const Color(0xFFEAF4FF) : Colors.white,
                child: ListTile(
                  title: Text(
                    title.isEmpty ? '(No title)' : title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: createdAt == null
                      ? null
                      : Text(
                    _prettyTime(createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  onTap: () async {
                    // Show full notification
                    await _openDetails(
                      context,
                      title: title,
                      body: body,
                      createdAt: createdAt,
                    );

                    // Mark this one as read in UI immediately
                    setState(() => _locallyReadIds.add(doc.id));

                    // Advance lastSeenNotificationsAt so badge/unread logic updates.
                    // Use createdAt (not serverTimestamp) so the logic is consistent.
                    await _markSeenUpTo(createdAt);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markSeenUpTo(DateTime? createdAt) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    // If createdAt missing (rare), fall back to now
    final seenTime = createdAt ?? DateTime.now();

    try {
      final db = ref.read(firestoreProvider);

      // We don't want to move lastSeen backwards by accident.
      await db.runTransaction((tx) async {
        final refUser = db.collection('users').doc(uid);
        final snap = await tx.get(refUser);

        final data = snap.data() ?? <String, dynamic>{};
        final prev = data['lastSeenNotificationsAt'];

        DateTime? prevDt;
        if (prev is Timestamp) prevDt = prev.toDate();

        if (prevDt == null || seenTime.isAfter(prevDt)) {
          tx.update(refUser, {'lastSeenNotificationsAt': Timestamp.fromDate(seenTime)});
        }
      });
    } catch (_) {
      // ignore silently (offline/rules)
    }
  }

  Future<void> _openDetails(
      BuildContext context, {
        required String title,
        required String body,
        required DateTime? createdAt,
      }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title.isEmpty ? 'Notification' : title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAt != null) ...[
              Text(
                _prettyTime(createdAt),
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
            ],
            Text(body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _prettyTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}