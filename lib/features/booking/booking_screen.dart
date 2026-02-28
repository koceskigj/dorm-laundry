import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/branded_app_bar.dart';

import 'logic/booking_utils.dart';
import 'models/booking.dart';
import 'models/slot.dart';
import 'widgets/active_booking_card.dart';
import 'widgets/day_strip_with_arrows.dart';
import 'widgets/dots_indicator.dart';
import 'widgets/info_point_card.dart';
import 'widgets/machine_card_radial.dart';
import 'widgets/rule_pill.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const int machineCount = 8;
  static const int workingDaysToShow = 10;

  static const List<TimeOfDayLite> slotTimes = [
    TimeOfDayLite(8, 0),
    TimeOfDayLite(9, 15),
    TimeOfDayLite(10, 30),
    TimeOfDayLite(11, 45),
  ];

  int _selectedDayIndex = 0;
  int _selectedMachineIndex = 0;

  Booking? _activeBooking;

  late final List<DateTime> _days = buildWorkingDays(count: workingDaysToShow);

  final ScrollController _dayScrollCtrl = ScrollController();
  final PageController _machineCtrl = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _dayScrollCtrl.dispose();
    _machineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days[_selectedDayIndex];

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ActiveBookingCard(
                    booking: _activeBooking,
                    onCancel: _activeBooking == null ? null : () => _tryCancel(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: InfoPointCard(onTap: () => _showInfoPointDialog(context)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          DayStripWithArrows(
            controller: _dayScrollCtrl,
            days: _days,
            selectedIndex: _selectedDayIndex,
            onSelected: (i) => setState(() => _selectedDayIndex = i),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _machineCtrl,
                    onPageChanged: (i) => setState(() => _selectedMachineIndex = i),
                    itemCount: machineCount,
                    itemBuilder: (context, i) {
                      final machineId = 'Machine ${i + 1}';

                      final slots = buildSlotsForDay(
                        day: selectedDay,
                        machineId: machineId,
                        slotTimes: slotTimes,
                        activeBooking: _activeBooking,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: MachineCardRadial(
                          machineTitle: machineId,
                          day: selectedDay,
                          slots: slots,
                          onTapSlot: (slot) => _onTapSlot(context, slot),
                          // Pick ONE:
                          backgroundColor: const Color(0xFFEAF4FF), // light blue
                          // backgroundColor: const Color(0xFFF2F4F7), // silver
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                DotsIndicator(count: machineCount, activeIndex: _selectedMachineIndex),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoPointDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Info point'),
          content: const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onTapSlot(BuildContext context, Slot slot) async {
    if (slot.status == SlotStatus.booked) {
      _snack(context, 'This slot is already booked.');
      return;
    }

    if (slot.status == SlotStatus.yours) {
      await _showManageSheet(context, slot);
      return;
    }

    if (_activeBooking != null) {
      _snack(context, 'You already have an active booking. Cancel it first.');
      return;
    }

    await _showBookSheet(context, slot);
  }

  Future<void> _showBookSheet(BuildContext context, Slot slot) async {
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final when = fmt.format(slot.start);

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('Slot: $when'),
              Text('Machine: ${slot.machineId}'),
              const SizedBox(height: 12),
              const RulePill(
                icon: Icons.lock_outline,
                text: 'Only 1 active booking at a time',
              ),
              const SizedBox(height: 8),
              const RulePill(
                icon: Icons.schedule,
                text: 'Cancel allowed until 12 hours before start',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Book'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _activeBooking = Booking(machineId: slot.machineId, start: slot.start);
      });
      _snack(context, 'Booked!');
    }
  }

  Future<void> _showManageSheet(BuildContext context, Slot slot) async {
    final okCancel = canCancel(slot.start);
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final when = fmt.format(slot.start);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('Slot: $when'),
              Text('Machine: ${slot.machineId}'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: okCancel
                      ? () async {
                    Navigator.pop(context);
                    await _tryCancel(context);
                  }
                      : null,
                  icon: const Icon(Icons.cancel),
                  label: Text(okCancel ? 'Cancel booking' : 'Cancel unavailable (<12h)'),
                ),
              ),
              const SizedBox(height: 8),
              if (!okCancel)
                Text(
                  'You can cancel until 12 hours before the start time.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tryCancel(BuildContext context) async {
    if (_activeBooking == null) return;

    final okCancel = canCancel(_activeBooking!.start);
    if (!okCancel) {
      _snack(context, 'Too late to cancel (must be 12h before).');
      return;
    }

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('Are you sure you want to cancel your booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (sure != true) return;

    setState(() => _activeBooking = null);
    _snack(context, 'Canceled.');
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}