import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudent {
  final String uid;
  final String studentId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final int pointsBalance;
  final int totalLaundries;

  AdminStudent({
    required this.uid,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.pointsBalance,
    required this.totalLaundries,
  });

  factory AdminStudent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final firstName = (d['firstName'] ?? '') as String;
    final lastName = (d['lastName'] ?? '') as String;
    final fullNameFromDb = (d['fullName'] ?? '') as String;

    final computedFullName = fullNameFromDb.trim().isNotEmpty
        ? fullNameFromDb.trim()
        : '$firstName $lastName'.trim();

    return AdminStudent(
      uid: doc.id,
      studentId: (d['studentId'] ?? '') as String,
      firstName: firstName,
      lastName: lastName,
      fullName: computedFullName,
      email: (d['email'] ?? '') as String,
      role: (d['role'] ?? '') as String,
      status: (d['status'] ?? 'active') as String,
      pointsBalance: ((d['pointsBalance'] ?? 0) as num).toInt(),
      totalLaundries: ((d['totalLaundries'] ?? 0) as num).toInt(),
    );
  }
}