import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/achievement.dart';

class AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;

  const AchievementTile({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.unlockedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = unlocked
        ? 'Unlocked • ${DateFormat('d MMM yyyy').format(unlockedAt!)}'
        : 'Locked';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: unlocked ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _IconBox(unlocked: unlocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: unlocked ? null : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+${achievement.rewardCoins}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: unlocked ? Theme.of(context).colorScheme.primary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final bool unlocked;
  const _IconBox({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: unlocked
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Icon(
        unlocked ? Icons.emoji_events : Icons.lock_outline,
        color: unlocked ? Theme.of(context).colorScheme.primary : Colors.grey[600],
      ),
    );
  }
}