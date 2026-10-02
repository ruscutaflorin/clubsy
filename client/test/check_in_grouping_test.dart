import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/check_in_history_page.dart';

CheckInModel _ci(String id, String clubId, DateTime at) => CheckInModel(
  id: id,
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

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckInModel _named(String id, String name, String city, DateTime at) =>
    CheckInModel(
      id: id,
      clubId: id,
      checkedInAt: at,
      verificationMethod: 'QR_GPS',
      distanceMeters: 10,
      club: ClubModel.fromMap({
        'id': id,
        'name': name,
        'address': '1 Main St',
        'city': city,
        'latitude': 46,
        'longitude': 23.5,
        'imageUrl': 'http://img',
      }),
    );

void main() {
  group('filterNightGroups', () {
    final groups = groupByNight([
      _named('1', 'Techno Hall', 'Cluj', DateTime(2026, 9, 12, 23)),
      _named('2', 'Pop Bar', 'Bucharest', DateTime(2026, 9, 13, 1)),
      _named('3', 'Disco', 'Iasi', DateTime(2026, 8, 1, 23)),
    ]);

    test('matches club name case-insensitively', () {
      final r = filterNightGroups(groups, 'techno');
      expect(r.length, 1);
      expect(r.first.checkIns.single.club.name, 'Techno Hall');
    });

    test('matches city', () {
      final r = filterNightGroups(groups, ' CLUJ ');
      expect(r.length, 1);
      expect(r.first.checkIns.single.club.city, 'Cluj');
    });

    test('keeps only matching check-ins in a night', () {
      final r = filterNightGroups(groups, 'pop');
      expect(r.length, 1);
      expect(r.first.checkIns.length, 1);
      expect(r.first.checkIns.single.club.name, 'Pop Bar');
    });

    test('empty or blank query returns all groups', () {
      expect(filterNightGroups(groups, ''), groups);
      expect(filterNightGroups(groups, '   '), groups);
    });

    test('no match returns empty list', () {
      expect(filterNightGroups(groups, 'nowhere'), isEmpty);
    });
  });

  test('23:00 and 02:00 next day share a night, 07:00 starts a new one', () {
    final groups = groupByNight([
      _ci('1', 'a', DateTime(2026, 9, 12, 23)),
      _ci('2', 'b', DateTime(2026, 9, 13, 2)),
      _ci('3', 'c', DateTime(2026, 9, 13, 7)),
    ]);
    expect(groups.length, 2);
    expect(groups[0].night, DateTime(2026, 9, 13));
    expect(groups[1].night, DateTime(2026, 9, 12));
    expect(groups[1].checkIns.length, 2);
  });

  test('groups and items are newest first', () {
    final groups = groupByNight([
      _ci('old', 'a', DateTime(2026, 9, 1, 22)),
      _ci('early', 'a', DateTime(2026, 9, 12, 22)),
      _ci('late', 'b', DateTime(2026, 9, 13, 1)),
    ]);
    expect(groups.map((g) => g.night), [
      DateTime(2026, 9, 12),
      DateTime(2026, 9, 1),
    ]);
    expect(groups[0].checkIns.map((c) => c.id), ['late', 'early']);
  });

  test('labels, times and summary', () {
    final now = DateTime(2026, 9, 20);
    expect(formatNightLabel(DateTime(2026, 9, 12), now: now), 'Sat 12 Sep');
    expect(
      formatNightLabel(DateTime(2025, 9, 12), now: now),
      'Fri 12 Sep 2025',
    );
    expect(formatTime(DateTime(2026, 9, 12, 1, 5)), '01:05');
    final items = [
      _ci('1', 'a', DateTime(2026, 9, 12, 23)),
      _ci('2', 'b', DateTime(2026, 9, 13, 2)),
      _ci('3', 'a', DateTime(2026, 9, 5, 22)),
      _ci('4', 'c', DateTime(2026, 8, 5, 22)),
    ];
    expect(monthSummary(items, now: now), 'This month: 2 nights · 2 clubs');
    expect(
      formatGroupHeader(groupByNight(items)[0], now: now),
      'Sat 12 Sep · 2 clubs',
    );
  });

  testWidgets('history page shows night headers and times', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final c = ClubController(
      clubService: _NoClubs(),
      checkInService: _NoCheckIns(),
    );
    Get.put<ClubController>(c);
    c.myCheckIns.assignAll([
      _ci('1', 'a', DateTime(2025, 9, 12, 23, 30)),
      _ci('2', 'b', DateTime(2025, 9, 13, 2, 15)),
      _ci('3', 'c', DateTime(2025, 9, 20, 22, 45)),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: CheckInHistoryPage()));
    await tester.pump();

    expect(find.text('Sat 20 Sep 2025 · 1 club'), findsOneWidget);
    expect(find.text('Fri 12 Sep 2025 · 2 clubs'), findsOneWidget);
    expect(find.text('Cluj · 22:45'), findsOneWidget);
    expect(find.text('Cluj · 02:15'), findsOneWidget);
  });
}
