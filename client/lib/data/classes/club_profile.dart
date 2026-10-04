import 'package:clubsy/data/classes/club_model.dart';

/// Must match `server/src/utils/genres.js`.
const clubGenres = [
  'techno',
  'house',
  'hip-hop',
  'commercial',
  'rock',
  'latin',
  'drum-and-bass',
  'live',
];

/// Weekday keys in `DateTime.weekday` order (Monday = 1).
const weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

const weekdayLabels = {
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

int _minutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

List<({String open, String close})> _slots(
  Map<String, dynamic> hours,
  String day,
) {
  final raw = hours[day];
  if (raw is! List) return const [];
  return [
    for (final slot in raw)
      if (slot is Map && slot['open'] is String && slot['close'] is String)
        (open: slot['open'] as String, close: slot['close'] as String),
  ];
}

/// The text of the "Open now" / "Opens 23:00" chip for [now] (read as the
/// club's local time), or null when the club has no schedule at all.
///
/// A slot belongs to the day it opens on, so Friday 23:00-05:00 is still open
/// on Saturday 02:00.
String? openingChipText(Map<String, dynamic>? hours, DateTime now) {
  if (hours == null || hours.values.every((v) => v is! List || v.isEmpty)) {
    return null;
  }
  final today = weekdayKeys[now.weekday - 1];
  final yesterday = weekdayKeys[(now.weekday + 5) % 7];
  final minutes = now.hour * 60 + now.minute;

  final spillover = _slots(hours, yesterday).any(
    (s) => _minutes(s.close) < _minutes(s.open) && minutes < _minutes(s.close),
  );
  final todaySlots = _slots(hours, today);
  final openToday = todaySlots.any((s) {
    final start = _minutes(s.open);
    final end = _minutes(s.close);
    return end > start ? minutes >= start && minutes < end : minutes >= start;
  });
  if (spillover || openToday) return 'Open now';

  final later = todaySlots.where((s) => _minutes(s.open) > minutes).toList()
    ..sort((a, b) => _minutes(a.open).compareTo(_minutes(b.open)));
  return later.isEmpty ? 'Closed' : 'Opens ${later.first.open}';
}

/// One display row per weekday, e.g. Friday / `23:00-05:00`, or `Closed`.
List<({String day, String hours})> openingHoursRows(
  Map<String, dynamic>? hours,
) {
  return [
    for (final key in weekdayKeys)
      (
        day: weekdayLabels[key]!,
        hours: _rowText(hours == null ? const [] : _slots(hours, key)),
      ),
  ];
}

String _rowText(List<({String open, String close})> slots) => slots.isEmpty
    ? 'Closed'
    : slots.map((s) => '${s.open}-${s.close}').join(', ');

final _slotPattern = RegExp(
  r'^([01]\d|2[0-3]):[0-5]\d-([01]\d|2[0-3]):[0-5]\d$',
);

/// Parses the admin form's per-day text (`22:00-04:00, 12:00-14:00`; blank is
/// closed) into schedule slots, or null when any slot is malformed.
List<Map<String, String>>? parseHoursText(String? text) {
  final trimmed = text?.trim() ?? '';
  if (trimmed.isEmpty) return [];
  final slots = <Map<String, String>>[];
  for (final part in trimmed.split(',')) {
    final slot = part.trim();
    if (!_slotPattern.hasMatch(slot)) return null;
    final times = slot.split('-');
    if (times[0] == times[1]) return null;
    slots.add({'open': times[0], 'close': times[1]});
  }
  return slots.length > 4 ? null : slots;
}

/// Form validator for one day's hours text.
String? hoursTextError(String? text) =>
    parseHoursText(text) == null ? 'Use HH:MM-HH:MM, e.g. 23:00-05:00' : null;

/// The form text for one day of an existing schedule.
String hoursText(Map<String, dynamic>? hours, String day) {
  final slots = hours == null ? const [] : _slots(hours, day);
  return slots.map((s) => '${s.open}-${s.close}').join(', ');
}

/// "★ 4.3 · 27 ratings", or a hint while the server withholds the aggregate.
String vibeText(({double average, int count})? vibe) => vibe == null
    ? 'Not enough ratings yet'
    : '★ ${vibe.average.toStringAsFixed(1)} · ${vibe.count} ratings';

/// "You rated it ★4.3 over 5 nights" (or "1 night").
String myVibeText(({double average, int count}) v) =>
    'You rated it ★${v.average.toStringAsFixed(1)} over '
    '${v.count} ${v.count == 1 ? 'night' : 'nights'}';

/// Clubs matching [genre] (all of them when it is null).
List<ClubModel> clubsWithGenre(List<ClubModel> clubs, String? genre) =>
    genre == null
    ? clubs
    : clubs.where((c) => c.genres.contains(genre)).toList();

/// Clubs whose schedule says "Open now" at [now]; clubs without one are dropped.
List<ClubModel> clubsOpenAt(List<ClubModel> clubs, DateTime now) => clubs
    .where((c) => openingChipText(c.openingHours, now) == 'Open now')
    .toList();
