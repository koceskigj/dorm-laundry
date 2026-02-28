import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/achievement.dart';

class AchievementDetailsScreen extends StatelessWidget {
  final Achievement achievement;
  final DateTime unlockedAt;

  const AchievementDetailsScreen({
    super.key,
    required this.achievement,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder “full image”
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(achievement.description),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Reward: +${achievement.rewardCoins} Goce Coins',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_available, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Unlocked: ${DateFormat('EEE, d MMM yyyy').format(unlockedAt)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}