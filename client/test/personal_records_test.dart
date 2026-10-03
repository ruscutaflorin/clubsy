import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/personal_records.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/personal_records_card.dart';

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

void main() {
  test('empty input gives null', () {
    expect(personalRecords([]), isNull);
  });

  test('02:00 check-in counts towards the previous evening', () {
    final r = personalRecords([
      _ci('a', DateTime(2026, 3, 14, 22)),
      _ci('b', DateTime(2026, 3, 14, 23, 30)),
      _ci('c', DateTime(2026, 3, 15, 2)),
      _ci('a', DateTime(2026, 4, 1, 22)),
    ])!;
    expect(r.biggestNight.clubs, 3);
    expect(r.biggestNight.night, DateTime(2026, 3, 14));
    expect(r.firstNight, DateTime(2026, 3, 14));
  });

  test('equal months choose the more recent one', () {
    final r = personalRecords([
      _ci('a', DateTime(2026, 5, 1, 22)),
      _ci('a', DateTime(2026, 5, 8, 22)),
      _ci('a', DateTime(2026, 7, 1, 22)),
      _ci('a', DateTime(2026, 7, 8, 22)),
    ])!;
    expect(r.busiestMonth.month, 7);
    expect(r.busiestMonth.nights, 2);
  });

  test('two check-ins on one night count as one night', () {
    final r = personalRecords([
      _ci('a', DateTime(2026, 5, 1, 22)),
      _ci('b', DateTime(2026, 5, 1, 23)),
      _ci('a', DateTime(2026, 6, 1, 22)),
      _ci('a', DateTime(2026, 6, 8, 22)),
    ])!;
    expect(r.busiestMonth.month, 6);
    expect(r.busiestMonth.nights, 2);
  });

  test('mostVisitedCity counts distinct nights, not check-ins', () {
    final r = personalRecords([
      _ci('a', DateTime(2026, 5, 1, 21), city: 'Cluj'),
      _ci('b', DateTime(2026, 5, 1, 22), city: 'Cluj'),
      _ci('c', DateTime(2026, 5, 1, 23), city: 'Cluj'),
      _ci('d', DateTime(2026, 5, 8, 22), city: 'Bucharest'),
      _ci('d', DateTime(2026, 5, 15, 22), city: 'Bucharest'),
    ])!;
    expect(r.mostVisitedCity, 'Bucharest');
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
      const MaterialApp(home: Scaffold(body: PersonalRecordsCard())),
    );
  }

  testWidgets('card shows records', (tester) async {
    await pump(tester, [
      _ci('a', DateTime(2026, 3, 14, 22)),
      _ci('b', DateTime(2026, 3, 14, 23)),
      _ci('c', DateTime(2026, 3, 15, 2)),
    ]);
    expect(find.text('Your records'), findsOneWidget);
    expect(find.textContaining('Biggest night: 3 clubs'), findsOneWidget);
  });

  testWidgets('card is empty with no check-ins', (tester) async {
    await pump(tester, []);
    expect(find.text('Your records'), findsNothing);
  });
}
