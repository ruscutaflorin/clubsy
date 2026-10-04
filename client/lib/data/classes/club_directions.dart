import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:clubsy/data/classes/club_model.dart';

/// The maps-app URI for directions to [club]: `geo:` on Android, Apple Maps on
/// iOS. Other platforms fall back to a Google Maps web URL.
Uri directionsUri(ClubModel club, TargetPlatform platform) {
  final coords = '${club.latitude},${club.longitude}';
  final label = Uri.encodeComponent(club.name);
  switch (platform) {
    case TargetPlatform.android:
      return Uri.parse('geo:$coords?q=${Uri.encodeComponent(coords)}($label)');
    case TargetPlatform.iOS:
      return Uri.parse(
        'https://maps.apple.com/?daddr=${Uri.encodeComponent(coords)}',
      );
    default:
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${Uri.encodeComponent(coords)}',
      );
  }
}

/// "350 m" below one kilometre, otherwise kilometres with one decimal.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Great-circle distance in metres (haversine, Earth radius 6371000 m).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const radius = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * radius * math.asin(math.sqrt(h));
}

/// Approved clubs other than [club] within [maxMeters], nearest first.
List<({ClubModel club, double meters})> nearbyClubs(
  ClubModel club,
  List<ClubModel> clubs, {
  double maxMeters = 1000,
  int limit = 3,
}) {
  final result = <({ClubModel club, double meters})>[];
  for (final c in clubs) {
    if (!c.isApproved || c.id == club.id) continue;
    final meters = distanceMeters(
      club.latitude,
      club.longitude,
      c.latitude,
      c.longitude,
    );
    if (meters <= maxMeters) result.add((club: c, meters: meters));
  }
  result.sort((a, b) {
    final byDistance = a.meters.compareTo(b.meters);
    if (byDistance != 0) return byDistance;
    return a.club.name.toLowerCase().compareTo(b.club.name.toLowerCase());
  });
  return result.take(limit).toList();
}

String clubShareText(ClubModel club) =>
    '${club.name} in ${club.city} — on Clubsy';
