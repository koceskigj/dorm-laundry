import 'package:flutter/material.dart';

import 'features/achievements/achievements_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/notifications/ui/notifications_screen.dart';

import 'features/history/ui/history_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    BookingScreen(),
    NotificationsScreen(),
    AchievementsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Book'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'News'),
          NavigationDestination(icon: Icon(Icons.stars), label: 'Rewards'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}