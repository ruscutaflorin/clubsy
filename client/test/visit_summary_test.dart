import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:flutter_test/flutter_test.dart';

ClubModel fixtureClub(String id) => ClubModel(
  id: id,
  name: 'Club',
  address: '1 Main St',
  city: 'Cluj',
  latitude: 46,
  longitude: 23.5,
  imageUrl: 'http://img',
  isApproved: true,
);

CheckInModel fixtureCheckIn(String clubId, DateTime at) => CheckInModel(
  id: '$clubId-$at',
  clubId: clubId,
  checkedInAt: at,
  verificationMethod: 'QR',
  distanceMeters: 10,
  club: fixtureClub(clubId),
);

CheckInModel rated(String clubId, int day, int? vibe) =>
    fixtureCheckIn(clubId, DateTime(2026, 9, day, 23)).withDiary(vibe: vibe);

void main() {
  group('myVibeAtClub', () {
    test('averages non-null ratings at that club only', () {
      final result = myVibeAtClub('a', [
        rated('a', 1, 4),
        rated('a', 2, 5),
        rated('a', 3, null),
        rated('b', 4, 1),
      ]);
      expect(result, (average: 4.5, count: 2));
    });

    test('null when nothing was rated or there are no check-ins', () {
      expect(myVibeAtClub('a', [rated('a', 1, null)]), isNull);
      expect(myVibeAtClub('a', []), isNull);
    });
  });

  group('nightsPerClub', () {
    test('counts distinct nights per club', () {
      final result = nightsPerClub([
        fixtureCheckIn('a', DateTime(2026, 9, 12, 23)),
        fixtureCheckIn('a', DateTime(2026, 9, 19, 23)),
        fixtureCheckIn('b', DateTime(2026, 9, 12, 23)),
      ]);
      expect(result, {'a': 2, 'b': 1});
    });

    test('a small-hours check-in joins the previous evening', () {
      final result = nightsPerClub([
        fixtureCheckIn('a', DateTime(2026, 9, 12, 23)),
        fixtureCheckIn('a', DateTime(2026, 9, 13, 2)),
      ]);
      expect(result, {'a': 1});
    });

    test('empty list gives empty map', () {
      expect(nightsPerClub([]), isEmpty);
    });
  });

  group('visitSummaryForClub', () {
    test('returns null with no visits', () {
      expect(visitSummaryForClub('a', []), isNull);
    });

    test('summarises a single visit', () {
      final at = DateTime.utc(2026, 9, 12);
      final summary = visitSummaryForClub('a', [fixtureCheckIn('a', at)]);
      expect(summary!.visits, 1);
      expect(summary.firstVisit, at);
      expect(summary.lastVisit, at);
    });

    test('picks the earliest and latest from out-of-order visits', () {
      final first = DateTime.utc(2026, 9, 1);
      final middle = DateTime.utc(2026, 9, 12);
      final last = DateTime.utc(2026, 9, 20);
      final summary = visitSummaryForClub('a', [
        fixtureCheckIn('a', middle),
        fixtureCheckIn('a', last),
        fixtureCheckIn('a', first),
      ]);
      expect(summary!.visits, 3);
      expect(summary.firstVisit, first);
      expect(summary.lastVisit, last);
    });

    test('ignores check-ins at other clubs', () {
      final at = DateTime.utc(2026, 9, 12);
      final summary = visitSummaryForClub('a', [
        fixtureCheckIn('a', at),
        fixtureCheckIn('b', at),
        fixtureCheckIn('b', at),
      ]);
      expect(summary!.visits, 1);
    });
  });

  group('nightsAtClub', () {
    test('lists distinct nights newest first, ignoring other clubs', () {
      final nights = nightsAtClub('a', [
        fixtureCheckIn('a', DateTime(2026, 3, 7, 22)),
        fixtureCheckIn('a', DateTime(2026, 3, 14, 22)),
        fixtureCheckIn('b', DateTime(2026, 3, 20, 22)),
      ]);
      expect(nights, [DateTime(2026, 3, 14), DateTime(2026, 3, 7)]);
    });

    test('a 02:00 check-in belongs to the previous evening', () {
      final nights = nightsAtClub('a', [
        fixtureCheckIn('a', DateTime(2026, 3, 14, 23)),
        fixtureCheckIn('a', DateTime(2026, 3, 15, 2)),
      ]);
      expect(nights, [DateTime(2026, 3, 14)]);
    });

    test('unknown club gives an empty list', () {
      expect(
        nightsAtClub('zzz', [fixtureCheckIn('a', DateTime(2026))]),
        isEmpty,
      );
    });
  });

  group('formatNightRow', () {
    test('renders weekday, day, month and year', () {
      expect(formatNightRow(DateTime(2026, 3, 14)), 'Sat 14 Mar 2026');
    });
  });

  group('formatShortDate', () {
    test('formats as day and short month', () {
      expect(formatShortDate(DateTime.utc(2026, 9, 12)), contains('Sep'));
    });
  });

  group('pairedClubs', () {
    CheckInModel at(String id, DateTime when) => CheckInModel(
      id: '$id-$when',
      clubId: id,
      checkedInAt: when,
      verificationMethod: 'QR',
      distanceMeters: 10,
      club: fixtureClub(id),
    );

    final n1 = DateTime(2026, 3, 6, 22);
    final n2 = DateTime(2026, 3, 13, 22);
    final n3 = DateTime(2026, 3, 20, 22);

    test('ranks partners by shared nights', () {
      final result = pairedClubs('a', [
        at('a', n1),
        at('b', n1),
        at('a', n2),
        at('b', n2),
        at('a', n3),
        at('c', n3),
      ]);
      expect(result.map((p) => p.club.id), ['b', 'c']);
      expect(result.map((p) => p.nights), [2, 1]);
    });

    test('a small-hours check-in joins the previous evening', () {
      final result = pairedClubs('a', [
        at('a', DateTime(2026, 3, 6, 23)),
        at('b', DateTime(2026, 3, 7, 2)),
      ]);
      expect(result.single.nights, 1);
    });

    test('two check-ins at the partner on one night count once', () {
      final result = pairedClubs('a', [
        at('a', n1),
        at('b', DateTime(2026, 3, 6, 23)),
        at('b', DateTime(2026, 3, 7, 1)),
      ]);
      expect(result.single.nights, 1);
    });

    test('ignores nights without the club and never returns itself', () {
      final result = pairedClubs('a', [
        at('a', n1),
        at('a', DateTime(2026, 3, 6, 23)),
        at('b', n2),
        at('c', n2),
      ]);
      expect(result, isEmpty);
    });

    test('respects limit', () {
      final result = pairedClubs('a', [
        at('a', n1),
        at('b', n1),
        at('c', n1),
        at('d', n1),
      ], limit: 2);
      expect(result, hasLength(2));
    });

    test('empty without shared nights', () {
      expect(pairedClubs('a', [at('a', n1)]), isEmpty);
      expect(pairedClubs('a', []), isEmpty);
    });
  });

  group('wantToGoList', () {
    ClubModel named(String id, String name) => ClubModel(
      id: id,
      name: name,
      address: '1 Main St',
      city: 'Cluj',
      latitude: 46,
      longitude: 23.5,
      imageUrl: 'http://img',
      isApproved: true,
    );

    final clubs = [named('z', 'Zeta'), named('a', 'alpha'), named('b', 'Beta')];

    test('unvisited first, then visited, alphabetical ignoring case', () {
      final result = wantToGoList(
        clubs,
        <String>{'z', 'a', 'b'},
        [
          fixtureCheckIn('a', DateTime(2026, 9, 12, 23)),
          fixtureCheckIn('a', DateTime(2026, 9, 19, 23)),
        ],
      );
      expect(result.map((e) => e.club.name), ['Beta', 'Zeta', 'alpha']);
      expect(result.map((e) => e.nights), [0, 0, 2]);
    });

    test('skips unknown ids; empty favourites give an empty list', () {
      expect(wantToGoList(clubs, <String>{'gone'}, []), isEmpty);
      expect(wantToGoList(clubs, <String>{}, []), isEmpty);
    });
  });
}
