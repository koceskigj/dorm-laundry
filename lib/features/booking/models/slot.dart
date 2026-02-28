enum SlotStatus { free, booked, yours }

class Slot {
  final String machineId;
  final DateTime start;
  final SlotStatus status;

  Slot({
    required this.machineId,
    required this.start,
    required this.status,
  });
}