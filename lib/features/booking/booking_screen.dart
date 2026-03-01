import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/firebase_providers.dart';
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

final myUserProfileProvider =
StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return db.collection('users').doc(uid).snapshots();
});

final myActiveBookingProvider =
StreamProvider.autoDispose<QueryDocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return db
      .collection('bookings')
      .where('userUid', isEqualTo: uid)
      .where('status', isEqualTo: 'booked')
      .limit(1)
      .snapshots()
      .map((q) => q.docs.isEmpty ? null : q.docs.first);
});

final bookingsForDayProvider =
StreamProvider.autoDispose.family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>(
        (ref, dayKey) {
      final db = ref.watch(firestoreProvider);

      return db
          .collection('bookings')
          .where('dayKey', isEqualTo: dayKey)
          .orderBy('startAt')
          .snapshots()
          .map((q) => q.docs);
    });

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
    final auth = ref.watch(firebaseAuthProvider);
    final uid = auth.currentUser?.uid;

    final selectedDay = _days[_selectedDayIndex];
    final selectedDayKey = DateFormat('yyyy-MM-dd').format(selectedDay);

    final activeBookingAsync = ref.watch(myActiveBookingProvider);
    final dayBookingsAsync = ref.watch(bookingsForDayProvider(selectedDayKey));
    final profileAsync = ref.watch(myUserProfileProvider);

    // Build a lightweight "Booking?" for the UI card, from Firestore active booking
    final Booking? activeBookingUi = activeBookingAsync.maybeWhen(
      data: (doc) {
        if (doc == null) return null;
        final d = doc.data();
        final startAt = (d['startAt'] as Timestamp).toDate();
        final machineNumber = (d['machineNumber'] as num).toInt();
        return Booking(machineId: 'Machine $machineNumber', start: startAt);
      },
      orElse: () => null,
    );

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
                    booking: activeBookingUi,
                    onCancel: activeBookingUi == null
                        ? null
                        : () => _tryCancel(context, activeBookingAsync),
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
                  child: dayBookingsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (dayDocs) {
                      return PageView.builder(
                        controller: _machineCtrl,
                        onPageChanged: (i) => setState(() => _selectedMachineIndex = i),
                        itemCount: machineCount,
                        itemBuilder: (context, i) {
                          final machineNumber = i + 1;
                          final machineId = 'Machine $machineNumber';

                          final slots = _buildSlotsFromFirestore(
                            day: selectedDay,
                            machineNumber: machineNumber,
                            slotTimes: slotTimes,
                            dayBookings: dayDocs,
                            myUid: uid,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: MachineCardRadial(
                              machineTitle: machineId,
                              day: selectedDay,
                              slots: slots,
                              onTapSlot: (slot) => _onTapSlot(
                                context,
                                slot,
                                activeBookingAsync,
                                profileAsync,
                              ),
                              backgroundColor: const Color(0xFFEAF4FF), // light blue
                            ),
                          );
                        },
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

  List<Slot> _buildSlotsFromFirestore({
    required DateTime day,
    required int machineNumber,
    required List<TimeOfDayLite> slotTimes,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> dayBookings,
    required String? myUid,
  }) {
    final now = DateTime.now();
    final slots = <Slot>[];

    for (final t in slotTimes) {
      final start = DateTime(day.year, day.month, day.day, t.hour, t.minute);

      // hide past times for today
      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
      if (isToday && !start.isAfter(now)) continue;

      SlotStatus status = SlotStatus.free;

      // Find any booking doc that matches machine+time and is still booked
      for (final d in dayBookings) {
        final data = d.data();
        final mn = (data['machineNumber'] as num?)?.toInt();
        final st = (data['startAt'] as Timestamp?)?.toDate();
        final s = (data['status'] ?? '') as String;
        final u = (data['userUid'] ?? '') as String;

        if (s != 'booked') continue;
        if (mn == machineNumber && st != null && _sameMinute(st, start)) {
          status = (myUid != null && u == myUid) ? SlotStatus.yours : SlotStatus.booked;
          break;
        }
      }

      slots.add(
        Slot(
          machineId: 'Machine $machineNumber',
          start: start,
          status: status,
        ),
      );
    }

    return slots;
  }

  bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
          a.month == b.month &&
          a.day == b.day &&
          a.hour == b.hour &&
          a.minute == b.minute;

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

  Future<void> _onTapSlot(
      BuildContext context,
      Slot slot,
      AsyncValue<QueryDocumentSnapshot<Map<String, dynamic>>?> activeBookingAsync,
      AsyncValue<DocumentSnapshot<Map<String, dynamic>>> profileAsync,
      ) async {
    if (slot.status == SlotStatus.booked) {
      _snack(context, 'This slot is already booked.');
      return;
    }

    if (slot.status == SlotStatus.yours) {
      await _showManageSheet(context, slot, activeBookingAsync);
      return;
    }

    final hasActive = activeBookingAsync.asData?.value != null;
    if (hasActive) {
      _snack(context, 'You already have an active booking. Cancel it first.');
      return;
    }

    await _showBookSheet(context, slot, profileAsync);
  }

  Future<void> _showBookSheet(
      BuildContext context,
      Slot slot,
      AsyncValue<DocumentSnapshot<Map<String, dynamic>>> profileAsync,
      ) async {
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

    if (confirm != true) return;

    final auth = ref.read(firebaseAuthProvider);
    final db = ref.read(firestoreProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    // Read name + studentId from profile
    final profileDoc = profileAsync.asData?.value;
    final data = profileDoc?.data() ?? {};
    final studentId = (data['studentId'] ?? 'UNKNOWN') as String;

    String studentName = 'Unknown';
    if (data['fullName'] != null) {
      studentName = data['fullName'] as String;
    } else {
      final fn = (data['firstName'] ?? '') as String;
      final ln = (data['lastName'] ?? '') as String;
      final combined = ('$fn $ln').trim();
      if (combined.isNotEmpty) studentName = combined;
    }

    final machineNumber = int.parse(slot.machineId.replaceAll('Machine ', '').trim());

    final dayKey = DateFormat('yyyy-MM-dd').format(slot.start);
    final docId = '$dayKey-M$machineNumber-${DateFormat('HHmm').format(slot.start)}';

    try {
      await db.runTransaction((tx) async {
        // enforce: no active booking
        final activeSnap = await db
            .collection('bookings')
            .where('userUid', isEqualTo: uid)
            .where('status', isEqualTo: 'booked')
            .limit(1)
            .get();

        if (activeSnap.docs.isNotEmpty) {
          throw Exception('ALREADY_HAS_ACTIVE');
        }

        final refBooking = db.collection('bookings').doc(docId);
        final existing = await tx.get(refBooking);
        if (existing.exists) {
          throw Exception('SLOT_TAKEN');
        }

        tx.set(refBooking, {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'dayKey': dayKey,
          'machineNumber': machineNumber,
          'startAt': Timestamp.fromDate(slot.start),
          'status': 'booked',
          'paidWith': null,
          'studentId': studentId,
          'studentName': studentName,
          'userUid': uid,
        });
      });

      if (!mounted) return;
      _snack(context, 'Booked!');
    } catch (e) {
      final s = e.toString();
      if (s.contains('ALREADY_HAS_ACTIVE')) {
        _snack(context, 'You already have an active booking.');
      } else if (s.contains('SLOT_TAKEN')) {
        _snack(context, 'This slot was just taken. Pick another one.');
      } else {
        _snack(context, 'Error: $e');
      }
    }
  }

  Future<void> _showManageSheet(
      BuildContext context,
      Slot slot,
      AsyncValue<QueryDocumentSnapshot<Map<String, dynamic>>?> activeBookingAsync,
      ) async {
    final activeDoc = activeBookingAsync.asData?.value;
    if (activeDoc == null) return;

    final startAt = (activeDoc.data()['startAt'] as Timestamp).toDate();
    final okCancel = canCancel(startAt);

    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final when = fmt.format(startAt);

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
              Text('Machine: Machine ${(activeDoc.data()['machineNumber'] as num).toInt()}'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: okCancel
                      ? () async {
                    Navigator.pop(context);
                    await _tryCancel(context, activeBookingAsync);
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

  Future<void> _tryCancel(
      BuildContext context,
      AsyncValue<QueryDocumentSnapshot<Map<String, dynamic>>?> activeBookingAsync,
      ) async {
    final activeDoc = activeBookingAsync.asData?.value;
    if (activeDoc == null) return;

    final startAt = (activeDoc.data()['startAt'] as Timestamp).toDate();
    if (!canCancel(startAt)) {
      _snack(context, 'Too late to cancel (must be 12h before).');
      return;
    }

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('Are you sure you want to cancel your booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
        ],
      ),
    );

    if (sure != true) return;

    final db = ref.read(firestoreProvider);
    await db.collection('bookings').doc(activeDoc.id).delete();
    _snack(context, 'Canceled.');
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}