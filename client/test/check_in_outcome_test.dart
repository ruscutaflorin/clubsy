import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_outcome.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/widgets/check_in_success_sheet.dart';

ClubModel _club(String id, String city) => ClubModel.fromMap({
  'id': id,
  'name': 'Club $id',
  'address': '1 Main St',
  'city': city,
  'latitude': 46,
  'longitude': 23.5,
  'imageUrl': 'http://img',
});

CheckInModel _visit(String id, String clubId, {String city = 'Cluj'}) =>
    CheckInModel(
      id: id,
      clubId: clubId,
      checkedInAt: DateTime.utc(2026, 1, 1),
      verificationMethod: 'QR_GPS',
      distanceMeters: 10,
      club: _club(clubId, city),
    );

void main() {
  group('checkInOutcome', () {
    test('no history is a first visit with total 1', () {
      final o = checkInOutcome('a', [], city: 'Cluj');
      expect(o.isFirstVisit, isTrue);
      expect(o.visitNumber, 1);
      expect(o.totalClubsVisited, 1);
      expect(o.isNewCity, isTrue);
    });

    test('two earlier visits make visit #3', () {
      final o = checkInOutcome('a', [_visit('1', 'a'), _visit('2', 'a')]);
      expect(o.isFirstVisit, isFalse);
      expect(o.visitNumber, 3);
      expect(o.totalClubsVisited, 1);
    });

    test('visits to other clubs only change the total', () {
      final o = checkInOutcome('a', [
        _visit('1', 'b'),
        _visit('2', 'c'),
      ], city: 'Cluj');
      expect(o.isFirstVisit, isTrue);
      expect(o.visitNumber, 1);
      expect(o.totalClubsVisited, 3);
      expect(o.isNewCity, isFalse);
    });

    test('a first club in a new city is flagged', () {
      final o = checkInOutcome('z', [_visit('1', 'b')], city: 'Brasov');
      expect(o.isNewCity, isTrue);
      expect(o.city, 'Brasov');
    });
  });

  group('CheckInSuccessSheet', () {
    Future<void> pump(WidgetTester tester, CheckInOutcome o) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CheckInSuccessSheet(outcome: o, club: _club('x', 'Cluj')),
            ),
          ),
        );

    testWidgets('first visit text', (tester) async {
      await pump(
        tester,
        checkInOutcome('x', [_visit('1', 'a'), _visit('2', 'b')], city: 'Cluj'),
      );
      await tester.pumpAndSettle();
      expect(find.text('New place on your map!'), findsOneWidget);
      expect(find.text("That's 3 clubs."), findsOneWidget);
      expect(find.text('View on map'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('new city text', (tester) async {
      await pump(tester, checkInOutcome('x', [], city: 'Cluj'));
      await tester.pumpAndSettle();
      expect(
        find.text("That's 1 club and your first in Cluj!"),
        findsOneWidget,
      );
    });

    testWidgets('repeat visit text', (tester) async {
      await pump(
        tester,
        checkInOutcome('x', [_visit('1', 'x'), _visit('2', 'x')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Visit #3 at Club x'), findsOneWidget);
    });
  });
}
