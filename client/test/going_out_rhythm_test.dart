import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/going_out_rhythm.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/rhythm_card.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckInModel _ci(DateTime at) => CheckInModel(
  id: at.toIso8601String(),
  clubId: 'a',
  checkedInAt: at,
  verificationMethod: 'QR_GPS',
  distanceMeters: 10,
  club: ClubModel.fromMap({
    'id': 'a',
    'name': 'Club a',
    'address': '1 Main St',
    'city': 'Cluj',
    'latitude': 46,
    'longitude': 23.5,
    'imageUrl': 'http://img',
  }),
);

void main() {
  // 2026-09-05 is a Saturday, 09-04 a Friday.
  test('two nights give null', () {
    expect(
      goingOutRhythm([
        _ci(DateTime(2026, 9, 5, 23)),
        _ci(DateTime(2026, 9, 12, 23)),
      ]),
      isNull,
    );
  });

  test('Sunday 02:00 counts toward Saturday', () {
    final r = goingOutRhythm([
      _ci(DateTime(2026, 9, 6, 2)),
      _ci(DateTime(2026, 9, 12, 23)),
      _ci(DateTime(2026, 9, 19, 23)),
    ])!;
    expect(r.nightsByWeekday, [0, 0, 0, 0, 0, 3, 0]);
    expect(r.topWeekday, 5);
  });

  test('two check-ins on one night count once; first feeds arrival', () {
    final r = goingOutRhythm([
      _ci(DateTime(2026, 9, 5, 22)),
      _ci(DateTime(2026, 9, 6, 3)),
      _ci(DateTime(2026, 9, 12, 22)),
      _ci(DateTime(2026, 9, 19, 22)),
    ])!;
    expect(r.nightsByWeekday.reduce((a, b) => a + b), 3);
    expect(r.typicalArrival, (hour: 22, minute: 0));
  });

  test('median arrival across midnight', () {
    final r = goingOutRhythm([
      _ci(DateTime(2026, 9, 5, 23, 30)),
      _ci(DateTime(2026, 9, 13, 0, 30)),
      _ci(DateTime(2026, 9, 20, 1)),
    ])!;
    expect(r.typicalArrival, (hour: 0, minute: 30));
  });

  test('tie between Friday and Saturday picks Saturday', () {
    final r = goingOutRhythm([
      _ci(DateTime(2026, 9, 4, 23)),
      _ci(DateTime(2026, 9, 5, 23)),
      _ci(DateTime(2026, 9, 11, 23)),
      _ci(DateTime(2026, 9, 12, 23)),
    ])!;
    expect(r.topWeekday, 5);
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
      const MaterialApp(home: Scaffold(body: RhythmCard())),
    );
  }

  testWidgets('card shows weekday and arrival', (tester) async {
    await pump(tester, [
      _ci(DateTime(2026, 9, 5, 23)),
      _ci(DateTime(2026, 9, 12, 23)),
      _ci(DateTime(2026, 9, 19, 23)),
    ]);
    expect(find.text('Your rhythm'), findsOneWidget);
    expect(find.text('Mostly Saturdays'), findsOneWidget);
    expect(find.textContaining('Usually in by'), findsOneWidget);
  });

  testWidgets('card is empty with two nights', (tester) async {
    await pump(tester, [
      _ci(DateTime(2026, 9, 5, 23)),
      _ci(DateTime(2026, 9, 12, 23)),
    ]);
    expect(find.text('Your rhythm'), findsNothing);
    expect(find.textContaining('Usually in by'), findsNothing);
  });
}
