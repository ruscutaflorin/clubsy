import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

class CityChecklistEntry {
  final ClubModel club;
  final int nights;
  final DateTime? lastNight;

  CityChecklistEntry({
    required this.club,
    required this.nights,
    this.lastNight,
  });

  bool get visited => nights > 0;
}

/// The approved clubs of [city] (case-insensitive, trimmed) with how many
/// distinct nights the user spent at each. Visited clubs first (most nights,
/// then most recent), then unvisited ones alphabetically.
List<CityChecklistEntry> cityChecklist(
  String city,
  List<ClubModel> clubs,
  List<CheckInModel> checkIns,
) {
  final wanted = city.trim().toLowerCase();
  final nightsByClub = <String, Set<DateTime>>{};
  for (final c in checkIns) {
    nightsByClub
        .putIfAbsent(c.clubId, () => {})
        .add(nightOf(c.checkedInAt.toLocal()));
  }
  final entries = <CityChecklistEntry>[];
  for (final club in clubs) {
    if (!club.isApproved || club.city.trim().toLowerCase() != wanted) continue;
    final nights = nightsByClub[club.id] ?? const <DateTime>{};
    DateTime? last;
    for (final n in nights) {
      if (last == null || n.isAfter(last)) last = n;
    }
    entries.add(
      CityChecklistEntry(club: club, nights: nights.length, lastNight: last),
    );
  }
  entries.sort((a, b) {
    if (a.visited != b.visited) return a.visited ? -1 : 1;
    if (a.visited) {
      final byNights = b.nights.compareTo(a.nights);
      if (byNights != 0) return byNights;
      return b.lastNight!.compareTo(a.lastNight!);
    }
    return a.club.name.toLowerCase().compareTo(b.club.name.toLowerCase());
  });
  return entries;
}
