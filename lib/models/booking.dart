class Booking {
  final String id;
  final String userId;
  final String slotId;
  final String status; // booked|canceled|completed|no_show
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.status,
    required this.createdAt,
  });
}