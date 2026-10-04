import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/club_search_controller.dart';
import 'package:clubsy/views/pages/club_search_page.dart';

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
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('renders fixture results and marks the visited one', (
    tester,
  ) async {
    final clubController = Get.put(ClubController());
    clubController.myCheckIns.add(
      CheckInModel(
        id: 'k1',
        clubId: 'a',
        checkedInAt: DateTime.utc(2026, 1, 1),
        verificationMethod: 'QR',
        distanceMeters: 10,
        club: fixtureClub('a', 'Club Alpha'),
      ),
    );

    final searchController = Get.put(
      ClubSearchController(
        fetch: ({search, city}) async => [
          fixtureClub('a', 'Club Alpha'),
          fixtureClub('b', 'Club Beta'),
        ],
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ClubSearchPage()));
    searchController.search('club');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Club Alpha'), findsOneWidget);
    expect(find.text('Club Beta'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });

  testWidgets(
    'shows a prompt before typing and "No clubs found" for an empty result',
    (tester) async {
      Get.put(ClubController());
      final searchController = Get.put(
        ClubSearchController(fetch: ({search, city}) async => []),
      );

      await tester.pumpWidget(const MaterialApp(home: ClubSearchPage()));
      expect(find.text('Start typing to search clubs'), findsOneWidget);

      searchController.search('nothing');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No clubs found'), findsOneWidget);
    },
  );

  testWidgets('Open now chip shows "No clubs open right now" when none open', (
    tester,
  ) async {
    Get.put(ClubController());
    final searchController = Get.put(
      ClubSearchController(
        fetch: ({search, city}) async => [fixtureClub('a', 'Club Alpha')],
        clock: () => DateTime(2026, 10, 3, 2),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ClubSearchPage()));
    searchController.search('club');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Club Alpha'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openNowFilter')));
    await tester.pump();

    expect(find.text('No clubs open right now'), findsOneWidget);
    expect(find.text('Club Alpha'), findsNothing);
  });
}
