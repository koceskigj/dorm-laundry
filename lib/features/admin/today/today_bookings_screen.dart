import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/branded_app_bar.dart';
import 'models/admin_booking.dart';
import 'providers/admin_today_providers.dart';
import 'booking_details_screen.dart';

class TodayBookingsScreen extends ConsumerWidget {
  const TodayBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(adminSelectedDayProvider);
    final bookingsAsync = ref.watch(adminBookingsForDayProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _DayHeader(
            day: day,
            onPrev: () => ref.read(adminSelectedDayProvider.notifier).state =
                day.subtract(const Duration(days: 1)),
            onNext: () => ref.read(adminSelectedDayProvider.notifier).state =
                day.add(const Duration(days: 1)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings for this day.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    return _BookingRow(
                      booking: b,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsScreen(bookingId: b.id),
                          ),
                        );
                      },
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

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DayHeader({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, MMM d').format(day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final AdminBooking booking;
  final VoidCallback onTap;

  const _BookingRow({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(booking.startAt);

    Color tint;
    String badge;

    switch (booking.status) {
      case 'completed':
        tint = Colors.green.withOpacity(0.12);
        badge = booking.paidWith == null
            ? 'COMPLETED'
            : 'COMPLETED (${booking.paidWith!.toUpperCase()})';
        break;
      case 'suspended':
        tint = Colors.red.withOpacity(0.12);
        badge = 'SUSPENDED';
        break;
      case 'no_show':
        tint = Colors.red.withOpacity(0.12);
        badge = 'NO-SHOW';
        break;
      default:
        tint = Colors.blueGrey.withOpacity(0.08);
        badge = 'BOOKED';
    }

    return Card(
      color: tint,
      child: ListTile(
        onTap: onTap,
        title: Text(
          '$time • Machine ${booking.machineNumber}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${booking.studentName} • ${booking.studentId}'),
        trailing: _StatusPill(text: badge),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}