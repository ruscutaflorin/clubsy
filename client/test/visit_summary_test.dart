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

void main() {
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
}
