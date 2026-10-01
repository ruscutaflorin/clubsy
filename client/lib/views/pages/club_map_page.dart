import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

class ClubMapPage extends StatelessWidget {
  const ClubMapPage({super.key});

  static const LatLng _defaultCenter = LatLng(51.509865, -0.118092); // London

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: clubController.refresh,
        child: Obx(() {
          if (clubController.isLoading.value && clubController.clubs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final clubs = clubController.clubs;
          final visited = clubController.visitedClubIds;
          final center = clubs.isNotEmpty
              ? LatLng(clubs.first.latitude, clubs.first.longitude)
              : _defaultCenter;

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.clubsy.app',
              ),
              MarkerLayer(
                markers: clubs.map((club) {
                  final isVisited = visited.contains(club.id);
                  return Marker(
                    point: LatLng(club.latitude, club.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => Get.to(() => ClubDetailsPage(club: club)),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: isVisited ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ),
    );
  }
}
