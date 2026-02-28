import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_providers.dart';

/// Stream that keeps the current user's points live.
final myPointsProvider = StreamProvider.autoDispose<int>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firestoreProvider);

  final uid = auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return db.collection('users').doc(uid).snapshots().map((doc) {
    final data = doc.data();
    final points = (data?['pointsBalance'] ?? 0) as num;
    return points.toInt();
  });
});

class BrandedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BrandedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(myPointsProvider);

    return AppBar(
      centerTitle: true,
      title: const _TextLogo(),
      leadingWidth: 120,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: pointsAsync.when(
          loading: () => const _CoinBadge(pointsText: '…'),
          error: (_, __) => const _CoinBadge(pointsText: '?'),
          data: (points) => _CoinBadge(pointsText: '$points'),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(firebaseAuthProvider).signOut(),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _TextLogo extends StatelessWidget {
  const _TextLogo();

  @override
  Widget build(BuildContext context) {
    // Later we can swap this for an Image.asset(...) logo.
    return const Text(
      'GOCE LAUNDRY',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final String pointsText;

  const _CoinBadge({required this.pointsText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Placeholder "coin" icon for now. Later we replace with your custom asset icon.
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(
            Icons.monetization_on_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            pointsText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}