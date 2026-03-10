import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase_providers.dart';
import '../models/admin_student.dart';

final adminStudentsSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final adminStudentsProvider =
StreamProvider.autoDispose<List<AdminStudent>>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);

  return db.collection('users').snapshots().map((q) {
    final all = q.docs.map((d) => AdminStudent.fromDoc(d)).toList();

    return all.where((s) => s.role == 'student').toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  });
});

final filteredAdminStudentsProvider = Provider.autoDispose<List<AdminStudent>>((ref) {
  final students = ref.watch(adminStudentsProvider).valueOrNull ?? [];
  final query = ref.watch(adminStudentsSearchProvider).trim().toLowerCase();

  if (query.isEmpty) return students;

  return students.where((s) {
    return s.fullName.toLowerCase().contains(query) ||
        s.firstName.toLowerCase().contains(query) ||
        s.lastName.toLowerCase().contains(query) ||
        s.studentId.toLowerCase().contains(query) ||
        s.email.toLowerCase().contains(query);
  }).toList();
});

final adminStudentHistoryProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, uid) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);

  return db
      .collection('users')
      .doc(uid)
      .collection('history')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs);
});