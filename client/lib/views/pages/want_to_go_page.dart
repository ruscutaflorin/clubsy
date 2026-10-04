import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/club_profile.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

class WantToGoPage extends StatelessWidget {
  const WantToGoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClubController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Want to go')),
      body: Obx(() {
        final entries = wantToGoList(
          controller.clubs.toList(),
          controller.favoriteIds.toSet(),
          controller.myCheckIns.toList(),
        );
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nothing saved yet. Tap the heart on a club to add it here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          children: [for (final e in entries) _row(controller, e)],
        );
      }),
    );
  }

  Widget _row(ClubController controller, WantToGoEntry e) {
    final club = e.club;
    final status = openingChipText(club.openingHours, club.localNow);
    final detail = openingDetailText(club.openingHours, club.localNow);
    final visited = e.nights == 0
        ? 'Not been yet'
        : 'Been · ${e.nights} ${e.nights == 1 ? 'night' : 'nights'}';
    return ListTile(
      key: Key('wantToGo_${club.id}'),
      title: Text(club.name),
      subtitle: Text(
        status == null
            ? club.city
            : [club.city, status, if (detail != null) detail].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(visited),
          IconButton(
            key: Key('unfavorite_${club.id}'),
            icon: const Icon(Icons.favorite),
            onPressed: () => controller.toggleFavorite(club.id),
          ),
        ],
      ),
      onTap: () => Get.to(() => ClubDetailsPage(club: club)),
    );
  }
}
