import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/firebase_providers.dart';
import 'app_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/gate_screen.dart';
import 'features/admin/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.read(authStateChangesProvider.stream),
    ),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isLogin = loc == '/login';
      final isGate = loc == '/gate';

      if (authAsync.isLoading) return null;

      final user = authAsync.asData?.value;

      if (user == null) {
        return isLogin ? null : '/login';
      }

      // logged in: if on login, go gate (gate decides admin/student)
      if (isLogin) return '/gate';

      // allow gate to run
      if (isGate) return null;

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/gate',
        builder: (context, state) => const GateScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
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