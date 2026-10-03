import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/streak_nudge_banner.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, bool atRisk) async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final c = ClubController(
    clubService: _NoClubs(),
    checkInService: _NoCheckIns(),
  );
  Get.put<ClubController>(c);
  c.achievements.value = AchievementsModel.fromMap({
    'streak': {'current': 3, 'longest': 3, 'atRisk': atRisk},
  });
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: StreakNudgeBanner())),
  );
}

void main() {
  test('streak.atRisk parses and defaults to false', () {
    final a = AchievementsModel.fromMap({
      'streak': {'current': 3, 'longest': 3, 'atRisk': true},
    });
    expect(a.streakAtRisk, isTrue);
    final b = AchievementsModel.fromMap({
      'streak': {'current': 3, 'longest': 3},
    });
    expect(b.streakAtRisk, isFalse);
  });

  testWidgets('shows the nudge when at risk and hides it on dismiss', (
    tester,
  ) async {
    await _pump(tester, true);
    expect(find.textContaining('keeps your 3-week streak'), findsOneWidget);
    await tester.tap(find.byKey(const Key('streakNudgeDismiss')));
    await tester.pump();
    expect(find.textContaining('keeps your 3-week streak'), findsNothing);
  });

  testWidgets('renders nothing when not at risk', (tester) async {
    await _pump(tester, false);
    expect(find.textContaining('keeps your'), findsNothing);
  });
}
