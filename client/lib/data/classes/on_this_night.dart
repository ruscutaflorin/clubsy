import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

class NightMemory {
  final String label;
  final DateTime nightDate;
  final List<ClubModel> clubs;

  NightMemory({
    required this.label,
    required this.nightDate,
    required this.clubs,
  });

  List<String> get clubNames => clubs.map((c) => c.name).toList();
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// Memories for the night [now] falls on: the same date exactly 1, 2, 3…
/// years ago, plus exactly one month ago. Nights are grouped as in
/// [nightOf], so a 02:00 check-in belongs to the previous evening.
List<NightMemory> onThisNight(List<CheckInModel> checkIns, DateTime now) {
  final byNight = <DateTime, List<CheckInModel>>{};
  for (final c in checkIns) {
    byNight.putIfAbsent(nightOf(c.checkedInAt.toLocal()), () => []).add(c);
  }
  if (byNight.isEmpty) return [];

  NightMemory? memory(String label, List<DateTime> candidates) {
    for (final date in candidates) {
      final found = byNight[date];
      if (found == null) continue;
      final sorted = [...found]
        ..sort((a, b) => a.checkedInAt.compareTo(b.checkedInAt));
      final seen = <String>{};
      return NightMemory(
        label: label,
        nightDate: date,
        clubs: [
          for (final c in sorted)
            if (seen.add(c.clubId)) c.club,
        ],
      );
    }
    return null;
  }

  final memories = <NightMemory>[];

  final month = now.month == 1 ? 12 : now.month - 1;
  final monthYear = now.month == 1 ? now.year - 1 : now.year;
  final monthAgo = DateTime(monthYear, month, now.day);
  if (monthAgo.month == month) {
    final m = memory('1 month ago', [monthAgo]);
    if (m != null) memories.add(m);
  }

  final oldest = byNight.keys
      .map((d) => d.year)
      .reduce((a, b) => a < b ? a : b);
  for (var n = 1; now.year - n >= oldest; n++) {
    final year = now.year - n;
    final candidates = <DateTime>[];
    if (now.month == 2 && now.day == 29) {
      if (_isLeap(year)) candidates.add(DateTime(year, 2, 29));
    } else {
      candidates.add(DateTime(year, now.month, now.day));
      // A 29 Feb night surfaces on 28 Feb when this year has no 29 Feb.
      if (now.month == 2 &&
          now.day == 28 &&
          !_isLeap(now.year) &&
          _isLeap(year)) {
        candidates.add(DateTime(year, 2, 29));
      }
    }
    final m = memory('$n year${n == 1 ? '' : 's'} ago', candidates);
    if (m != null) memories.add(m);
  }
  return memories;
}
