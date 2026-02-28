import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/firebase_providers.dart';
import 'app_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/admin_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.read(authStateChangesProvider.stream),
    ),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final user = authAsync.asData?.value;

      final isLoginRoute = location == '/login';
      final isAdminRoute = location == '/admin';
      final isStudentRoute = location == '/';

      // Not logged in
      if (user == null) {
        return isLoginRoute ? null : '/login';
      }

      // Logged in → fetch role
      final db = ref.read(firestoreProvider);
      final doc = await db.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        return '/login';
      }

      final data = doc.data()!;
      final role = (data['role'] ?? '') as String;
      final status = (data['status'] ?? 'active') as String;

      if (status != 'active') {
        await FirebaseAuth.instance.signOut();
        return '/login';
      }

      // If on login page after login → redirect properly
      if (isLoginRoute) {
        return role == 'admin' ? '/admin' : '/';
      }

      // Prevent role crossing
      if (role == 'admin' && isStudentRoute) return '/admin';
      if (role == 'student' && isAdminRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}