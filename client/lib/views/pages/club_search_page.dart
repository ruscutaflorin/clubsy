import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      body: Obx(() {
        if (searchController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (searchController.query.value.trim().isEmpty) {
          return const Center(child: Text('Start typing to search clubs'));
        }

        if (searchController.results.isEmpty) {
          return const Center(child: Text('No clubs found'));
        }

        final visited = clubController.visitedClubIds;

        return ListView.builder(
          itemCount: searchController.results.length,
          itemBuilder: (context, index) {
            final club = searchController.results[index];
            final isVisited = visited.contains(club.id);

            return ListTile(
              leading: Icon(
                isVisited ? Icons.check_circle : Icons.location_on_outlined,
                color: isVisited ? Colors.green : null,
              ),
              title: Text(club.name),
              subtitle: Text(club.city),
              onTap: () => Get.to(() => ClubDetailsPage(club: club)),
            );
          },
        );
      }),
    );
  }
}
