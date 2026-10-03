import 'package:clubsy/data/classes/club_footfall_model.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

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

String _pct(double v) => '${(v * 100).round()}%';

/// "2026-09-07" -> "7 Sep"; falls back to the raw string if unparseable.
String _shortDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_months[d.month - 1]}';
}

/// Plain-text venue report to paste into a message. Aggregates only: no
/// user ids, names, emails or distances.
String footfallSummaryText(String clubName, ClubFootfallModel m) {
  final lines = <String>[
    '$clubName · Clubsy verified check-ins, last ${m.weekly.length} weeks',
    'Check-ins: ${m.totalCheckIns}',
    'Unique visitors: ${m.uniqueVisitors}',
    'Returning visitors: ${_pct(m.returningVisitorRate)}',
    'First-time visitors: ${_pct(m.firstTimeShare)}',
  ];

  var bestDay = -1;
  var bestDayCount = 0;
  for (var i = 0; i < m.byWeekday.length && i < _weekdays.length; i++) {
    if (m.byWeekday[i] > bestDayCount) {
      bestDayCount = m.byWeekday[i];
      bestDay = i;
    }
  }
  if (bestDay >= 0) lines.add('Busiest night: ${_weekdays[bestDay]}');

  FootfallWeek? bestWeek;
  for (final w in m.weekly) {
    if (w.checkIns > 0 &&
        (bestWeek == null || w.checkIns >= bestWeek.checkIns)) {
      bestWeek = w;
    }
  }
  if (bestWeek != null) {
    lines.add(
      'Best week: week of ${_shortDate(bestWeek.weekStart)} · ${bestWeek.checkIns} check-ins',
    );
  }
  return lines.join('\n');
}
