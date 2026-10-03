import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_map_page.dart';

ClubModel fixtureClub(String id, String name) => ClubModel(
  id: id,
  name: name,
  address: '1 Main St',
  city: 'Cluj',
  latitude: 46,
  longitude: 23.5,
  imageUrl: 'http://img',
  isApproved: true,
);

void main() {
  late ClubController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put(ClubController());
  });

  tearDown(Get.reset);

  void addNights(ClubModel club, int count) {
    for (var i = 0; i < count; i++) {
      controller.myCheckIns.add(
        CheckInModel(
          id: '${club.id}-$i',
          clubId: club.id,
          checkedInAt: DateTime(2026, 1, 1 + i, 22),
          verificationMethod: 'QR',
          distanceMeters: 10,
          club: club,
        ),
      );
    }
  }

  testWidgets('a club with 3 nights shows a count of 3', (tester) async {
    final club = fixtureClub('a', 'Club Alpha');
    controller.clubs.add(club);
    addNights(club, 3);

    await tester.pumpWidget(const MaterialApp(home: ClubMapPage()));
    await tester.pump();
    tester.takeException();

    expect(
      find.descendant(
        of: find.byKey(const Key('pinCount_a')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('single-night and unvisited clubs show no badge', (tester) async {
    final a = fixtureClub('a', 'Club Alpha');
    controller.clubs.addAll([a, fixtureClub('b', 'Club Beta')]);
    addNights(a, 1);

    await tester.pumpWidget(const MaterialApp(home: ClubMapPage()));
    tester.takeException();

    expect(find.byKey(const Key('pinCount_a')), findsNothing);
    expect(find.byKey(const Key('pinCount_b')), findsNothing);
  });

  testWidgets('more than 99 nights shows 99+', (tester) async {
    final club = fixtureClub('a', 'Club Alpha');
    controller.clubs.add(club);
    addNights(club, 120);

    await tester.pumpWidget(const MaterialApp(home: ClubMapPage()));
    await tester.pump();
    tester.takeException();

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('toggling to Visited with no check-ins shows the empty state', (
    tester,
  ) async {
    controller.clubs.addAll([
      fixtureClub('a', 'Club Alpha'),
      fixtureClub('b', 'Club Beta'),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ClubMapPage()));
    tester.takeException(); // tile layer has no network in tests

    expect(
      find.text("No check-ins yet — scan a club's QR to add your first pin"),
      findsNothing,
    );

    await tester.tap(find.text('Visited'));
    await tester.pump();
    tester.takeException();

    expect(controller.visitedOnly.value, isTrue);
    expect(
      find.text("No check-ins yet — scan a club's QR to add your first pin"),
      findsOneWidget,
    );
  });

  testWidgets('toggling to Visited with a check-in hides the empty state', (
    tester,
  ) async {
    final club = fixtureClub('a', 'Club Alpha');
    controller.clubs.add(club);
    controller.myCheckIns.add(
      CheckInModel(
        id: 'k1',
        clubId: 'a',
        checkedInAt: DateTime.utc(2026, 1, 1),
        verificationMethod: 'QR',
        distanceMeters: 10,
        club: club,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ClubMapPage()));
    tester.takeException();

    await tester.tap(find.text('Visited'));
    await tester.pump();
    tester.takeException();

    expect(
      find.text("No check-ins yet — scan a club's QR to add your first pin"),
      findsNothing,
    );
  });
}
