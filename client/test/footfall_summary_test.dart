import 'package:clubsy/data/classes/club_footfall_model.dart';
import 'package:clubsy/data/classes/footfall_summary.dart';
import 'package:flutter_test/flutter_test.dart';

ClubFootfallModel model({
  List<int> byWeekday = const [0, 0, 0, 0, 0, 9, 2],
  List<FootfallWeek>? weekly,
  double returning = 0.375,
  double firstTime = 0.625,
}) => ClubFootfallModel(
  totalCheckIns: 184,
  uniqueVisitors: 97,
  returningVisitorRate: returning,
  firstTimeShare: firstTime,
  weekly:
      weekly ??
      List.generate(
        12,
        (i) => FootfallWeek(
          weekStart: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
          checkIns: i == 6 ? 20 : 1,
          uniqueVisitors: 1,
        ),
      ),
  byWeekday: byWeekday,
);

void main() {
  test('busiest night comes from byWeekday index (0 = Monday)', () {
    expect(
      footfallSummaryText('Alpha', model()),
      contains('Busiest night: Saturday'),
    );
  });

  test('ties go to the earlier weekday', () {
    final t = footfallSummaryText(
      'Alpha',
      model(byWeekday: [0, 4, 0, 0, 4, 0, 0]),
    );
    expect(t, contains('Busiest night: Tuesday'));
  });

  test('all-zero data omits busiest night and best week', () {
    final t = footfallSummaryText(
      'Alpha',
      model(
        byWeekday: List.filled(7, 0),
        weekly: [
          const FootfallWeek(
            weekStart: '2026-09-07',
            checkIns: 0,
            uniqueVisitors: 0,
          ),
        ],
      ),
    );
    expect(t, isNot(contains('Busiest night')));
    expect(t, isNot(contains('Best week')));
  });

  test('best week formatted, ties go to the most recent', () {
    final t = footfallSummaryText(
      'Alpha',
      model(
        weekly: [
          const FootfallWeek(
            weekStart: '2026-09-07',
            checkIns: 5,
            uniqueVisitors: 3,
          ),
          const FootfallWeek(
            weekStart: '2026-09-14',
            checkIns: 5,
            uniqueVisitors: 3,
          ),
        ],
      ),
    );
    expect(t, contains('Best week: week of 14 Sep · 5 check-ins'));
  });

  test('guest vibe line only when an average is present', () {
    ClubFootfallModel withVibe(VibeSummary? v) => ClubFootfallModel(
      vibe: v,
      totalCheckIns: 1,
      uniqueVisitors: 1,
      returningVisitorRate: 0,
      firstTimeShare: 1,
      weekly: const [],
      byWeekday: const [],
    );
    expect(
      footfallSummaryText(
        'Alpha',
        withVibe(
          const VibeSummary(
            count: 27,
            average: 4.3,
            distribution: [0, 1, 4, 9, 13],
          ),
        ),
      ),
      contains('Guest vibe: ★4.3 from 27 ratings'),
    );
    expect(
      footfallSummaryText('Alpha', withVibe(const VibeSummary(count: 3))),
      isNot(contains('Guest vibe')),
    );
    expect(
      footfallSummaryText('Alpha', withVibe(null)),
      isNot(contains('Guest vibe')),
    );
  });

  test('summary lists the regulars count', () {
    final m = ClubFootfallModel(
      visitFrequency: const VisitFrequency(threePlus: 4),
      totalCheckIns: 1,
      uniqueVisitors: 1,
      returningVisitorRate: 0,
      firstTimeShare: 1,
      weekly: const [],
      byWeekday: const [],
    );
    expect(
      footfallSummaryText('Alpha', m),
      contains('Regulars (3+ nights): 4'),
    );
  });

  test('percentages are whole numbers; name and week count included', () {
    final t = footfallSummaryText('Alpha', model());
    expect(t, contains('Returning visitors: 38%'));
    expect(t, contains('First-time visitors: 63%'));
    expect(t, contains('Alpha'));
    expect(t, contains('last 12 weeks'));
    expect(t, contains('Check-ins: 184'));
    expect(t, contains('Unique visitors: 97'));
  });
}
