import 'package:clubsy/data/classes/check_in_model.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

/// Hour at which a night rolls over (06:00 to 06:00), as in the server's `night.js`
/// but in local time.
const nightStartHour = 6;

/// The calendar date (local midnight) of the evening a night began on.
DateTime nightOf(DateTime local) {
  final shifted = local.subtract(const Duration(hours: nightStartHour));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

class NightGroup {
  final DateTime night;
  final List<CheckInModel> checkIns;

  NightGroup(this.night, this.checkIns);

  int get clubCount => checkIns.map((c) => c.clubId).toSet().length;
}

/// Groups check-ins by night, newest night first and newest check-in first
/// inside each group.
List<NightGroup> groupByNight(List<CheckInModel> checkIns) {
  final sorted = [...checkIns]
    ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));
  final groups = <NightGroup>[];
  for (final checkIn in sorted) {
    final night = nightOf(checkIn.checkedInAt.toLocal());
    if (groups.isNotEmpty && groups.last.night == night) {
      groups.last.checkIns.add(checkIn);
    } else {
      groups.add(NightGroup(night, [checkIn]));
    }
  }
  return groups;
}

/// Keeps the check-ins whose club name or city contains the trimmed [query]
/// (case-insensitive) and drops nights left empty. An empty query keeps all.
List<NightGroup> filterNightGroups(List<NightGroup> groups, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return groups;
  final result = <NightGroup>[];
  for (final group in groups) {
    final matches = group.checkIns
        .where(
          (c) =>
              c.club.name.toLowerCase().contains(q) ||
              c.club.city.toLowerCase().contains(q),
        )
        .toList();
    if (matches.isNotEmpty) result.add(NightGroup(group.night, matches));
  }
  return result;
}

/// Keeps the check-ins rated [minVibe] or more and drops nights left empty.
List<NightGroup> filterBestNights(List<NightGroup> groups, {int minVibe = 4}) {
  final result = <NightGroup>[];
  for (final group in groups) {
    final best = group.checkIns
        .where((c) => c.vibe != null && c.vibe! >= minVibe)
        .toList();
    if (best.isNotEmpty) result.add(NightGroup(group.night, best));
  }
  return result;
}

/// "Sat 12 Sep", with a year suffix ("Sat 12 Sep 2025") outside [now]'s year.
String formatNightLabel(DateTime night, {DateTime? now}) {
  final year = (now ?? DateTime.now()).year;
  final base =
      '${_weekdays[night.weekday - 1]} ${night.day} ${_months[night.month - 1]}';
  return night.year == year ? base : '$base ${night.year}';
}

/// "HH:mm" of a local time.
String formatTime(DateTime local) =>
    '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

/// "Sat 12 Sep · 2 clubs"
String formatGroupHeader(NightGroup group, {DateTime? now}) =>
    '${formatNightLabel(group.night, now: now)} · ${_plural(group.clubCount, 'club')}';

/// "This month: 3 nights · 5 clubs", or null when nothing happened this month.
String? monthSummary(List<CheckInModel> checkIns, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final inMonth = groupByNight(checkIns)
      .where((g) => g.night.year == today.year && g.night.month == today.month)
      .toList();
  if (inMonth.isEmpty) return null;
  final clubs = inMonth.expand((g) => g.checkIns).map((c) => c.clubId).toSet();
  return 'This month: ${_plural(inMonth.length, 'night')} · ${_plural(clubs.length, 'club')}';
}
