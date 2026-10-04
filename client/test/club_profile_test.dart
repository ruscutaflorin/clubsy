import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_profile.dart';
import 'package:flutter_test/flutter_test.dart';

ClubModel club(List<String> genres) => ClubModel(
  id: 'c',
  name: 'C',
  address: 'a',
  city: 'x',
  latitude: 0,
  longitude: 0,
  imageUrl: 'https://x.com/a.png',
  isApproved: true,
  genres: genres,
);

void main() {
  test('vibeText shows the aggregate or the not-enough hint', () {
    expect(vibeText((average: 4.26, count: 27)), '★ 4.3 · 27 ratings');
    expect(vibeText(null), 'Not enough ratings yet');
    expect(
      ClubModel.fromMap({
        ...club([]).toMap(),
        'vibe': {'average': 4, 'count': 5},
      }).vibe,
      (average: 4.0, count: 5),
    );
  });

  final hours = {
    'fri': [
      {'open': '23:00', 'close': '05:00'},
    ],
    'wed': [
      {'open': '20:00', 'close': '23:00'},
      {'open': '23:30', 'close': '23:45'},
    ],
  };

  group('openingChipText', () {
    // 2026-10-02 is a Friday.
    test('says "Opens 23:00" before a Friday opening', () {
      expect(openingChipText(hours, DateTime(2026, 10, 2, 18)), 'Opens 23:00');
    });

    test('is open late Friday and still open at Saturday 02:00', () {
      expect(openingChipText(hours, DateTime(2026, 10, 2, 23, 30)), 'Open now');
      expect(openingChipText(hours, DateTime(2026, 10, 3, 2)), 'Open now');
    });

    test('is closed after the overnight slot ends', () {
      expect(openingChipText(hours, DateTime(2026, 10, 3, 6)), 'Closed');
    });

    test('names the next slot of the same day', () {
      expect(
        openingChipText(hours, DateTime(2026, 9, 30, 23, 10)),
        'Opens 23:30',
      );
    });

    test('shows no chip without a schedule', () {
      expect(openingChipText(null, DateTime(2026, 10, 2, 23)), isNull);
      expect(openingChipText({'mon': []}, DateTime(2026, 10, 2, 23)), isNull);
    });
  });

  test('openingHoursRows lists all seven days, closed ones included', () {
    final rows = openingHoursRows(hours);
    expect(rows, hasLength(7));
    expect(rows[4], (day: 'Friday', hours: '23:00-05:00'));
    expect(rows[0], (day: 'Monday', hours: 'Closed'));
  });

  test('parseHoursText accepts slots and rejects malformed ones', () {
    expect(parseHoursText(''), isEmpty);
    expect(parseHoursText('22:00-04:00, 12:00-14:00'), [
      {'open': '22:00', 'close': '04:00'},
      {'open': '12:00', 'close': '14:00'},
    ]);
    expect(parseHoursText('7pm-4am'), isNull);
    expect(parseHoursText('22:00-22:00'), isNull);
    expect(hoursTextError('25:00-04:00'), isNotNull);
  });

  test('clubsWithGenre keeps matching clubs and everything for null', () {
    final clubs = [
      club(['techno']),
      club(['house', 'live']),
    ];
    expect(clubsWithGenre(clubs, 'live'), [clubs[1]]);
    expect(clubsWithGenre(clubs, null), clubs);
  });

  test(
    'ClubModel round-trips the profile fields and defaults old payloads',
    () {
      final parsed = ClubModel.fromMap({
        ...club(['techno']).toMap(),
        'description': 'Great',
        'openingHours': hours,
        'websiteUrl': 'https://club.ro',
      });
      expect(parsed.genres, ['techno']);
      expect(parsed.openingHours!['fri'], isNotEmpty);
      expect(parsed.timezone, 'Europe/Bucharest');

      final legacy = ClubModel.fromMap({
        'id': 'c',
        'name': 'C',
        'address': 'a',
        'city': 'x',
        'latitude': 1,
        'longitude': 2,
        'imageUrl': 'u',
      });
      expect(legacy.genres, isEmpty);
      expect(legacy.openingHours, isNull);
    },
  );
}
