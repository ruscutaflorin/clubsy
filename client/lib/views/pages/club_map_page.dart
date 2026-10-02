import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:clubsy/services/location_lookup.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_map_filtering.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/club_search_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';
import 'package:clubsy/views/pages/club_search_page.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';

class ClubMapPage extends StatefulWidget {
  const ClubMapPage({super.key});

  @override
  State<ClubMapPage> createState() => _ClubMapPageState();
}

class _ClubMapPageState extends State<ClubMapPage> {
  static const LatLng _defaultCenter = LatLng(51.509865, -0.118092); // London

  final MapController _mapController = MapController();

  Future<void> _centreOnMe() async {
    final position = await positionIfPermitted();
    if (position == null) {
      // Never prompt from the map: explain, the check-in flow asks.
      await Get.dialog(
        AlertDialog(
          title: const Text('Location is off'),
          content: const Text(
            'Clubsy only reads your location when you check in, to confirm '
            'you are at the club. You will be asked the first time you check '
            'in.',
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('nearMeFab'),
        tooltip: 'Near me',
        onPressed: _centreOnMe,
        child: const Icon(Icons.my_location),
      ),
      body: RefreshIndicator(
        onRefresh: clubController.refresh,
        child: Obx(() {
          if (clubController.isLoading.value && clubController.clubs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final visited = clubController.visitedClubIds;
          final visitedOnly = clubController.visitedOnly.value;
          final clubs = clubsForMap(clubController.clubs, visited, visitedOnly);
          final bounds = boundsFor(clubs);
          final showEmptyHint = visitedOnly && clubs.isEmpty;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 13,
                  // maxZoom caps the fit when bounds has zero span (a single
                  // club, or several at the same point) - without it, fitting
                  // a zero-size box asks for infinite zoom and crashes.
                  initialCameraFit: bounds != null
                      ? CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(48),
                          maxZoom: 16,
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          onTap: () =>
                              Get.to(() => ClubDetailsPage(club: club)),
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
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('All')),
                              ButtonSegment(
                                value: true,
                                label: Text('Visited'),
                              ),
                            ],
                            selected: {visitedOnly},
                            onSelectionChanged: (selection) =>
                                clubController.visitedOnly.value =
                                    selection.first,
                          ),
                        ),
                      ),
                      Material(
                        color: Theme.of(context).cardColor,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Search clubs',
                          onPressed: () {
                            Get.put(ClubSearchController());
                            Get.to(() => const ClubSearchPage());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showEmptyHint)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "No check-ins yet — scan a club's QR to add your first pin",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (clubController.loadError.value != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: ErrorBanner(
                      error: clubController.loadError.value!,
                      savedAt: clubController.dataSavedAt.value,
                      onRetry: clubController.refresh,
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
