import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/data/classes/next_goals.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/next_goals_card.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _badge(
  String id,
  String title,
  int current,
  int target, {
  bool earned = false,
}) => {
  'id': id,
  'title': title,
  'progress': {'current': current, 'target': target},
  if (earned) 'earnedAt': '2026-01-01T00:00:00Z',
};

AchievementsModel _model(List<Map<String, dynamic>> badges) =>
    AchievementsModel.fromMap({'badges': badges});

void main() {
  test('closest badge first with a plural hint', () {
    final goals = nextGoals(
      _model([
        _badge('first_pin', 'First pin', 1, 1, earned: true),
        _badge('explorer_5', 'Explorer', 3, 5),
        _badge('explorer_15', 'Pathfinder', 3, 15),
      ]),
    );
    expect(goals.first.badgeId, 'explorer_5');
    expect(goals.first.hint, '2 more clubs to unlock Explorer');
    expect(goals.length, 2);
  });

  test('earned badges are never returned', () {
    final goals = nextGoals(
      _model([
        _badge('explorer_5', 'Explorer', 5, 5, earned: true),
        _badge('globetrotter_3', 'Globetrotter', 2, 3),
      ]),
    );
    expect(goals.map((g) => g.badgeId), ['globetrotter_3']);
    expect(goals.single.hint, '1 more city to unlock Globetrotter');
  });

  test('singular for a remaining count of 1', () {
    final goals = nextGoals(_model([_badge('explorer_5', 'Explorer', 4, 5)]));
    expect(goals.single.hint, '1 more club to unlock Explorer');
  });

  test('no check-ins returns only the first pin hint', () {
    final goals = nextGoals(
      _model([
        _badge('first_pin', 'First pin', 0, 1),
        _badge('explorer_5', 'Explorer', 0, 5),
      ]),
    );
    expect(goals.length, 1);
    expect(goals.single.hint, 'Check in anywhere to unlock First pin');
  });

  test('limit is respected', () {
    final m = _model([
      _badge('explorer_5', 'Explorer', 3, 5),
      _badge('globetrotter_3', 'Globetrotter', 1, 3),
      _badge('streak_4', 'Streaker', 1, 4),
    ]);
    expect(nextGoals(m, limit: 1).length, 1);
    expect(nextGoals(m, limit: 3).length, 3);
  });

  Future<void> pump(WidgetTester tester, AchievementsModel a) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final c = ClubController(
      clubService: _NoClubs(),
      checkInService: _NoCheckIns(),
    );
    Get.put<ClubController>(c);
    c.achievements.value = a;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NextGoalsCard())),
    );
  }

  testWidgets('card shows title and hint', (tester) async {
    await pump(tester, _model([_badge('explorer_5', 'Explorer', 3, 5)]));
    expect(find.text('Next up'), findsOneWidget);
    expect(find.text('2 more clubs to unlock Explorer'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('card is empty when every badge is earned', (tester) async {
    await pump(
      tester,
      _model([_badge('explorer_5', 'Explorer', 5, 5, earned: true)]),
    );
    expect(find.text('Next up'), findsNothing);
  });
}
