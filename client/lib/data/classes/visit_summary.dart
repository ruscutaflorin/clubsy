import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

class VisitSummary {
  final int visits;
  final DateTime firstVisit;
  final DateTime lastVisit;

  VisitSummary({
    required this.visits,
    required this.firstVisit,
    required this.lastVisit,
  });
}

/// Pure: summarises a user's visits to one club from their full check-in
/// history. Returns null when there are none, so callers can skip rendering.
VisitSummary? visitSummaryForClub(String clubId, List<CheckInModel> checkIns) {
  final matches = checkIns.where((c) => c.clubId == clubId);
  if (matches.isEmpty) return null;

  var first = matches.first.checkedInAt;
  var last = matches.first.checkedInAt;
  for (final checkIn in matches) {
    if (checkIn.checkedInAt.isBefore(first)) first = checkIn.checkedInAt;
    if (checkIn.checkedInAt.isAfter(last)) last = checkIn.checkedInAt;
  }

  return VisitSummary(
    visits: matches.length,
    firstVisit: first,
    lastVisit: last,
  );
}

/// Pure: the distinct nights (date-only, newest first) a user spent at one
/// club. A small-hours check-in counts towards the previous evening.
List<DateTime> nightsAtClub(String clubId, List<CheckInModel> checkIns) {
  final nights = <DateTime>{
    for (final c in checkIns)
      if (c.clubId == clubId) nightOf(c.checkedInAt.toLocal()),
  }.toList();
  nights.sort((a, b) => b.compareTo(a));
  return nights;
}

/// Pure: the average of the user's own vibe ratings at one club, or null when
/// they never rated a night there.
({double average, int count})? myVibeAtClub(
  String clubId,
  List<CheckInModel> checkIns,
) {
  final vibes = [
    for (final c in checkIns)
      if (c.clubId == clubId && c.vibe != null) c.vibe!,
  ];
  if (vibes.isEmpty) return null;
  return (
    average: vibes.reduce((a, b) => a + b) / vibes.length,
    count: vibes.length,
  );
}

/// Pure: distinct nights per club id, for the map pins' count badges.
Map<String, int> nightsPerClub(List<CheckInModel> checkIns) {
  final nights = <String, Set<DateTime>>{};
  for (final c in checkIns) {
    (nights[c.club.id] ??= {}).add(nightOf(c.checkedInAt.toLocal()));
  }
  return {for (final e in nights.entries) e.key: e.value.length};
}

class WantToGoEntry {
  final ClubModel club;
  final int nights;

  WantToGoEntry({required this.club, required this.nights});
}

/// Pure: favourite clubs with their night counts, not-yet-visited first, then
/// alphabetical (case-insensitive). Favourite ids with no matching club are
/// skipped.
List<WantToGoEntry> wantToGoList(
  List<ClubModel> clubs,
  Set<String> favoriteIds,
  List<CheckInModel> checkIns,
) {
  final nights = nightsPerClub(checkIns);
  final entries = [
    for (final club in clubs)
      if (favoriteIds.contains(club.id))
        WantToGoEntry(club: club, nights: nights[club.id] ?? 0),
  ];
  entries.sort((a, b) {
    final byVisited = (a.nights > 0 ? 1 : 0).compareTo(b.nights > 0 ? 1 : 0);
    if (byVisited != 0) return byVisited;
    return a.club.name.toLowerCase().compareTo(b.club.name.toLowerCase());
  });
  return entries;
}

class ClubPairing {
  final ClubModel club;
  final int nights;

  ClubPairing({required this.club, required this.nights});
}

/// Pure: the other clubs a user combined with [clubId] on the same night,
/// most shared nights first (then most recent shared night, then name).
List<ClubPairing> pairedClubs(
  String clubId,
  List<CheckInModel> checkIns, {
  int limit = 3,
}) {
  final byNight = <DateTime, Map<String, ClubModel>>{};
  for (final c in checkIns) {
    final night = nightOf(c.checkedInAt.toLocal());
    (byNight[night] ??= {})[c.club.id] = c.club;
  }
  final counts = <String, int>{};
  final latest = <String, DateTime>{};
  final clubs = <String, ClubModel>{};
  byNight.forEach((night, nightClubs) {
    if (!nightClubs.containsKey(clubId)) return;
    nightClubs.forEach((id, club) {
      if (id == clubId) return;
      clubs[id] = club;
      counts[id] = (counts[id] ?? 0) + 1;
      if (latest[id] == null || night.isAfter(latest[id]!)) latest[id] = night;
    });
  });
  final ids = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      final byRecent = latest[b]!.compareTo(latest[a]!);
      if (byRecent != 0) return byRecent;
      return clubs[a]!.name.compareTo(clubs[b]!.name);
    });
  return [
    for (final id in ids.take(limit))
      ClubPairing(club: clubs[id]!, nights: counts[id]!),
  ];
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sat 14 Mar 2026" for a date-only night.
String formatNightRow(DateTime night) =>
    '${_weekdays[night.weekday - 1]} ${night.day} '
    '${_months[night.month - 1]} ${night.year}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "12 Sep", in local time. Hand-rolled so the app doesn't need intl.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}
