import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clubsy/data/classes/club_directions.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_profile.dart';
import 'package:clubsy/services/location_lookup.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/feed_controller.dart';
import 'package:clubsy/views/pages/check_in_primer_page.dart';

const _maxNightRows = 20;

class ClubDetailsPage extends StatefulWidget {
  final ClubModel club;

  const ClubDetailsPage({super.key, required this.club});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  String? _distance;
  int _friendCount = 0;

  ClubModel get club => widget.club;

  @override
  void initState() {
    super.initState();
    _loadDistance();
    _loadFriendCount();
  }

  Future<void> _loadFriendCount() async {
    if (!Get.isRegistered<FeedController>()) return;
    final count = await Get.find<FeedController>().friendCountForClub(club.id);
    if (!mounted || count == 0) return;
    setState(() => _friendCount = count);
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

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) Get.snackbar('Link', 'Could not open $url');
  }

  List<Widget> _profileSection(BuildContext context) {
    final status = openingChipText(club.openingHours, club.localNow);
    final description = club.description;
    return [
      const SizedBox(height: 8),
      Text(vibeText(club.vibe), key: const Key('vibeText')),
      if (_friendCount > 0) ...[
        const SizedBox(height: 8),
        Text(
          friendsHaveBeenHereText(_friendCount),
          key: const Key('friendsHereText'),
        ),
      ],
      if (status != null) ...[
        const SizedBox(height: 8),
        Chip(
          key: const Key('openStatusChip'),
          avatar: Icon(
            Icons.access_time,
            size: 18,
            color: status == 'Open now' ? Colors.white : null,
          ),
          label: Text(status),
          backgroundColor: status == 'Open now' ? Colors.green : null,
          labelStyle: status == 'Open now'
              ? const TextStyle(color: Colors.white)
              : null,
        ),
      ],
      if (club.genres.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          key: const Key('genreChips'),
          spacing: 6,
          children: [for (final g in club.genres) Chip(label: Text(g))],
        ),
      ],
      if (description != null && description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(description),
      ],
      if (status != null)
        ExpansionTile(
          key: const Key('openingHoursTile'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Opening hours'),
          children: [
            for (final row in openingHoursRows(club.openingHours))
              ListTile(
                dense: true,
                title: Text(row.day),
                trailing: Text(row.hours),
              ),
          ],
        ),
      if (club.instagramUrl != null || club.websiteUrl != null)
        Wrap(
          spacing: 8,
          children: [
            if (club.instagramUrl != null)
              TextButton.icon(
                key: const Key('instagramLink'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Instagram'),
                onPressed: () => _openLink(club.instagramUrl!),
              ),
            if (club.websiteUrl != null)
              TextButton.icon(
                key: const Key('websiteLink'),
                icon: const Icon(Icons.language),
                label: const Text('Website'),
                onPressed: () => _openLink(club.websiteUrl!),
              ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(club.name),
        actions: [
          Obx(() {
            final isFavorite = clubController.favoriteIds.contains(club.id);
            return IconButton(
              key: const Key('favoriteToggle'),
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              color: isFavorite ? Colors.redAccent : null,
              tooltip: isFavorite ? 'Remove from Want to go' : 'Want to go',
              onPressed: () async {
                try {
                  await clubController.toggleFavorite(club.id);
                } catch (_) {
                  Get.snackbar('Want to go', 'Could not update your list');
                }
              },
            );
          }),
          IconButton(
            key: const Key('shareClub'),
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: clubShareText(club)),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final summary = clubController.visitSummaryFor(club.id);
        final isVisited = summary != null;

        final nights = isVisited
            ? nightsAtClub(club.id, clubController.myCheckIns)
            : <DateTime>[];
        final pairings = isVisited
            ? pairedClubs(club.id, clubController.myCheckIns)
            : <ClubPairing>[];

        return SingleChildScrollView(
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
              ..._profileSection(context),
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
                ExpansionTile(
                  key: const Key('nightsHereTile'),
                  tilePadding: EdgeInsets.zero,
                  title: Text('Your nights here (${nights.length})'),
                  children: [
                    for (final night in nights.take(_maxNightRows))
                      ListTile(dense: true, title: Text(formatNightRow(night))),
                    if (nights.length > _maxNightRows)
                      ListTile(
                        dense: true,
                        title: Text(
                          '+${nights.length - _maxNightRows} earlier nights',
                        ),
                      ),
                  ],
                ),
                if (pairings.isNotEmpty)
                  Column(
                    key: const Key('pairedClubs'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Often paired with',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final pairing in pairings)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(pairing.club.name),
                          subtitle: Text(
                            '${pairing.nights} '
                            '${pairing.nights == 1 ? 'night' : 'nights'} together',
                          ),
                          onTap: () =>
                              Get.to(() => ClubDetailsPage(club: pairing.club)),
                        ),
                    ],
                  ),
              ],
              const SizedBox(height: 16),
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
