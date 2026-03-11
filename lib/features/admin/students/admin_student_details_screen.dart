

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'models/admin_student.dart';
import 'providers/admin_students_providers.dart';

class AdminStudentDetailsScreen extends ConsumerWidget {
  final AdminStudent student;

  const AdminStudentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminStudentHistoryProvider(student.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFFEAF4FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    child: Icon(Icons.person, size: 42),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student.fullName.isEmpty ? '(No name)' : student.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    student.email.isEmpty ? 'No email' : student.email,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Student ID', value: student.studentId),
                  _InfoRow(label: 'Status', value: student.status),
                  _InfoRow(label: 'Coins', value: '${student.pointsBalance}'),
                  _InfoRow(
                    label: 'Total laundries',
                    value: '${student.totalLaundries}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Laundry history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Error: $e'),
            ),
            data: (docs) {
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('No history yet.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final d = doc.data();

                  final paidWith = (d['paidWith'] ?? '').toString();
                  final machineNumber = ((d['machineNumber'] ?? 0) as num).toInt();

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
                    bgColor = Colors.red.withOpacity(0.70);
                    badgeColor = Colors.white;
                    badgeText = 'SUSPENDED';
                  } else if (paidWith == 'coins') {
                    title = 'Machine $machineNumber';
                    bgColor = Colors.amber.withOpacity(0.70);
                    badgeColor = Colors.white;
                    badgeText = 'COINS';
                  } else {
                    title = 'Machine $machineNumber';
                    bgColor = Colors.green.withOpacity(0.70);
                    badgeColor = Colors.white;
                    badgeText = 'CASH';
                  }

                  final subtitle = startAt == null
                      ? 'Laundry completed'
                      : DateFormat('EEE, MMM d • HH:mm').format(startAt);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
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
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}