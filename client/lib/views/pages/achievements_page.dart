import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/streak_nudge_banner.dart';

/// Material icon per badge id; artwork is a later design task.
IconData badgeIcon(String id) => switch (id) {
  'first_pin' => Icons.push_pin,
  'explorer_5' || 'explorer_15' => Icons.explore,
  'globetrotter_3' => Icons.public,
  'regular_5' => Icons.repeat,
  'night_owl' => Icons.nightlight_round,
  'weekend_warrior' => Icons.celebration,
  'streak_4' => Icons.local_fire_department,
  _ => Icons.emoji_events,
};

String streakLabel(int weeks) => '🔥 $weeks-week streak';

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Profile row summarising streak, points and badges; opens the full page.
class AchievementsSummaryTile extends StatelessWidget {
  final AchievementsModel achievements;
  final VoidCallback? onTap;

  const AchievementsSummaryTile({
    super.key,
    required this.achievements,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('achievementsTile'),
      leading: const Icon(Icons.emoji_events),
      title: Text(streakLabel(achievements.currentStreak)),
      subtitle: Text(
        '${achievements.points} pts · '
        '${achievements.earnedCount}/${achievements.badges.length} badges',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class AchievementsView extends StatelessWidget {
  final AchievementsModel achievements;

  const AchievementsView({super.key, required this.achievements});

  void _showBadge(BuildContext context, BadgeModel badge) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(badge.title),
        content: Text(
          badge.earned
              ? '${badge.description}\nEarned ${_date(badge.earnedAt!)}'
              : '${badge.description}\n${badge.current}/${badge.target}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endsAt = achievements.challenges
        .map((c) => c.endsAt)
        .whereType<DateTime>()
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          streakLabel(achievements.currentStreak),
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          'Longest: ${achievements.longestStreak} weeks · '
          '${achievements.points} pts',
        ),
        const SizedBox(height: 20),
        Text('This week', style: theme.textTheme.titleMedium),
        if (endsAt != null) Text('Ends ${_date(endsAt)}'),
        const SizedBox(height: 8),
        for (final c in achievements.challenges)
          Padding(
            key: Key('challenge_${c.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.title)),
                    Text('${c.current}/${c.target}'),
                    if (c.completed)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: c.target == 0 ? 0 : c.current / c.target,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const StreakNudgeBanner(),
        Text(
          'Badges (${achievements.earnedCount}/${achievements.badges.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final b in achievements.badges)
              InkWell(
                key: Key('badge_${b.id}'),
                onTap: () => _showBadge(context, b),
                child: Opacity(
                  opacity: b.earned ? 1 : 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        badgeIcon(b.id),
                        size: 40,
                        color: b.earned ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!b.earned)
                        Text(
                          '${b.current}/${b.target}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClubController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Obx(() {
        final a = controller.achievements.value;
        if (a == null) {
          return const Center(child: Text('No achievements yet'));
        }
        return AchievementsView(achievements: a);
      }),
    );
  }
}
