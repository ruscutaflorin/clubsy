import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/check_in_history_page.dart';
import 'package:clubsy/views/pages/club_details_page.dart';
import 'package:clubsy/views/pages/profile_page.dart';

ClubModel fixtureClub(String id, String name) => ClubModel(
  id: id,
  name: name,
  address: '1 Main St',
  city: 'Cluj',
  latitude: 46,
  longitude: 23.5,
  imageUrl: 'http://localhost/img.png',
  isApproved: true,
);

CheckInModel fixtureCheckIn(String id, ClubModel club) => CheckInModel(
  id: id,
  clubId: club.id,
  checkedInAt: DateTime.utc(2026, 1, 1),
  verificationMethod: 'QR_GPS',
  distanceMeters: 10,
  club: club,
);

void main() {
  late ClubController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put(ClubController());
  });

  tearDown(Get.reset);

  group('ClubDetailsPage', () {
    final club = fixtureClub('a', 'Club Alpha');

    testWidgets('shows club info and no visit history by default', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException(); // Image.network fails under the test HTTP stub.

      expect(find.text('Club Alpha'), findsWidgets);
      expect(find.text('1 Main St, Cluj'), findsOneWidget);
      expect(find.text('Check in'), findsOneWidget);
      expect(find.text('Checked in before'), findsNothing);
      expect(find.text('Not on your map yet'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.byKey(const Key('nightsHereTile')), findsNothing);
    });

    testWidgets('shows visited chip and a 1-visit summary with one check-in', (
      tester,
    ) async {
      controller.myCheckIns.add(fixtureCheckIn('1', club));
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException();

      expect(find.text('Checked in before'), findsOneWidget);
      expect(find.textContaining('1 visit ·'), findsOneWidget);
      expect(find.text('Not on your map yet'), findsNothing);
    });

    testWidgets('shows a plural visit count with multiple check-ins', (
      tester,
    ) async {
      controller.myCheckIns.addAll([
        fixtureCheckIn('1', club),
        fixtureCheckIn('2', club),
      ]);
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException();

      expect(find.textContaining('2 visits · last on'), findsOneWidget);
    });

    testWidgets('lists the nights spent here in an expandable tile', (
      tester,
    ) async {
      for (final day in [3, 10, 14]) {
        controller.myCheckIns.add(
          CheckInModel(
            id: '$day',
            clubId: club.id,
            checkedInAt: DateTime(2026, 3, day, 22),
            verificationMethod: 'QR_GPS',
            distanceMeters: 10,
            club: club,
          ),
        );
      }
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException();

      expect(find.text('Your nights here (3)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nightsHereTile')));
      await tester.pumpAndSettle();
      expect(find.text('Sat 14 Mar 2026'), findsOneWidget);
    });
  });

  group('ClubDetailsPage my vibe', () {
    final club = fixtureClub('a', 'Club Alpha');

    testWidgets('shows my own rating when I rated a night here', (
      tester,
    ) async {
      controller.myCheckIns.add(fixtureCheckIn('1', club).withDiary(vibe: 4));
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException();

      final line = tester.widget<Text>(find.byKey(const Key('myVibeText')));
      expect(line.data, contains('You rated it'));
    });

    testWidgets('hides the line when I never rated this club', (tester) async {
      controller.myCheckIns.add(fixtureCheckIn('1', club));
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: club)));
      tester.takeException();

      expect(find.byKey(const Key('myVibeText')), findsNothing);
    });
  });

  group('ClubDetailsPage pairings', () {
    final a = fixtureClub('a', 'Club Alpha');
    final b = fixtureClub('b', 'Club Beta');

    CheckInModel at(String id, ClubModel c, DateTime when) => CheckInModel(
      id: id,
      clubId: c.id,
      checkedInAt: when,
      verificationMethod: 'QR_GPS',
      distanceMeters: 10,
      club: c,
    );

    testWidgets('shows often paired with partners', (tester) async {
      controller.myCheckIns.addAll([
        at('1', a, DateTime(2026, 3, 6, 22)),
        at('2', b, DateTime(2026, 3, 6, 23)),
        at('3', a, DateTime(2026, 3, 13, 22)),
        at('4', b, DateTime(2026, 3, 13, 23)),
      ]);
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: a)));
      tester.takeException();

      expect(find.byKey(const Key('pairedClubs')), findsOneWidget);
      expect(find.text('Often paired with'), findsOneWidget);
      expect(find.text('2 nights together'), findsOneWidget);
    });

    testWidgets('hides the section without shared nights', (tester) async {
      controller.myCheckIns.add(at('1', a, DateTime(2026, 3, 6, 22)));
      await tester.pumpWidget(MaterialApp(home: ClubDetailsPage(club: a)));
      tester.takeException();

      expect(find.byKey(const Key('pairedClubs')), findsNothing);
    });
  });

  group('CheckInHistoryPage', () {
    testWidgets('shows empty state without check-ins', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CheckInHistoryPage()));

      expect(
        find.text("No check-ins yet — scan a club's QR to add your first pin"),
        findsOneWidget,
      );
    });

    testWidgets('lists a tile per check-in', (tester) async {
      controller.myCheckIns.addAll([
        fixtureCheckIn('1', fixtureClub('a', 'Club Alpha')),
        fixtureCheckIn('2', fixtureClub('b', 'Club Beta')),
      ]);
      await tester.pumpWidget(const MaterialApp(home: CheckInHistoryPage()));

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Club Alpha'), findsOneWidget);
      expect(find.text('Club Beta'), findsOneWidget);
      expect(
        find.text("No check-ins yet — scan a club's QR to add your first pin"),
        findsNothing,
      );
    });
  });

  group('CheckInHistoryPage search', () {
    testWidgets('filters by query and shows counts', (tester) async {
      controller.myCheckIns.addAll([
        fixtureCheckIn('1', fixtureClub('a', 'Club Alpha')),
        fixtureCheckIn('2', fixtureClub('b', 'Club Beta')),
      ]);
      await tester.pumpWidget(const MaterialApp(home: CheckInHistoryPage()));

      await tester.enterText(find.byKey(const Key('history_search')), 'beta');
      await tester.pump();
      expect(find.text('Club Beta'), findsOneWidget);
      expect(find.text('Club Alpha'), findsNothing);
      expect(find.text('1 night matches'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('history_search')), 'zzz');
      await tester.pump();
      expect(find.textContaining('No nights match'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('ProfileStatsCard', () {
    testWidgets('shows the personal-map summary from fixture stats', (
      tester,
    ) async {
      final stats = CheckInStatsModel.fromMap({
        'totalCheckIns': 5,
        'uniqueClubs': 3,
        'uniqueCities': 2,
        'mostVisitedClub': {'id': 'a', 'name': 'Club Alpha', 'visits': 3},
        'firstCheckInAt': '2026-01-01T20:00:00Z',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfileStatsCard(stats: stats)),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Most visited: Club Alpha (3 visits)'), findsOneWidget);
    });

    testWidgets('omits the most-visited line with no history', (tester) async {
      final stats = CheckInStatsModel.fromMap({
        'totalCheckIns': 0,
        'uniqueClubs': 0,
        'uniqueCities': 0,
        'mostVisitedClub': null,
        'firstCheckInAt': null,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfileStatsCard(stats: stats)),
        ),
      );

      expect(find.byKey(const Key('profileStatsCard')), findsOneWidget);
      expect(find.textContaining('Most visited'), findsNothing);
    });
  });
}
