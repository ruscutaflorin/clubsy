import 'package:clubsy/data/classes/achievements_model.dart';

class NextGoal {
  final String badgeId;
  final String title;
  final int remaining;
  final int current;
  final int target;
  final String hint;

  const NextGoal({
    required this.badgeId,
    required this.title,
    required this.remaining,
    required this.current,
    required this.target,
    required this.hint,
  });

  double get progress => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

String _plural(int n, String one, String many) => n == 1 ? one : many;

String _hint(BadgeModel b, int n) {
  final id = b.id;
  if (id == 'first_pin') return 'Check in anywhere to unlock ${b.title}';
  if (id.startsWith('explorer_')) {
    return '$n more ${_plural(n, 'club', 'clubs')} to unlock ${b.title}';
  }
  if (id.startsWith('globetrotter_')) {
    return '$n more ${_plural(n, 'city', 'cities')} to unlock ${b.title}';
  }
  if (id.startsWith('regular_')) {
    return '$n more ${_plural(n, 'night', 'nights')} at one club to unlock '
        '${b.title}';
  }
  if (id.startsWith('streak_')) {
    return '$n more ${_plural(n, 'week', 'weeks')} in a row to unlock '
        '${b.title}';
  }
  return '$n to go for ${b.title}';
}

/// The unearned badges closest to being earned, most advanced first.
List<NextGoal> nextGoals(AchievementsModel a, {int limit = 2}) {
  final nothingEarned = a.earnedCount == 0;
  final candidates = <MapEntry<int, BadgeModel>>[];
  for (var i = 0; i < a.badges.length; i++) {
    final b = a.badges[i];
    if (b.earned) continue;
    if (b.current > 0 || (nothingEarned && b.id == 'first_pin')) {
      candidates.add(MapEntry(i, b));
    }
  }
  double ratio(BadgeModel b) => b.target <= 0 ? 0 : b.current / b.target;
  candidates.sort((x, y) {
    final r = ratio(y.value).compareTo(ratio(x.value));
    if (r != 0) return r;
    final d = (x.value.target - x.value.current).compareTo(
      y.value.target - y.value.current,
    );
    return d != 0 ? d : x.key.compareTo(y.key);
  });
  return candidates.take(limit < 0 ? 0 : limit).map((e) {
    final b = e.value;
    final remaining = (b.target - b.current).clamp(1, 1 << 30);
    return NextGoal(
      badgeId: b.id,
      title: b.title,
      remaining: remaining,
      current: b.current,
      target: b.target,
      hint: _hint(b, remaining),
    );
  }).toList();
}
