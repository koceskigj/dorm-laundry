import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/slot.dart';

class SlotChip extends StatelessWidget {
  final Slot? slot;
  final ValueChanged<Slot> onTap;

  const SlotChip({
    super.key,
    required this.slot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slot == null) return const _EmptyChip();

    final label = DateFormat('HH:mm').format(slot!.start);

    final Color bg = switch (slot!.status) {
      SlotStatus.free => Colors.white,
      SlotStatus.booked => Colors.red,
      SlotStatus.yours => Colors.green,
    };

    final Color fg = switch (slot!.status) {
      SlotStatus.free => Colors.black,
      SlotStatus.booked => Colors.white,
      SlotStatus.yours => Colors.white,
    };

    final String sub = switch (slot!.status) {
      SlotStatus.free => 'Free',
      SlotStatus.booked => 'Booked',
      SlotStatus.yours => 'Yours',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(slot!),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: fg,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(sub, style: TextStyle(color: fg, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  const _EmptyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Center(
        child: Text(
          '—',
          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}