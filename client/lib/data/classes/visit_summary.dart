import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

class VisitSummary {
  final int visits;
  final DateTime firstVisit;
  final DateTime lastVisit;

  VisitSummary({
    required this.visits,
    required this.firstVisit,
    required this.lastVisit,
  });
}

/// Pure: summarises a user's visits to one club from their full check-in
/// history. Returns null when there are none, so callers can skip rendering.
VisitSummary? visitSummaryForClub(String clubId, List<CheckInModel> checkIns) {
  final matches = checkIns.where((c) => c.clubId == clubId);
  if (matches.isEmpty) return null;

  var first = matches.first.checkedInAt;
  var last = matches.first.checkedInAt;
  for (final checkIn in matches) {
    if (checkIn.checkedInAt.isBefore(first)) first = checkIn.checkedInAt;
    if (checkIn.checkedInAt.isAfter(last)) last = checkIn.checkedInAt;
  }

  return VisitSummary(
    visits: matches.length,
    firstVisit: first,
    lastVisit: last,
  );
}

/// Pure: the distinct nights (date-only, newest first) a user spent at one
/// club. A small-hours check-in counts towards the previous evening.
List<DateTime> nightsAtClub(String clubId, List<CheckInModel> checkIns) {
  final nights = <DateTime>{
    for (final c in checkIns)
      if (c.clubId == clubId) nightOf(c.checkedInAt.toLocal()),
  }.toList();
  nights.sort((a, b) => b.compareTo(a));
  return nights;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sat 14 Mar 2026" for a date-only night.
String formatNightRow(DateTime night) =>
    '${_weekdays[night.weekday - 1]} ${night.day} '
    '${_months[night.month - 1]} ${night.year}';

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

/// "12 Sep", in local time. Hand-rolled so the app doesn't need intl.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}
