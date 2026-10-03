import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

const _rhythmMinNights = 3;
const _arrivalOriginMinutes = 18 * 60;

class GoingOutRhythm {
  /// Distinct nights per weekday of the evening they began on, Monday first.
  final List<int> nightsByWeekday;

  /// Index into [nightsByWeekday] of the busiest weekday (ties: the later one).
  final int topWeekday;

  /// Median first check-in time of a night, rounded to 15 minutes.
  final ({int hour, int minute}) typicalArrival;

  const GoingOutRhythm({
    required this.nightsByWeekday,
    required this.topWeekday,
    required this.typicalArrival,
  });
}

/// Which nights the user goes out and when they usually arrive, or null with
/// fewer than 3 distinct nights.
GoingOutRhythm? goingOutRhythm(List<CheckInModel> checkIns) {
  final firstByNight = <DateTime, DateTime>{};
  for (final checkIn in checkIns) {
    final local = checkIn.checkedInAt.toLocal();
    final night = nightOf(local);
    final first = firstByNight[night];
    if (first == null || local.isBefore(first)) firstByNight[night] = local;
  }
  if (firstByNight.length < _rhythmMinNights) return null;

  final counts = List<int>.filled(7, 0);
  for (final night in firstByNight.keys) {
    counts[night.weekday - 1]++;
  }
  var top = 0;
  for (var i = 0; i < 7; i++) {
    if (counts[i] >= counts[top]) top = i;
  }

  final minutes =
      firstByNight.values
          .map(
            (t) =>
                (t.hour * 60 + t.minute - _arrivalOriginMinutes + 1440) % 1440,
          )
          .toList()
        ..sort();
  final mid = minutes.length ~/ 2;
  final median = minutes.length.isOdd
      ? minutes[mid].toDouble()
      : (minutes[mid - 1] + minutes[mid]) / 2;
  final rounded = ((median / 15).round() * 15 + _arrivalOriginMinutes) % 1440;
  return GoingOutRhythm(
    nightsByWeekday: counts,
    topWeekday: top,
    typicalArrival: (hour: rounded ~/ 60, minute: rounded % 60),
  );
}
