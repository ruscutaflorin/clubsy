import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

enum MapMilestoneKind { club, city }

const _clubOrdinals = {1, 5, 10, 25, 50, 100};

class MapMilestone {
  final MapMilestoneKind kind;

  /// Distinct-club count reached (club milestones); 0 for city milestones.
  final int ordinal;
  final ClubModel club;
  final String city;
  final DateTime night;

  const MapMilestone({
    required this.kind,
    required this.ordinal,
    required this.club,
    required this.city,
    required this.night,
  });
}

/// Pure: replays check-ins oldest first and returns milestones newest first.
List<MapMilestone> mapMilestones(List<CheckInModel> checkIns) {
  final sorted = [...checkIns]
    ..sort((a, b) => a.checkedInAt.compareTo(b.checkedInAt));
  final clubIds = <String>{};
  final cities = <String>{};
  final result = <MapMilestone>[];
  for (final c in sorted) {
    final night = nightOf(c.checkedInAt.toLocal());
    final city = c.club.city.trim();
    final cityKey = city.toLowerCase();
    if (cityKey.isNotEmpty && cities.add(cityKey) && cities.length > 1) {
      result.add(
        MapMilestone(
          kind: MapMilestoneKind.city,
          ordinal: 0,
          club: c.club,
          city: city,
          night: night,
        ),
      );
    }
    if (clubIds.add(c.club.id) && _clubOrdinals.contains(clubIds.length)) {
      result.add(
        MapMilestone(
          kind: MapMilestoneKind.club,
          ordinal: clubIds.length,
          club: c.club,
          city: city,
          night: night,
        ),
      );
    }
  }
  return result.reversed.toList();
}

String _ordinal(int n) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

String milestoneLabel(MapMilestone m) => m.kind == MapMilestoneKind.club
    ? '${_ordinal(m.ordinal)} club: ${m.club.name}'
    : 'First night in ${m.city}';
