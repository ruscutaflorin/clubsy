import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

class BiggestNight {
  final DateTime night;
  final int clubs;

  const BiggestNight(this.night, this.clubs);
}

class BusiestMonth {
  final int year;
  final int month;
  final int nights;

  const BusiestMonth(this.year, this.month, this.nights);
}

class PersonalRecords {
  final BiggestNight biggestNight;
  final BusiestMonth busiestMonth;
  final DateTime firstNight;
  final String mostVisitedCity;

  const PersonalRecords({
    required this.biggestNight,
    required this.busiestMonth,
    required this.firstNight,
    required this.mostVisitedCity,
  });
}

/// Personal bests derived from check-ins, or null when there are none.
PersonalRecords? personalRecords(List<CheckInModel> checkIns) {
  if (checkIns.isEmpty) return null;
  // Newest night first, so a strict `>` keeps the most recent on ties.
  final groups = groupByNight(checkIns);

  var biggest = groups.first;
  for (final g in groups) {
    if (g.clubCount > biggest.clubCount) biggest = g;
  }

  final monthNights = <int, int>{};
  int keyOf(DateTime d) => d.year * 12 + d.month - 1;
  for (final g in groups) {
    final key = keyOf(g.night);
    monthNights[key] = (monthNights[key] ?? 0) + 1;
  }
  var busiestKey = keyOf(groups.first.night);
  for (final g in groups) {
    final key = keyOf(g.night);
    if (monthNights[key]! > monthNights[busiestKey]!) busiestKey = key;
  }

  final cityNights = <String, int>{};
  for (final g in groups) {
    for (final city in g.checkIns.map((c) => c.club.city).toSet()) {
      cityNights[city] = (cityNights[city] ?? 0) + 1;
    }
  }
  final cities = cityNights.keys.toList()
    ..sort((a, b) {
      final byCount = cityNights[b]!.compareTo(cityNights[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });

  return PersonalRecords(
    biggestNight: BiggestNight(biggest.night, biggest.clubCount),
    busiestMonth: BusiestMonth(
      busiestKey ~/ 12,
      busiestKey % 12 + 1,
      monthNights[busiestKey]!,
    ),
    firstNight: groups.last.night,
    mostVisitedCity: cities.first,
  );
}
