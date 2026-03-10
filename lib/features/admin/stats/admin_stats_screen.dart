import 'package:dorm_laundry_app/features/admin/stats/providers/admin_state_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/branded_app_bar.dart';

import 'widgets/stat_card.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'System overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                children: [
                  StatCard(
                    title: 'Completed laundries',
                    value: stats.totalCompleted.toString(),
                    icon: Icons.local_laundry_service,
                  ),
                  StatCard(
                    title: 'Suspensions',
                    value: stats.totalSuspended.toString(),
                    icon: Icons.block,
                  ),
                  StatCard(
                    title: 'Paid with coins',
                    value: stats.paidWithCoins.toString(),
                    icon: Icons.monetization_on_outlined,
                  ),
                  StatCard(
                    title: 'Paid with cash',
                    value: stats.paidWithCash.toString(),
                    icon: Icons.payments_outlined,
                  ),
                  StatCard(
                    title: 'Average per student',
                    value: stats.averagePerStudent.toStringAsFixed(1),
                    icon: Icons.bar_chart,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                'Laundry time popularity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _StatsBarGroup(data: stats.timeCounts),

              const SizedBox(height: 18),

              Text(
                'Weekday popularity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _StatsBarGroup(data: stats.weekdayCounts),
            ],
          );
        },
      ),
    );
  }
}

class _StatsBarGroup extends StatelessWidget {
  final Map<String, int> data;

  const _StatsBarGroup({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: data.entries.map((entry) {
            final label = entry.key;
            final value = entry.value;
            final factor = value / maxValue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: factor,
                        minHeight: 12,
                        backgroundColor: Colors.grey.withOpacity(0.15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}