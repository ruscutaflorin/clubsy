import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

/// Dismissible "keep your streak alive" card; empty unless the streak is at risk.
class StreakNudgeBanner extends StatelessWidget {
  const StreakNudgeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final a = controller.achievements.value;
      if (a == null ||
          !a.streakAtRisk ||
          controller.streakNudgeDismissed.value) {
        return const SizedBox.shrink();
      }
      return Card(
        key: const Key('streakNudgeBanner'),
        child: ListTile(
          leading: const Icon(Icons.local_fire_department),
          title: Text(
            'One night out this week keeps your ${a.currentStreak}-week streak',
          ),
          trailing: IconButton(
            key: const Key('streakNudgeDismiss'),
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss',
            onPressed: () => controller.streakNudgeDismissed.value = true,
          ),
        ),
      );
    });
  }
}
