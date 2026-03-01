import 'package:flutter/material.dart';

import 'notifications/admin_notifications_screen.dart';
import 'stats/admin_stats_screen.dart';
import 'students/admin_students_screen.dart';
import 'today/today_bookings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    TodayBookingsScreen(),
    AdminNotificationsScreen(),
    AdminStudentsScreen(),
    AdminStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Notify'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Stats'),
        ],
      ),
    );
  }
}