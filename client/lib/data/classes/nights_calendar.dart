import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

class NightsCalendarData {
  /// Night date (date-only) to the names of the clubs visited that night.
  final Map<DateTime, List<String>> nights;
  final int nightsOut;
  final int longestGapDays;

  const NightsCalendarData({
    required this.nights,
    required this.nightsOut,
    required this.longestGapDays,
  });
}

/// The nights out in [year], keyed by the evening they began on.
NightsCalendarData nightsCalendar(List<CheckInModel> checkIns, int year) {
  final nights = <DateTime, List<String>>{};
  for (final checkIn in checkIns) {
    final night = nightOf(checkIn.checkedInAt.toLocal());
    if (night.year != year) continue;
    final names = nights.putIfAbsent(night, () => []);
    if (!names.contains(checkIn.club.name)) names.add(checkIn.club.name);
  }
  final dates = nights.keys.toList()..sort();
  var longestGap = 0;
  for (var i = 1; i < dates.length; i++) {
    // Calendar-day difference, immune to DST shifts.
    final gap = DateTime.utc(dates[i].year, dates[i].month, dates[i].day)
        .difference(
          DateTime.utc(dates[i - 1].year, dates[i - 1].month, dates[i - 1].day),
        )
        .inDays;
    if (gap > longestGap) longestGap = gap;
  }
  return NightsCalendarData(
    nights: nights,
    nightsOut: nights.length,
    longestGapDays: longestGap,
  );
}
