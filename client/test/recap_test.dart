import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/recap.dart';
import 'package:clubsy/views/pages/recap_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

class _NoClubs implements ClubService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCheckIns implements CheckInService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Recap _nights(int n) => Recap(
  nightsOut: n,
  distinctClubs: n,
  distinctCities: 1,
  topClub: null,
  topClubVisits: 0,
  busiestWeekday: null,
  latestNight: null,
  newClubs: 0,
);

CheckInModel ci(String clubId, DateTime at, {String city = 'Cluj'}) =>
    CheckInModel(
      id: '$clubId-$at',
      clubId: clubId,
      checkedInAt: at,
      verificationMethod: 'QR',
      distanceMeters: 10,
      club: ClubModel(
        id: clubId,
        name: 'Secret $clubId',
        address: '1 Main St',
        city: city,
        latitude: 46,
        longitude: 23.5,
        imageUrl: 'http://img',
        isApproved: true,
      ),
    );

void main() {
  final from = DateTime(2026, 9, 1, 6);
  final to = DateTime(2026, 10, 1, 6);

  group('buildRecap', () {
    test('empty period', () {
      final r = buildRecap([], from: from, to: to);
      expect(r.isEmpty, isTrue);
      expect(r.topClub, isNull);
      expect(r.busiestWeekday, isNull);
      expect(r.latestNight, isNull);
      expect(r.newClubs, 0);
    });

    test('period boundary at 06:00', () {
      final r = buildRecap(
        [
          ci('a', DateTime(2026, 9, 1, 5, 59)),
          ci('b', DateTime(2026, 9, 1, 6)),
          ci('c', DateTime(2026, 10, 1, 5, 59)),
          ci('d', DateTime(2026, 10, 1, 6)),
        ],
        from: from,
        to: to,
      );
      expect(r.distinctClubs, 2);
      expect(r.nightsOut, 2);
    });

    test('top club ties go to the most recent visit', () {
      final r = buildRecap(
        [
          ci('a', DateTime(2026, 9, 3, 23)),
          ci('b', DateTime(2026, 9, 10, 23)),
          ci('a', DateTime(2026, 9, 17, 23)),
          ci('b', DateTime(2026, 9, 24, 23)),
        ],
        from: from,
        to: to,
      );
      expect(r.topClub!.id, 'b');
      expect(r.topClubVisits, 2);
    });

    test('new clubs are first-ever visits inside the period', () {
      final r = buildRecap(
        [
          ci('a', DateTime(2026, 8, 20, 23)),
          ci('a', DateTime(2026, 9, 5, 23)),
          ci('b', DateTime(2026, 9, 6, 23), city: 'Iasi'),
        ],
        from: from,
        to: to,
      );
      expect(r.newClubs, 1);
      expect(r.distinctCities, 2);
    });

    test('latest night is closest to 06:00 and weekday uses the night', () {
      final r = buildRecap(
        [
          ci('a', DateTime(2026, 9, 5, 23)), // Saturday
          ci('b', DateTime(2026, 9, 6, 4, 30)), // still Saturday's night
        ],
        from: from,
        to: to,
      );
      expect(r.nightsOut, 1);
      expect(r.busiestWeekday, DateTime.saturday);
      expect(r.latestNight, DateTime(2026, 9, 6, 4, 30));
    });
  });

  group('RecapCard', () {
    final recap = buildRecap(
      [ci('a', DateTime(2026, 9, 5, 23))],
      from: from,
      to: to,
    );

    Widget host(bool hide) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 800,
          child: RecapCard(
            recap: recap,
            title: 'Your September',
            hideClubNames: hide,
          ),
        ),
      ),
    );

    testWidgets('hides club names when asked', (tester) async {
      await tester.pumpWidget(host(true));
      expect(find.textContaining('Secret'), findsNothing);
      expect(find.text('Top spot: 1 visits'), findsOneWidget);
    });

    testWidgets('shows club names when allowed', (tester) async {
      await tester.pumpWidget(host(false));
      expect(find.textContaining('Secret a'), findsOneWidget);
    });
  });

  group('comparison', () {
    String? line(int cur, int prev) =>
        comparisonLine(compareRecaps(_nights(cur), _nights(prev)), 'August');

    test('lines', () {
      expect(line(6, 4), '+2 nights vs August');
      expect(line(5, 4), '+1 night vs August');
      expect(line(3, 4), '-1 night vs August');
      expect(line(2, 4), '-2 nights vs August');
      expect(line(4, 4), 'Same number of nights as August');
      expect(line(4, 0), isNull);
    });

    test('previousMonthRange across January', () {
      final r = previousMonthRange(DateTime(2026, 2, 10));
      expect(r.$1, DateTime(2025, 12, 1, 6));
      expect(r.$2, DateTime(2026, 1, 1, 6));
    });

    Future<void> pump(WidgetTester tester, List<CheckInModel> items) async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      final c = ClubController(
        clubService: _NoClubs(),
        checkInService: _NoCheckIns(),
      );
      Get.put<ClubController>(c);
      c.myCheckIns.assignAll(items);
      await tester.pumpWidget(const GetMaterialApp(home: RecapPage()));
      await tester.pump();
    }

    testWidgets('page shows comparison', (tester) async {
      final now = DateTime.now();
      final last = lastMonthRange(now).$1;
      final prev = previousMonthRange(now).$1;
      await pump(tester, [
        ci('a', DateTime(last.year, last.month, 5, 23)),
        ci('a', DateTime(last.year, last.month, 6, 23)),
        ci('a', DateTime(prev.year, prev.month, 5, 23)),
      ]);
      final label = lastMonthName(DateTime(prev.year, prev.month + 1));
      expect(
        tester.widget<Text>(find.byKey(const Key('recapComparison'))).data,
        '+1 night vs $label',
      );
    });

    testWidgets('page hides comparison without previous check-ins', (
      tester,
    ) async {
      final last = lastMonthRange(DateTime.now()).$1;
      await pump(tester, [ci('a', DateTime(last.year, last.month, 5, 23))]);
      expect(find.byKey(const Key('recapComparison')), findsNothing);
    });
  });
}
