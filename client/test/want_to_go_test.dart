import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/want_to_go_page.dart';

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

class _FakeClubService implements ClubService {
  @override
  Future<void> setFavorite(String id, bool favorite) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ClubController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put(ClubController(clubService: _FakeClubService()));
  });

  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WantToGoPage()));
  }

  testWidgets('shows been-yet status for unvisited and visited favourites', (
    tester,
  ) async {
    final seen = fixtureClub('a', 'Alpha');
    controller.clubs.addAll([seen, fixtureClub('b', 'Beta')]);
    controller.favoriteIds.addAll(['a', 'b']);
    for (var i = 0; i < 2; i++) {
      controller.myCheckIns.add(
        CheckInModel(
          id: 'a-$i',
          clubId: 'a',
          checkedInAt: DateTime(2026, 1, 1 + i, 22),
          verificationMethod: 'QR',
          distanceMeters: 10,
          club: seen,
        ),
      );
    }

    await pump(tester);

    expect(find.text('Not been yet'), findsOneWidget);
    expect(find.text('Been · 2 nights'), findsOneWidget);
  });

  testWidgets('no favourites shows the empty state', (tester) async {
    controller.clubs.add(fixtureClub('a', 'Alpha'));
    await pump(tester);
    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('tapping the heart removes the row', (tester) async {
    controller.clubs.add(fixtureClub('a', 'Alpha'));
    controller.favoriteIds.add('a');
    await pump(tester);

    await tester.tap(find.byKey(const Key('unfavorite_a')));
    await tester.pump();

    expect(find.text('Alpha'), findsNothing);
    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
  });
}
