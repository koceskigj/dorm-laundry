import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/branded_app_bar.dart';
import 'achievement_details_screen.dart';
import 'providers/achievements_providers.dart';
import 'widgets/achievement_tile.dart';
import 'widgets/gift_friend_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(achievementsCatalogProvider);
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const GiftFriendCard(),
          const SizedBox(height: 10),

          const Text(
            'Achievements',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 10),

          // Achievements list
          catalogAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Error loading achievements: $e'),
            ),
            data: (catalog) {
              return unlockedAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Error loading unlocks: $e'),
                ),
                data: (unlockedMap) {
                  if (catalog.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No achievements found.\n'
                            'Create a Firestore collection "achievements" with docs (title, description, rewardCoins, order).',
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final a in catalog)
                        Builder(builder: (context) {
                          final ts = unlockedMap[a.id];
                          final unlocked = ts != null;
                          final unlockedAt = ts?.toDate();

                          return AchievementTile(
                            achievement: a,
                            unlocked: unlocked,
                            unlockedAt: unlockedAt,
                            onTap: unlockedAt == null
                                ? null
                                : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AchievementDetailsScreen(
                                    achievement: a,
                                    unlockedAt: unlockedAt,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}