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

String clubShareText(ClubModel club) =>
    '${club.name} in ${club.city} — on Clubsy';
