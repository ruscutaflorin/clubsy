import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_profile.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/club_search_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

class ClubSearchPage extends StatelessWidget {
  const ClubSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = Get.find<ClubSearchController>();
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search clubs by name, address or city',
            border: InputBorder.none,
          ),
          onChanged: searchController.search,
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: Obx(
              () => ListView(
                key: const Key('genreFilter'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final g in clubGenres)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(g),
                        selected: searchController.genre.value == g,
                        onSelected: (_) => searchController.toggleGenre(g),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _results(searchController, clubController)),
        ],
      ),
    );
  }

  Widget _results(
    ClubSearchController searchController,
    ClubController clubController,
  ) {
    return Obx(() {
      if (searchController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (searchController.query.value.trim().isEmpty) {
        return const Center(child: Text('Start typing to search clubs'));
      }

      final results = searchController.filteredResults;
      if (results.isEmpty) {
        return const Center(child: Text('No clubs found'));
      }

      final visited = clubController.visitedClubIds;

      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final club = results[index];
          final isVisited = visited.contains(club.id);

          return ListTile(
            leading: Icon(
              isVisited ? Icons.check_circle : Icons.location_on_outlined,
              color: isVisited ? Colors.green : null,
            ),
            title: Text(club.name),
            subtitle: Text(
              club.vibe == null
                  ? club.city
                  : '${club.city} · ${vibeText(club.vibe)}',
            ),
            onTap: () => Get.to(() => ClubDetailsPage(club: club)),
          );
        },
      );
    });
  }
}
