import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase_providers.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/booking/booking_screen.dart';

import 'features/history/history_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/notifications/providers/notification_providers.dart';

import 'features/achievements/providers/achievements_providers.dart' as ach;
import 'features/partners/screens/partners_screen.dart';

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
    PartnersScreen(),
  ];

  ProviderSubscription<AsyncValue<ach.AchievementInboxItem?>>? _achSub;

  @override
  void initState() {
    super.initState();

    _achSub = ref.listenManual<AsyncValue<ach.AchievementInboxItem?>>(
      ach.unreadAchievementPopupProvider,
          (prev, next) async {
        final item = next.valueOrNull;
        if (item == null) return;

        if (!mounted) return;

        // Show popup
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Congratulations!'),
            content: Text(
              'You’ve unlocked:\n\n'
                  '${item.title}\n\n'
                  'Reward: +${item.rewardCoins} Goce coins',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nice!'),
              ),
            ],
          ),
        );

        // Mark inbox item as read
        final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid == null) return;

        final db = ref.read(firestoreProvider);
        await ach.markAchievementInboxRead(db: db, uid: uid, inboxId: item.id);
      },
    );
  }

  @override
  void dispose() {
    _achSub?.close();
    super.dispose();
  }

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
          NavigationDestination(
            icon: Icon(Icons.apartment_rounded),
            label: 'Partners',
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