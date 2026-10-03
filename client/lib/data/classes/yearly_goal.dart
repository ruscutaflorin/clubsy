import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

class YearlyGoalProgress {
  final int year;
  final int goal;
  final int nightsSoFar;
  final int expectedByNow;

  const YearlyGoalProgress({
    required this.year,
    required this.goal,
    required this.nightsSoFar,
    required this.expectedByNow,
  });

  int get aheadBy => nightsSoFar - expectedByNow;
  bool get reached => nightsSoFar >= goal;
}

/// Progress of [goal] nights out in [now]'s year, counting distinct nights.
YearlyGoalProgress yearlyGoalProgress(
  List<CheckInModel> checkIns,
  int goal,
  DateTime now,
) {
  final nights = <DateTime>{};
  for (final c in checkIns) {
    final night = nightOf(c.checkedInAt.toLocal());
    if (night.year == now.year) nights.add(night);
  }
  final dayOfYear =
      DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime.utc(now.year, 1, 1)).inDays +
      1;
  final daysInYear = DateTime.utc(
    now.year + 1,
    1,
    1,
  ).difference(DateTime.utc(now.year, 1, 1)).inDays;
  return YearlyGoalProgress(
    year: now.year,
    goal: goal,
    nightsSoFar: nights.length,
    expectedByNow: goal * dayOfYear ~/ daysInYear,
  );
}

/// "Goal reached!", "2 ahead of pace", "1 behind pace" or "Right on pace".
String goalPaceLine(YearlyGoalProgress p) {
  if (p.reached) return 'Goal reached!';
  if (p.aheadBy > 0) return '${p.aheadBy} ahead of pace';
  if (p.aheadBy < 0) return '${-p.aheadBy} behind pace';
  return 'Right on pace';
}

/// "22 of 30 nights in 2026"
String goalHeadline(YearlyGoalProgress p) =>
    '${p.nightsSoFar} of ${p.goal} night${p.goal == 1 ? '' : 's'} in ${p.year}';
