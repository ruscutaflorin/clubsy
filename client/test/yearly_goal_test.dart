import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/yearly_goal.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/yearly_goal_card.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckInModel _ci(DateTime at) => CheckInModel(
  id: at.toIso8601String(),
  clubId: 'a',
  checkedInAt: at,
  verificationMethod: 'QR_GPS',
  distanceMeters: 10,
  club: ClubModel.fromMap({
    'id': 'a',
    'name': 'Club a',
    'address': '1 Main St',
    'city': 'Cluj',
    'latitude': 46,
    'longitude': 23.5,
    'imageUrl': 'http://img',
  }),
);

/// [n] check-ins on distinct evenings from 1 Feb 2026.
List<CheckInModel> _nights(int n) => [
  for (var i = 0; i < n; i++) _ci(DateTime(2026, 2, 1 + i, 22)),
];

void main() {
  final now = DateTime(2026, 7, 2, 12);

  test('3 check-ins on 2 nights count as 2', () {
    final p = yearlyGoalProgress(
      [
        _ci(DateTime(2026, 3, 1, 23)),
        _ci(DateTime(2026, 3, 2, 2)),
        _ci(DateTime(2026, 3, 8, 22)),
      ],
      30,
      now,
    );
    expect(p.nightsSoFar, 2);
  });

  test('01:00 on 1 Jan 2026 counts for 2025', () {
    final list = [_ci(DateTime(2026, 1, 1, 1))];
    expect(yearlyGoalProgress(list, 30, now).nightsSoFar, 0);
    expect(yearlyGoalProgress(list, 30, DateTime(2025, 12, 31)).nightsSoFar, 1);
  });

  test('pace lines on day 183', () {
    expect(yearlyGoalProgress([], 30, now).expectedByNow, 15);
    expect(
      goalPaceLine(yearlyGoalProgress(_nights(17), 30, now)),
      '2 ahead of pace',
    );
    expect(
      goalPaceLine(yearlyGoalProgress(_nights(14), 30, now)),
      '1 behind pace',
    );
    expect(
      goalPaceLine(yearlyGoalProgress(_nights(15), 30, now)),
      'Right on pace',
    );
  });

  test('goal reached', () {
    expect(
      goalPaceLine(yearlyGoalProgress(_nights(30), 30, now)),
      'Goal reached!',
    );
  });

  test('headline pluralises', () {
    expect(
      goalHeadline(yearlyGoalProgress(_nights(1), 1, now)),
      '1 of 1 night in 2026',
    );
  });

  Future<void> pump(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    Get.reset();
    final c = ClubController(
      clubService: _NoClubs(),
      checkInService: _NoCheckIns(),
    );
    Get.put<ClubController>(c);
    c.myCheckIns.assignAll(_nights(17));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: YearlyGoalCard(now: now)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('setting a goal validates and saves', (tester) async {
    await pump(tester, {});
    expect(find.text('Set a goal for 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('setYearlyGoal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('yearlyGoalField')), '0');
    await tester.tap(find.byKey(const Key('saveYearlyGoal')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 1 to 365'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('yearlyGoalField')), '30');
    await tester.tap(find.byKey(const Key('saveYearlyGoal')));
    await tester.pumpAndSettle();
    expect(find.textContaining('of 30 nights in 2026'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('yearly_goal_2026'), 30);
  });

  testWidgets('stored goal shows the pace line', (tester) async {
    await pump(tester, {'yearly_goal_2026': 30});
    expect(find.text('2 ahead of pace'), findsOneWidget);
    expect(find.text('17 of 30 nights in 2026'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
