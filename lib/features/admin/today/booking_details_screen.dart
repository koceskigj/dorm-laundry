import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/firebase_providers.dart';
import 'models/admin_booking.dart';
import 'providers/admin_today_providers.dart';
import 'services/admin_booking_actions.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final bookingDocAsync = ref.watch(adminBookingDocProvider(widget.bookingId));

    return bookingDocAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Booking details')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (doc) {
        final data = doc.data();
        if (!doc.exists || data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking details')),
            body: const Center(child: Text('Booking not found.')),
          );
        }

        final b = AdminBooking.fromDoc(doc);
        final when = DateFormat('EEE, MMM d • HH:mm').format(b.startAt);
        final isActionable = b.status == 'booked';

        return Scaffold(
          appBar: AppBar(title: const Text('Booking details')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student: ${b.studentName}',
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Student ID: ${b.studentId}'),
                        Text('Machine: ${b.machineNumber}'),
                        Text('Time: $when'),
                        const SizedBox(height: 8),
                        Text('Status: ${b.status}'),
                        if (b.paidWith != null) Text('Paid with: ${b.paidWith}'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                if (!isActionable)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'This booking is already processed.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),

                if (isActionable)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _confirmSuspend(context, b),
                          icon: const Icon(Icons.block),
                          label: const Text('Suspend'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : () => _submitSheet(context, b),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSuspend(BuildContext context, AdminBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend student?'),
        content: const Text(
          'This will suspend the student for 30 days and mark this booking as suspended.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final db = ref.read(firestoreProvider);

      await AdminBookingActions.suspendBooking(
        db: db,
        bookingId: b.id,
        userUid: b.userUid,
        days: 30,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suspended.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitSheet(BuildContext context, AdminBooking b) async {
    String paidWith = 'coins';

    // live balance preview
    final userDocAsync = ref.read(adminUserDocProvider(b.userUid));

    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final userDoc = ref.watch(adminUserDocProvider(b.userUid));

            final balance = userDoc.maybeWhen(
              data: (d) => ((d.data()?['pointsBalance'] ?? 0) as num).toInt(),
              orElse: () => 0,
            );

            final enoughCoins = balance >= AdminBookingActions.gocePricePerLaundry;

            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submit booking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text('Student balance: $balance coins'),

                      const SizedBox(height: 10),

                      RadioListTile<String>(
                        value: 'coins',
                        groupValue: paidWith,
                        onChanged: (v) => setModalState(() => paidWith = v!),
                        title: const Text('Paid with Goce coins'),
                        subtitle: enoughCoins
                            ? null
                            : const Text('Not enough coins (needs 50).'),
                      ),
                      RadioListTile<String>(
                        value: 'cash',
                        groupValue: paidWith,
                        onChanged: (v) => setModalState(() => paidWith = v!),
                        title: const Text('Paid with cash'),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                // block confirm if coins selected and not enough
                                if (paidWith == 'coins' && !enoughCoins) return;
                                Navigator.pop(ctx, true);
                              },
                              child: const Text('Confirm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != true) return;

    setState(() => _busy = true);
    try {
      final db = ref.read(firestoreProvider);

      await AdminBookingActions.submitBooking(
        db: db,
        bookingId: b.id,
        paidWith: paidWith,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('NOT_ENOUGH_COINS')
          ? 'Not enough coins for this student.'
          : 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}