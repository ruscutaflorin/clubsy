import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

class BeenAWhileEntry {
  final ClubModel club;
  final int nights;
  final DateTime lastNight;
  final int daysSince;

  const BeenAWhileEntry({
    required this.club,
    required this.nights,
    required this.lastNight,
    required this.daysSince,
  });
}

/// Favourite clubs (at least [minNights] distinct nights) whose latest night is
/// at least [quietDays] days before tonight's night. Most nights first, then
/// most recent last night, capped at [limit].
List<BeenAWhileEntry> beenAWhile(
  List<CheckInModel> checkIns,
  DateTime now, {
  int minNights = 2,
  int quietDays = 30,
  int limit = 3,
}) {
  final today = nightOf(now);
  final nightsByClub = <String, Set<DateTime>>{};
  final clubs = <String, ClubModel>{};
  for (final c in checkIns) {
    nightsByClub
        .putIfAbsent(c.clubId, () => {})
        .add(nightOf(c.checkedInAt.toLocal()));
    clubs[c.clubId] = c.club;
  }
  final result = <BeenAWhileEntry>[];
  nightsByClub.forEach((clubId, nights) {
    final last = nights.reduce((a, b) => a.isAfter(b) ? a : b);
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(last.year, last.month, last.day)).inDays;
    if (nights.length < minNights || days < quietDays) return;
    result.add(
      BeenAWhileEntry(
        club: clubs[clubId]!,
        nights: nights.length,
        lastNight: last,
        daysSince: days,
      ),
    );
  });
  result.sort((a, b) {
    final byNights = b.nights.compareTo(a.nights);
    return byNights != 0 ? byNights : b.lastNight.compareTo(a.lastNight);
  });
  return result.take(limit).toList();
}
