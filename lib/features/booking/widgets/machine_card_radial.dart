import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/slot.dart';
import 'slot_chip.dart';

class MachineCardRadial extends StatelessWidget {
  final String machineTitle;
  final DateTime day;
  final List<Slot> slots;
  final ValueChanged<Slot> onTapSlot;

  // optional: colorize the card
  final Color? backgroundColor;

  const MachineCardRadial({
    super.key,
    required this.machineTitle,
    required this.day,
    required this.slots,
    required this.onTapSlot,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleDate = DateFormat('EEE, MMM d').format(day);
    final headerText = '$machineTitle • $titleDate';

    final top = slots.isNotEmpty ? slots[0] : null;
    final right = slots.length > 1 ? slots[1] : null;
    final bottom = slots.length > 2 ? slots[2] : null;
    final left = slots.length > 3 ? slots[3] : null;

    return Card(
      elevation: 1.5,
      color: backgroundColor, // e.g. light blue / silver
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const _HeaderDot(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const _HeaderDot(),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final size = c.maxWidth;

                        final circle = (size * 0.30).clamp(95.0, 170.0);
                        final chipW = (size * 0.34).clamp(130.0, 210.0);
                        final chipH = (size * 0.20).clamp(72.0, 72.0);
                        final gap = (size * 0.05).clamp(14.0, 22.0);

                        final cx = size / 2;
                        final cy = size / 2;
                        final r = circle / 2;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: cx - r,
                              top: cy - r,
                              width: circle,
                              height: circle,
                              child: _PriceCircle(
                                borderColor:
                                Theme.of(context).colorScheme.outlineVariant,
                                fill: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            Positioned(
                              left: cx - chipW / 2,
                              top: cy - r - gap - chipH,
                              width: chipW,
                              height: chipH,
                              child: SlotChip(slot: top, onTap: onTapSlot),
                            ),
                            Positioned(
                              left: cx + r + gap,
                              top: cy - chipH / 2,
                              width: chipW,
                              height: chipH,
                              child: SlotChip(slot: right, onTap: onTapSlot),
                            ),
                            Positioned(
                              left: cx - chipW / 2,
                              top: cy + r + gap,
                              width: chipW,
                              height: chipH,
                              child: SlotChip(slot: bottom, onTap: onTapSlot),
                            ),
                            Positioned(
                              left: cx - r - gap - chipW,
                              top: cy - chipH / 2,
                              width: chipW,
                              height: chipH,
                              child: SlotChip(slot: left, onTap: onTapSlot),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderDot extends StatelessWidget {
  const _HeaderDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PriceCircle extends StatelessWidget {
  final Color borderColor;
  final Color fill;

  const _PriceCircle({
    required this.borderColor,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: fill,
      ),
    );
  }
}