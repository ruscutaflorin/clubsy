import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/city_checklist.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

/// The clubs of one city, visited and not yet.
class CityChecklistPage extends StatelessWidget {
  final String city;

  const CityChecklistPage({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClubController>();
    return Scaffold(
      appBar: AppBar(title: Text(city)),
      body: Obx(() {
        final entries = cityChecklist(
          city,
          controller.clubs.toList(),
          controller.myCheckIns.toList(),
        );
        final visited = entries.where((e) => e.visited).toList();
        final missing = entries.where((e) => !e.visited).toList();
        final headline = Theme.of(context).textTheme.titleMedium;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${visited.length} of ${entries.length} clubs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (visited.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Visited', style: headline),
              for (final e in visited) _row(e, _visitedLabel(e)),
            ],
            if (entries.isNotEmpty && missing.isEmpty) ...[
              const SizedBox(height: 16),
              Text("You've been to every club in $city!", style: headline),
            ] else if (missing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Not been yet', style: headline),
              for (final e in missing) _row(e, e.club.name),
            ],
          ],
        );
      }),
    );
  }

  String _visitedLabel(CityChecklistEntry e) =>
      '${e.club.name} · ${e.nights} ${e.nights == 1 ? 'night' : 'nights'}'
      ' · last on ${formatShortDate(e.lastNight!)}';

  Widget _row(CityChecklistEntry e, String label) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    onTap: () => Get.to(() => ClubDetailsPage(club: e.club)),
  );
}
