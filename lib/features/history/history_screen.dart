import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_laundry_app/core/widgets/branded_app_bar.dart';
import 'package:dorm_laundry_app/features/history/providers/history_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyItemsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Booking history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (docs) {
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No completed bookings yet.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();

                    final paidWith = (d['paidWith'] ?? '').toString();
                    final machineNumber =
                    ((d['machineNumber'] ?? 0) as num).toInt();

                    final startAtRaw = d['startAt'];
                    final createdAtRaw = d['createdAt'];

                    final startAt =
                    startAtRaw is Timestamp ? startAtRaw.toDate() : null;
                    final createdAt =
                    createdAtRaw is Timestamp ? createdAtRaw.toDate() : null;

                    final isPenalty = paidWith.isEmpty;

                    String title;
                    Color bgColor;
                    Color badgeColor;
                    String badgeText;

                    if (isPenalty) {
                      title = 'PENALTY';
                      bgColor = Colors.red.withOpacity(0.80);
                      badgeColor = Colors.white;
                      badgeText = 'SUSPENDED';
                    } else if (paidWith == 'coins') {
                      title = 'Machine $machineNumber';
                      bgColor = Colors.amber.withOpacity(0.80);
                      badgeColor = Colors.white;
                      badgeText = 'COINS';
                    } else {
                      title = 'Machine $machineNumber';
                      bgColor = Colors.green.withOpacity(0.80);
                      badgeColor = Colors.white;
                      badgeText = 'CASH';
                    }

                    final subtitle = startAt == null
                        ? 'Laundry completed'
                        : DateFormat('EEE, MMM d • HH:mm').format(startAt);

                    return Card(
                      color: bgColor,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_laundry_service_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(subtitle),
                            const SizedBox(height: 10),
                            if (createdAt != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  DateFormat('EEE, MMM d • HH:mm')
                                      .format(createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.black),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}