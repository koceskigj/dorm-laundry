import 'package:dorm_laundry_app/features/notifications/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/achievements/achievements_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/history/ui/history_screen.dart';


import 'features/notifications/notifications_screen.dart';


class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  final _pages = const [
    BookingScreen(),
    NotificationsScreen(),
    AchievementsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final hasUnreadAsync = ref.watch(hasUnreadNotificationsProvider);
    final hasUnread = hasUnreadAsync.valueOrNull ?? false;

    final showDot = hasUnread && _index != 1; // hide dot while on News tab

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Book',
          ),

          NavigationDestination(
            icon: _DotIcon(
              showDot: showDot,
              child: const Icon(Icons.notifications),
            ),
            label: 'News',
          ),

          const NavigationDestination(
            icon: Icon(Icons.stars),
            label: 'Rewards',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _DotIcon extends StatelessWidget {
  final bool showDot;
  final Widget child;

  const _DotIcon({required this.showDot, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!showDot) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -1,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}