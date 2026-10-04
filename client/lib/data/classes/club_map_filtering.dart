import 'package:clubsy/data/classes/club_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Pure: the clubs a map should render, filtered to visited-only or
/// want-to-go-only when asked (want-to-go wins if both are set).
List<ClubModel> clubsForMap(
  List<ClubModel> clubs,
  Set<String> visitedIds,
  bool visitedOnly, {
  Set<String> favoriteIds = const {},
  bool wantToGoOnly = false,
}) {
  if (wantToGoOnly) {
    return clubs.where((club) => favoriteIds.contains(club.id)).toList();
  }
  if (!visitedOnly) return clubs;
  return clubs.where((club) => visitedIds.contains(club.id)).toList();
}

/// Pure: the smallest bounds containing every club, or null for an empty list
/// so callers can fall back to a default center instead of fitting nothing.
LatLngBounds? boundsFor(List<ClubModel> clubs) {
  if (clubs.isEmpty) return null;

  var minLat = clubs.first.latitude;
  var maxLat = clubs.first.latitude;
  var minLng = clubs.first.longitude;
  var maxLng = clubs.first.longitude;

  for (final club in clubs) {
    if (club.latitude < minLat) minLat = club.latitude;
    if (club.latitude > maxLat) maxLat = club.latitude;
    if (club.longitude < minLng) minLng = club.longitude;
    if (club.longitude > maxLng) maxLng = club.longitude;
  }

  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}
