import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase_providers.dart';

/// Stream a user profile doc by uid.
final userDocProvider = StreamProvider.family
    .autoDispose<DocumentSnapshot<Map<String, dynamic>>, String>((ref, uid) {
  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots();
});

class GateScreen extends ConsumerWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    if (authAsync.isLoading) {
      return const _GateLoading(text: 'Checking session...');
    }

    final user = authAsync.asData?.value;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const _GateLoading(text: 'Redirecting to login...');
    }

    final profileAsync = ref.watch(userDocProvider(user.uid));

    return profileAsync.when(
      loading: () => const _GateLoading(text: 'Loading profile...'),
      error: (e, _) {
        // This is the important part: if rules block the read, you'll land here.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref.read(firebaseAuthProvider).signOut();
          if (context.mounted) context.go('/login');
        });
        return _GateLoading(text: 'Profile load error: $e');
      },
      data: (doc) {
        final data = doc.data();

        // If doc doesn't exist -> this will also look like "loading forever" in your mind.
        // Here we fail fast and send you back to login.
        if (!doc.exists || data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref.read(firebaseAuthProvider).signOut();
            if (context.mounted) context.go('/login');
          });
          return const _GateLoading(
            text: 'No Firestore user profile found.\nCreate users/{uid} document.',
          );
        }

        final role = (data['role'] ?? '') as String; // "admin" | "student"
        final status = (data['status'] ?? 'active') as String;

        if (status != 'active') {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref.read(firebaseAuthProvider).signOut();
            if (context.mounted) context.go('/login');
          });
          return const _GateLoading(text: 'Account not active...');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(role == 'admin' ? '/admin' : '/');
        });

        return const _GateLoading(text: 'Opening app...');
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  final String text;
  const _GateLoading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}