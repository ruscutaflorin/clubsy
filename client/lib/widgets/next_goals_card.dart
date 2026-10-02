import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/next_goals.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

/// "Next up" card: the badges closest to unlocking. Empty when there are none.
class NextGoalsCard extends StatelessWidget {
  final VoidCallback? onTap;

  const NextGoalsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final a = controller.achievements.value;
      if (a == null) return const SizedBox.shrink();
      final goals = nextGoals(a);
      if (goals.isEmpty) return const SizedBox.shrink();
      return Card(
        key: const Key('nextGoalsCard'),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next up', style: Theme.of(context).textTheme.titleMedium),
                for (final g in goals) ...[
                  const SizedBox(height: 12),
                  Text(g.hint),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: g.progress),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
