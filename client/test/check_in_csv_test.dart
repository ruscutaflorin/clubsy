import 'package:flutter_test/flutter_test.dart';
import 'package:clubsy/data/classes/check_in_csv.dart';

const header = 'date,time,club,city,address,distance_m,verification';

Map<String, dynamic> exportWith(
  List<Map<String, dynamic>> clubs, {
  double distance = 10,
}) {
  return {
    'user': {'id': 'user-1', 'email': 'me@example.com'},
    'checkIns': [
      for (var i = 0; i < clubs.length; i++)
        {
          'id': 'ci-$i',
          'checkedInAt': '2026-03-05T21:07:00.000Z',
          'distanceMeters': distance,
          'verificationMethod': 'qr_gps',
          'club': {
            'id': 'club-id-$i',
            'city': 'Cluj',
            'address': 'Main St 1',
            'latitude': 46.77,
            'longitude': 23.59,
            ...clubs[i],
          },
        },
    ],
  };
}

void main() {
  test('empty export gives only the header', () {
    expect(checkInsToCsv({'checkIns': []}), header);
    expect(checkInsToCsv({}), header);
  });

  test('quotes fields with commas and quotes', () {
    final csv = checkInsToCsv(
      exportWith([
        {'name': 'Bar "X", Old Town'},
      ]),
    );
    expect(csv, contains('"Bar ""X"", Old Town"'));
  });

  test('prefixes formula-looking fields', () {
    final csv = checkInsToCsv(
      exportWith([
        {'name': '=SUM(A1)'},
      ]),
    );
    expect(csv, contains(",'=SUM(A1),"));
  });

  test('rounds distance', () {
    final csv = checkInsToCsv(
      exportWith([
        {'name': 'A'},
      ], distance: 42.6),
    );
    expect(csv, contains(',43,'));
  });

  test('rows use CRLF and no ids or email leak', () {
    final csv = checkInsToCsv(
      exportWith([
        {'name': 'A'},
        {'name': 'B'},
      ]),
    );
    final lines = csv.split('\r\n');
    expect(lines.length, 3);
    expect(lines.first, header);
    expect(csv, isNot(contains('me@example.com')));
    expect(csv, isNot(contains('club-id-')));
    expect(csv, isNot(contains('46.77')));
  });
}
