import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/branded_app_bar.dart';
import 'admin_student_details_screen.dart';
import 'providers/admin_students_providers.dart';

class AdminStudentsScreen extends ConsumerWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final filtered = ref.watch(filteredAdminStudentsProvider);
    final search = ref.watch(adminStudentsSearchProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Students',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, surname, ID, or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () => ref
                      .read(adminStudentsSearchProvider.notifier)
                      .state = '',
                  icon: const Icon(Icons.close),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) =>
              ref.read(adminStudentsSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final s = filtered[i];

                    final statusColor = s.status == 'active'
                        ? Colors.green
                        : Colors.red;

                    return Card(
                      color: const Color(0xFFEAF4FF),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminStudentDetailsScreen(student: s),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.person, size: 28),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s.fullName.isEmpty ? '(No name)' : s.fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.studentId.isEmpty ? 'No ID' : s.studentId,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.status.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${s.pointsBalance} coins • ${s.totalLaundries} washes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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