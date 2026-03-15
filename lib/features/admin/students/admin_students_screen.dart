import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../../../core/widgets/branded_app_bar.dart';

final adminStudentsProvider =
StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('users')
      .where('role', isEqualTo: 'student')
      .snapshots()
      .map((q) => q.docs);
});

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, surname, ID, or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _search = v.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 14),

          /// Students grid
          Expanded(
            child: studentsAsync.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (docs) {
                final filtered = docs.where((d) {
                  final data = d.data();

                  final name =
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                      .toLowerCase();
                  final id = (data['studentId'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();

                  return name.contains(_search) ||
                      id.contains(_search) ||
                      email.contains(_search);
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,

                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, i) {
                    final data = filtered[i].data();

                    final firstName = data['firstName'] ?? '';
                    final lastName = data['lastName'] ?? '';
                    final studentId = data['studentId'] ?? '';
                    final status = data['status'] ?? 'active';

                    final coins =
                    ((data['pointsBalance'] ?? 0) as num).toInt();
                    final laundries =
                    ((data['totalLaundries'] ?? 0) as num).toInt();

                    final isActive = status == 'active';

                    return Card(
                      elevation: 2,
                      color: const Color(0xFFE6F2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            /// Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.purple.withOpacity(0.15),
                              child: const Icon(Icons.person, size: 30),
                            ),

                            const SizedBox(height: 10),

                            /// Name
                            Text(
                              '$firstName $lastName',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// Student ID
                            Text(
                              studentId,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'ACTIVE' : 'SUSPENDED',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            /// Coins + washes
                            Text(
                              '$coins coins • $laundries washes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}