import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBooking {
  final String id;
  final String userUid;
  final String studentId;
  final String studentName;
  final int machineNumber;
  final DateTime startAt;
  final String dayKey;

  final String status;   // booked | completed | no_show | suspended | canceled
  final String? paidWith; // coins | cash | null

  AdminBooking({
    required this.id,
    required this.userUid,
    required this.studentId,
    required this.studentName,
    required this.machineNumber,
    required this.startAt,
    required this.dayKey,
    required this.status,
    required this.paidWith,
  });

  factory AdminBooking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminBooking(
      id: doc.id,
      userUid: (d['userUid'] ?? '') as String,
      studentId: (d['studentId'] ?? '') as String,
      studentName: (d['studentName'] ?? '') as String,
      machineNumber: (d['machineNumber'] ?? 0) as int,
      startAt: (d['startAt'] as Timestamp).toDate(),
      dayKey: (d['dayKey'] ?? '') as String,
      status: (d['status'] ?? 'booked') as String,
      paidWith: d['paidWith'] as String?,
    );
  }
}