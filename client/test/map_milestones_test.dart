import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/map_milestones.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/map_milestones_card.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckInModel _ci(String clubId, DateTime at, {String city = 'Cluj'}) =>
    CheckInModel(
      id: '$clubId-${at.toIso8601String()}',
      clubId: clubId,
      checkedInAt: at,
      verificationMethod: 'QR_GPS',
      distanceMeters: 10,
      club: ClubModel.fromMap({
        'id': clubId,
        'name': 'Club $clubId',
        'address': '1 Main St',
        'city': city,
        'latitude': 46,
        'longitude': 23.5,
        'imageUrl': 'http://img',
      }),
    );

List<CheckInModel> _tenClubs() => [
  for (var i = 1; i <= 10; i++) _ci('c$i', DateTime(2026, 1, i, 22)),
  _ci('c1', DateTime(2026, 2, 1, 22)),
];

void main() {
  test('empty input gives an empty list', () {
    expect(mapMilestones([]), isEmpty);
  });

  test('club milestones at 1, 5 and 10; repeats ignored', () {
    final list = [_ci('c1', DateTime(2025, 12, 1, 22)), ..._tenClubs()];
    final m = mapMilestones(list);
    expect(m.map((e) => e.ordinal), [10, 5, 1]);
    expect(m.first.club.id, 'c10');
    expect(m.first.night, DateTime(2026, 1, 10));
  });

  test('second city gives one city milestone; case/space-insensitive', () {
    final m = mapMilestones([
      _ci('a', DateTime(2026, 3, 1, 22), city: 'cluj '),
      _ci('b', DateTime(2026, 3, 2, 22), city: 'Cluj'),
      _ci('c', DateTime(2026, 3, 3, 22), city: 'Brașov'),
      _ci('d', DateTime(2026, 3, 4, 22), city: 'Brașov'),
    ]);
    final cities = m.where((e) => e.kind == MapMilestoneKind.city).toList();
    expect(cities, hasLength(1));
    expect(cities.single.city, 'Brașov');
    expect(cities.single.night, DateTime(2026, 3, 3));
  });

  test('02:00 check-in gets the previous evening', () {
    final m = mapMilestones([_ci('a', DateTime(2026, 3, 15, 2))]);
    expect(m.single.night, DateTime(2026, 3, 14));
  });

  test('labels', () {
    final m = mapMilestones([
      for (var i = 1; i <= 25; i++)
        _ci('c$i', DateTime(2026, 1, 1, 22).add(Duration(days: i))),
      _ci('z', DateTime(2026, 6, 1, 22), city: 'Brașov'),
    ]);
    final labels = m.map(milestoneLabel).toList();
    expect(labels, contains('1st club: Club c1'));
    expect(labels, contains('25th club: Club c25'));
    expect(labels, contains('First night in Brașov'));
  });

  Future<void> pump(WidgetTester tester, List<CheckInModel> list) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final c = ClubController(
      clubService: _NoClubs(),
      checkInService: _NoCheckIns(),
    );
    Get.put<ClubController>(c);
    c.myCheckIns.assignAll(list);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: MapMilestonesCard())),
      ),
    );
  }

  testWidgets('card shows milestones', (tester) async {
    await pump(tester, [_ci('a', DateTime(2026, 3, 1, 22))]);
    expect(find.text('Map milestones'), findsOneWidget);
    expect(find.textContaining('1st club'), findsOneWidget);
  });

  testWidgets('show all expands to the oldest milestone', (tester) async {
    // 1st, 5th, 10th clubs + 3 more cities = 6 milestones.
    await pump(tester, [
      ..._tenClubs(),
      _ci('x1', DateTime(2026, 4, 1, 22), city: 'A'),
      _ci('x2', DateTime(2026, 4, 2, 22), city: 'B'),
      _ci('x3', DateTime(2026, 4, 3, 22), city: 'C'),
    ]);
    expect(find.textContaining('1st club'), findsNothing);
    await tester.tap(find.byKey(const Key('milestonesShowAll')));
    await tester.pump();
    expect(find.textContaining('1st club'), findsOneWidget);
  });

  testWidgets('card is empty with no check-ins', (tester) async {
    await pump(tester, []);
    expect(find.text('Map milestones'), findsNothing);
  });
}
