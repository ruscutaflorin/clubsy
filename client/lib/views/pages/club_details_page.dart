import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clubsy/data/classes/club_directions.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/location_lookup.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/check_in_primer_page.dart';

class ClubDetailsPage extends StatefulWidget {
  final ClubModel club;

  const ClubDetailsPage({super.key, required this.club});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  String? _distance;

  ClubModel get club => widget.club;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    final position = await positionIfPermitted();
    if (position == null || !mounted) return;
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      club.latitude,
      club.longitude,
    );
    setState(() => _distance = formatDistance(meters));
  }

  Future<void> _openDirections() async {
    final uri = directionsUri(club, defaultTargetPlatform);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar('Directions', 'No maps app available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(club.name),
        actions: [
          IconButton(
            key: const Key('shareClub'),
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => Share.share(clubShareText(club)),
          ),
        ],
      ),
      body: Obx(() {
        final summary = clubController.visitSummaryFor(club.id);
        final isVisited = summary != null;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  club.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                club.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('${club.address}, ${club.city}'),
              if (_distance != null) ...[
                const SizedBox(height: 4),
                Text('$_distance from you'),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('directionsButton'),
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                onPressed: _openDirections,
              ),
              const SizedBox(height: 8),
              if (!isVisited)
                Text(
                  'Not on your map yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (isVisited) ...[
                const Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text('Checked in before'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.visits == 1
                      ? '1 visit · on ${formatShortDate(summary.firstVisit)}'
                      : '${summary.visits} visits · last on '
                            '${formatShortDate(summary.lastVisit)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Check in'),
                  onPressed: () => openCheckIn(club),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
