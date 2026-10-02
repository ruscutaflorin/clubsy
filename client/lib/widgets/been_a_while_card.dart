import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/been_a_while.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

/// "Been a while" card: favourite clubs the user hasn't visited lately.
class BeenAWhileCard extends StatelessWidget {
  final DateTime? now;

  const BeenAWhileCard({super.key, this.now});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final entries = beenAWhile(
        controller.myCheckIns.toList(),
        now ?? DateTime.now(),
      );
      if (entries.isEmpty) return const SizedBox.shrink();
      return Card(
        key: const Key('beenAWhileCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Been a while',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final e in entries)
                InkWell(
                  onTap: () => Get.to(() => ClubDetailsPage(club: e.club)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${e.club.name} · last on ${formatShortDate(e.lastNight)} · ${e.nights} nights',
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
