import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/been_a_while.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/been_a_while_card.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckInModel _ci(String clubId, DateTime at) => CheckInModel(
  id: '$clubId-${at.toIso8601String()}',
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
  final now = DateTime(2026, 10, 3, 12);
  DateTime ago(int days, [int hour = 22]) => DateTime(2026, 10, 3 - days, hour);

  test('club with 3 nights, last 45 days ago, is returned', () {
    final r = beenAWhile([
      _ci('a', ago(80)),
      _ci('a', ago(60)),
      _ci('a', ago(45)),
    ], now);
    expect(r, hasLength(1));
    expect(r.first.nights, 3);
    expect(r.first.daysSince, 45);
  });

  test('recently visited club is excluded', () {
    expect(beenAWhile([_ci('a', ago(60)), _ci('a', ago(10))], now), isEmpty);
  });

  test('single night is excluded', () {
    expect(beenAWhile([_ci('a', ago(60))], now), isEmpty);
  });

  test('23:00 and 02:00 on the same night count as one night', () {
    final r = beenAWhile([
      _ci('a', DateTime(2026, 8, 1, 23)),
      _ci('a', DateTime(2026, 8, 2, 2)),
    ], now);
    expect(r, isEmpty);
  });

  test('sorted by nights then recency, and limited', () {
    final list = [
      _ci('a', ago(90)),
      _ci('a', ago(80)),
      _ci('b', ago(90)),
      _ci('b', ago(70)),
      _ci('c', ago(90)),
      _ci('c', ago(80)),
      _ci('c', ago(60)),
      _ci('d', ago(100)),
      _ci('d', ago(95)),
    ];
    final r = beenAWhile(list, now);
    expect(r.map((e) => e.club.id), ['c', 'b', 'a']);
    expect(beenAWhile(list, now, limit: 1).single.club.id, 'c');
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
      MaterialApp(
        home: Scaffold(body: BeenAWhileCard(now: now)),
      ),
    );
  }

  testWidgets('card shows quiet favourites', (tester) async {
    await pump(tester, [_ci('a', ago(60)), _ci('a', ago(50))]);
    expect(find.text('Been a while'), findsOneWidget);
    expect(find.textContaining('Club a'), findsOneWidget);
  });

  testWidgets('card is empty when favourites were visited recently', (
    tester,
  ) async {
    await pump(tester, [_ci('a', ago(60)), _ci('a', ago(5))]);
    expect(find.text('Been a while'), findsNothing);
  });
}
