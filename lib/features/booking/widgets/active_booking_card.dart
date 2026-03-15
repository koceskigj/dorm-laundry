import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';

class ActiveBookingCard extends StatelessWidget {
  final Booking? booking;
  final VoidCallback? onCancel;

  const ActiveBookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: b == null
            ? const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_available, size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active booking',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text('Pick a day, pick a machine, and reserve a slot.'),
                ],
              ),
            ),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your active booking',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('EEE, MMM d').format(b.start)} • ${DateFormat('HH:mm').format(b.start)}',
                      ),
                      Text(
                        b.machineId,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}