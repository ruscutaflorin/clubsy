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

  return VisitSummary(visits: matches.length, firstVisit: first, lastVisit: last);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "12 Sep", in local time. Hand-rolled so the app doesn't need intl.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}
