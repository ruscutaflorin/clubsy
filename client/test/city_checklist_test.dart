import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/city_checklist.dart';
import 'package:clubsy/data/classes/city_progress_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/city_checklist_page.dart';
import 'package:clubsy/views/pages/my_cities_page.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClubModel _club(
  String id,
  String name, {
  String city = 'Cluj-Napoca',
  bool approved = true,
}) => ClubModel.fromMap({
  'id': id,
  'name': name,
  'address': '1 Main St',
  'city': city,
  'latitude': 46,
  'longitude': 23.5,
  'imageUrl': 'http://img',
  'isApproved': approved,
});

CheckInModel _ci(ClubModel club, DateTime at) => CheckInModel(
  id: '${club.id}-${at.toIso8601String()}',
  clubId: club.id,
  checkedInAt: at,
  verificationMethod: 'QR_GPS',
  distanceMeters: 10,
  club: club,
);

void main() {
  test('other cities and unapproved clubs are excluded', () {
    final r = cityChecklist('Cluj-Napoca', [
      _club('a', 'A'),
      _club('b', 'B', city: 'Bucharest'),
      _club('c', 'C', approved: false),
    ], []);
    expect(r.map((e) => e.club.id), ['a']);
  });

  test('city matching ignores case and surrounding spaces', () {
    final r = cityChecklist('  cluj-napoca ', [
      _club('a', 'A', city: 'CLUJ-NAPOCA'),
      _club('b', 'B', city: ' Cluj-Napoca '),
    ], []);
    expect(r, hasLength(2));
  });

  test('23:00 and 02:00 next morning count as one night', () {
    final a = _club('a', 'A');
    final r = cityChecklist(
      'Cluj-Napoca',
      [a],
      [_ci(a, DateTime(2026, 8, 1, 23)), _ci(a, DateTime(2026, 8, 2, 2))],
    );
    expect(r.single.nights, 1);
    expect(r.single.lastNight, DateTime(2026, 8, 1));
  });

  test('visited first, unvisited alphabetical', () {
    final a = _club('a', 'Zed');
    final b = _club('b', 'Beta');
    final c = _club('c', 'Alpha');
    final d = _club('d', 'Visited');
    final r = cityChecklist(
      'Cluj-Napoca',
      [a, b, c, d],
      [_ci(d, DateTime(2026, 8, 1, 23))],
    );
    expect(r.map((e) => e.club.name), ['Visited', 'Alpha', 'Beta', 'Zed']);
    expect(r.last.lastNight, isNull);
  });

  Future<ClubController> setUpController(
    List<ClubModel> clubs,
    List<CheckInModel> checkIns,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final c = ClubController(
      clubService: _NoClubs(),
      checkInService: _NoCheckIns(),
    );
    Get.put<ClubController>(c);
    c.clubs.assignAll(clubs);
    c.myCheckIns.assignAll(checkIns);
    return c;
  }

  testWidgets('tapping a city shows its not-yet clubs', (tester) async {
    final a = _club('a', 'Visited Club');
    final b = _club('b', 'Missing Club');
    final c = await setUpController([a, b], [_ci(a, DateTime(2026, 8, 1, 23))]);
    c.cityProgress.assignAll([
      CityProgressModel(city: 'Cluj-Napoca', visitedClubs: 1, totalClubs: 2),
    ]);
    await tester.pumpWidget(const GetMaterialApp(home: MyCitiesPage()));
    await tester.tap(find.byKey(const Key('city_Cluj-Napoca')));
    await tester.pumpAndSettle();
    expect(find.text('Not been yet'), findsOneWidget);
    expect(find.text('Missing Club'), findsOneWidget);
    expect(find.text('1 of 2 clubs'), findsOneWidget);
  });

  testWidgets('all visited shows the celebration line', (tester) async {
    final a = _club('a', 'Visited Club');
    await setUpController([a], [_ci(a, DateTime(2026, 8, 1, 23))]);
    await tester.pumpWidget(
      const GetMaterialApp(home: CityChecklistPage(city: 'Cluj-Napoca')),
    );
    expect(find.textContaining("You've been to every club in"), findsOneWidget);
    expect(find.text('Not been yet'), findsNothing);
  });
}
