import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/views/pages/achievements_page.dart';

Map<String, dynamic> badge(String id, {String? earnedAt, int current = 0}) => {
  'id': id,
  'title': id == 'explorer_5' ? 'Explorer' : 'Badge $id',
  'description': 'Desc $id',
  'earnedAt': earnedAt,
  'progress': {'current': current, 'target': 5},
};

AchievementsModel make(List<Map<String, dynamic>> badges, {int streak = 3}) =>
    AchievementsModel.fromMap({
      'streak': {'current': streak, 'longest': 5},
      'badges': badges,
      'challenges': [
        {
          'id': 'two_clubs',
          'title': 'Check in at 2 different clubs',
          'progress': {'current': 1, 'target': 2},
          'completed': false,
          'endsAt': '2026-10-05T00:00:00.000Z',
        },
      ],
      'points': 120,
    });

void main() {
  group('AchievementsModel.fromMap', () {
    test('parses streak, points, badges and challenges', () {
      final a = make([
        badge('first_pin', earnedAt: '2026-09-01T22:00:00.000Z', current: 5),
        badge('explorer_5', current: 3),
      ]);
      expect(a.currentStreak, 3);
      expect(a.longestStreak, 5);
      expect(a.points, 120);
      expect(a.earnedCount, 1);
      expect(a.badges[1].earned, isFalse);
      expect(a.badges[1].current, 3);
      expect(a.challenges.single.target, 2);
      expect(a.challenges.single.endsAt, isNotNull);
    });
  });

  group('newlyEarned', () {
    final none = make([badge('first_pin'), badge('explorer_5')]);
    final one = make([
      badge('first_pin', earnedAt: '2026-09-01T22:00:00.000Z'),
      badge('explorer_5'),
    ]);
    final two = make([
      badge('first_pin', earnedAt: '2026-09-01T22:00:00.000Z'),
      badge('explorer_5', earnedAt: '2026-09-02T22:00:00.000Z'),
    ]);

    test('none', () => expect(newlyEarned(none, none), isEmpty));
    test('one', () {
      expect(newlyEarned(none, one).map((b) => b.id), ['first_pin']);
    });
    test('several', () {
      expect(newlyEarned(none, two).map((b) => b.id), [
        'first_pin',
        'explorer_5',
      ]);
    });
    test('a streak increase is not a badge', () {
      final more = make([badge('first_pin'), badge('explorer_5')], streak: 4);
      expect(newlyEarned(none, more), isEmpty);
    });
    test('no earlier snapshot announces nothing', () {
      expect(newlyEarned(null, two), isEmpty);
    });
    test('unlock text', () {
      expect(badgeUnlockedText(two.badges[1]), 'Badge unlocked: Explorer');
    });
  });

  testWidgets(
    'AchievementsView renders earned/unearned badges and challenges',
    (tester) async {
      final a = make([
        badge('first_pin', earnedAt: '2026-09-01T22:00:00.000Z', current: 5),
        badge('explorer_5', current: 3),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AchievementsView(achievements: a)),
        ),
      );
      expect(find.text('🔥 3-week streak'), findsOneWidget);
      expect(find.text('Check in at 2 different clubs'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('Badges (1/2)'), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const Key('badge_explorer_5')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, lessThan(1));

      await tester.tap(find.byKey(const Key('badge_first_pin')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Desc first_pin'), findsOneWidget);
      expect(find.textContaining('Earned'), findsOneWidget);
    },
  );
}
