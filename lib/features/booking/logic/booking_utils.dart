import '../models/booking.dart';
import '../models/slot.dart';

class TimeOfDayLite {
  final int hour;
  final int minute;
  const TimeOfDayLite(this.hour, this.minute);
}

bool isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

bool sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool sameMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;

List<DateTime> buildWorkingDays({required int count}) {
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day);

  final result = <DateTime>[];
  while (result.length < count) {
    if (!isWeekend(day)) result.add(day);
    day = day.add(const Duration(days: 1));
  }
  return result;
}

/// Mock slot generation (later we replace this with Firestore).
List<Slot> buildSlotsForDay({
  required DateTime day,
  required String machineId,
  required List<TimeOfDayLite> slotTimes,
  required Booking? activeBooking,
}) {
  final now = DateTime.now();
  final slots = <Slot>[];

  for (final t in slotTimes) {
    final start = DateTime(day.year, day.month, day.day, t.hour, t.minute);

    // Hide passed slots today
    final isToday = sameDate(day, now);
    if (isToday && !start.isAfter(now)) continue;

    // deterministic “random” bookings
    final hash = (day.year * 10000) +
        (day.month * 100) +
        day.day +
        (t.hour * 17) +
        (t.minute * 31) +
        (machineId.hashCode & 0x7fffffff);

    final randomlyBooked = (hash % 9 == 0);

    var status = randomlyBooked ? SlotStatus.booked : SlotStatus.free;

    // mark yours
    if (activeBooking != null &&
        activeBooking.machineId == machineId &&
        sameMinute(activeBooking.start, start)) {
      status = SlotStatus.yours;
    }

    slots.add(Slot(machineId: machineId, start: start, status: status));
  }

  return slots;
}

bool canCancel(DateTime start) {
  final now = DateTime.now();
  return start.difference(now) >= const Duration(hours: 12);
}