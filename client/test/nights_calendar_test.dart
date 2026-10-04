import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/nights_calendar.dart';
import 'package:clubsy/widgets/nights_calendar.dart';

CheckInModel _ci(String clubId, DateTime at) => CheckInModel(
  id: '$clubId-$at',
  clubId: clubId,
  checkedInAt: at,
  verificationMethod: 'QR_GPS',
  distanceMeters: 10,
  club: ClubModel.fromMap({
    'id': clubId,
    'name': 'Club $clubId',
    'address': '1 Main St',
    'city': 'Cluj',
    'latitude': 46,
    'longitude': 23.5,
    'imageUrl': 'http://img',
  }),
);

void main() {
  test('two clubs on one evening is one night', () {
    final r = nightsCalendar([
      _ci('a', DateTime(2026, 3, 14, 23)),
      _ci('b', DateTime(2026, 3, 15, 1)),
    ], 2026);
    expect(r.nightsOut, 1);
    expect(r.nights[DateTime(2026, 3, 14)], ['Club a', 'Club b']);
  });

  test('02:00 check-in belongs to the previous date', () {
    final r = nightsCalendar([_ci('a', DateTime(2026, 5, 10, 2))], 2026);
    expect(r.nights.keys, [DateTime(2026, 5, 9)]);
  });

  test('01:00 on 1 January belongs to the previous year', () {
    final c = [_ci('a', DateTime(2026, 1, 1, 1))];
    expect(nightsCalendar(c, 2026).nightsOut, 0);
    expect(nightsCalendar(c, 2025).nights.keys, [DateTime(2025, 12, 31)]);
  });

  test('longestGapDays between nights', () {
    final r = nightsCalendar([
      _ci('a', DateTime(2026, 3, 1, 22)),
      _ci('a', DateTime(2026, 3, 11, 22)),
    ], 2026);
    expect(r.longestGapDays, 10);
  });

  test('empty list', () {
    final r = nightsCalendar([], 2026);
    expect(r.nightsOut, 0);
    expect(r.longestGapDays, 0);
  });

  test('the same club twice in one night is listed once', () {
    final r = nightsCalendar([
      _ci('a', DateTime(2026, 6, 6, 22)),
      _ci('a', DateTime(2026, 6, 7, 3)),
    ], 2026);
    expect(r.nightsOut, 1);
    expect(r.nights[DateTime(2026, 6, 6)], ['Club a']);
  });

  testWidgets('cells cover the year and shade by club count', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: NightsCalendar(
            checkIns: [
              _ci('a', DateTime(2026, 1, 3, 23)),
              _ci('a', DateTime(2026, 1, 10, 23)),
              _ci('b', DateTime(2026, 1, 11, 1)),
            ],
            year: 2026,
          ),
        ),
      ),
    );
    Color colorOf(String key) {
      final box = tester.widget<Container>(find.byKey(Key(key)));
      return (box.decoration! as BoxDecoration).color!;
    }

    expect(find.byKey(const Key('night_2026-01-01')), findsOneWidget);
    expect(find.byKey(const Key('night_2026-01-02')), findsOneWidget);
    final empty = colorOf('night_2026-01-02');
    final one = colorOf('night_2026-01-03');
    final many = colorOf('night_2026-01-10');
    expect(one, isNot(empty));
    expect(many, isNot(one));
    expect(many, isNot(empty));
  });

  testWidgets('tapping a night lists its clubs', (tester) async {
    final checkIns = [
      _ci('a', DateTime(2026, 3, 14, 23)),
      _ci('b', DateTime(2026, 3, 20, 23)),
      _ci('c', DateTime(2026, 4, 2, 23)),
    ];
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: NightsCalendar(checkIns: checkIns, year: 2026)),
      ),
    );
    await tester.tap(find.byKey(const Key('night_2026-03-14')));
    await tester.pumpAndSettle();
    expect(find.text('Club a'), findsOneWidget);
  });
}
