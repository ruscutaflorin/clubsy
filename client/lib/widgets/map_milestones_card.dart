import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/map_milestones.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

const _collapsedRows = 5;

/// "Map milestones" card: 1st/10th club and first night in each city.
class MapMilestonesCard extends StatefulWidget {
  const MapMilestonesCard({super.key});

  @override
  State<MapMilestonesCard> createState() => _MapMilestonesCardState();
}

class _MapMilestonesCardState extends State<MapMilestonesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final all = mapMilestones(controller.myCheckIns.toList());
      if (all.isEmpty) return const SizedBox.shrink();
      final shown = _expanded ? all : all.take(_collapsedRows).toList();
      return Card(
        key: const Key('mapMilestonesCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map milestones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final m in shown)
                InkWell(
                  onTap: () => Get.to(() => ClubDetailsPage(club: m.club)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${milestoneLabel(m)} · ${formatShortDate(m.night)}',
                    ),
                  ),
                ),
              if (!_expanded && all.length > _collapsedRows)
                TextButton(
                  key: const Key('milestonesShowAll'),
                  onPressed: () => setState(() => _expanded = true),
                  child: Text('Show all (${all.length})'),
                ),
            ],
          ),
        ),
      );
    });
  }
}
