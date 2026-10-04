import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/genre_taste.dart';

class Recap {
  final int nightsOut;
  final int distinctClubs;
  final int distinctCities;
  final ClubModel? topClub;
  final int topClubVisits;

  /// 1 = Monday .. 7 = Sunday, by the night a check-in belongs to.
  final int? busiestWeekday;
  final DateTime? latestNight;
  final int newClubs;
  final String? topGenre;

  const Recap({
    this.topGenre,
    required this.nightsOut,
    required this.distinctClubs,
    required this.distinctCities,
    required this.topClub,
    required this.topClubVisits,
    required this.busiestWeekday,
    required this.latestNight,
    required this.newClubs,
  });

  bool get isEmpty => nightsOut == 0;
}

class RecapComparison {
  final int nightsDelta;
  final int clubsDelta;
  final bool previousEmpty;

  const RecapComparison({
    required this.nightsDelta,
    required this.clubsDelta,
    required this.previousEmpty,
  });
}

RecapComparison compareRecaps(Recap current, Recap previous) => RecapComparison(
  nightsDelta: current.nightsOut - previous.nightsOut,
  clubsDelta: current.distinctClubs - previous.distinctClubs,
  previousEmpty: previous.isEmpty,
);

/// e.g. "+2 nights vs August"; null when there is nothing to compare against.
String? comparisonLine(RecapComparison c, String previousLabel) {
  if (c.previousEmpty) return null;
  final d = c.nightsDelta;
  if (d == 0) return 'Same number of nights as $previousLabel';
  final n = d.abs();
  final unit = n == 1 ? 'night' : 'nights';
  return '${d > 0 ? '+' : '-'}$n $unit vs $previousLabel';
}

const _nightStartHour = 6;

/// A night runs 06:00-06:00 local, so shifting back 6h gives its calendar day.
DateTime _nightDay(DateTime t) {
  final s = t.subtract(const Duration(hours: _nightStartHour));
  return DateTime(s.year, s.month, s.day);
}

/// Minutes since the 06:00 night start, so 05:30 is later than 23:00.
int _nightOffset(DateTime t) =>
    ((t.hour * 60 + t.minute) - _nightStartHour * 60) % 1440;

/// Pure: summarises check-ins with `from <= checkedInAt < to`. New clubs are
/// those whose first-ever visit in [checkIns] falls inside the period.
Recap buildRecap(
  List<CheckInModel> checkIns, {
  required DateTime from,
  required DateTime to,
}) {
  final all = checkIns.map((c) => (c, c.checkedInAt.toLocal())).toList();
  final inPeriod = all
      .where((e) => !e.$2.isBefore(from) && e.$2.isBefore(to))
      .toList();

  final nights = <DateTime>{};
  final weekdayNights = <int, Set<DateTime>>{};
  final visits = <String, int>{};
  final lastVisit = <String, DateTime>{};
  final clubs = <String, ClubModel>{};
  DateTime? latest;
  for (final (c, t) in inPeriod) {
    final day = _nightDay(t);
    nights.add(day);
    weekdayNights.putIfAbsent(day.weekday, () => {}).add(day);
    visits[c.clubId] = (visits[c.clubId] ?? 0) + 1;
    final prev = lastVisit[c.clubId];
    if (prev == null || t.isAfter(prev)) lastVisit[c.clubId] = t;
    clubs[c.clubId] = c.club;
    if (latest == null || _nightOffset(t) > _nightOffset(latest)) latest = t;
  }

  String? topId;
  for (final id in visits.keys) {
    if (topId == null ||
        visits[id]! > visits[topId]! ||
        (visits[id] == visits[topId] &&
            lastVisit[id]!.isAfter(lastVisit[topId]!))) {
      topId = id;
    }
  }

  int? weekday;
  for (var d = 1; d <= 7; d++) {
    final n = weekdayNights[d]?.length ?? 0;
    if (n > 0 && (weekday == null || n > weekdayNights[weekday]!.length)) {
      weekday = d;
    }
  }

  final firstEver = <String, DateTime>{};
  for (final (c, t) in all) {
    final prev = firstEver[c.clubId];
    if (prev == null || t.isBefore(prev)) firstEver[c.clubId] = t;
  }
  final newClubs = visits.keys.where((id) {
    final t = firstEver[id]!;
    return !t.isBefore(from) && t.isBefore(to);
  }).length;

  final genres = genreNights([for (final (c, _) in inPeriod) c]);

  return Recap(
    nightsOut: nights.length,
    distinctClubs: visits.length,
    distinctCities: clubs.values.map((c) => c.city).toSet().length,
    topClub: topId == null ? null : clubs[topId],
    topClubVisits: topId == null ? 0 : visits[topId]!,
    busiestWeekday: weekday,
    latestNight: latest,
    newClubs: newClubs,
    topGenre: genres.isEmpty ? null : genres.first.genre,
  );
}
