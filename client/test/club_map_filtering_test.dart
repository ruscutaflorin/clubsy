import 'package:clubsy/data/classes/club_map_filtering.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:flutter_test/flutter_test.dart';

ClubModel fixtureClub(String id, double lat, double lng) => ClubModel(
  id: id,
  name: 'Club $id',
  address: '1 Main St',
  city: 'Cluj',
  latitude: lat,
  longitude: lng,
  imageUrl: 'http://img',
  isApproved: true,
);

void main() {
  final a = fixtureClub('a', 46.0, 23.0);
  final b = fixtureClub('b', 47.0, 24.0);
  final c = fixtureClub('c', 45.0, 22.0);

  group('clubsForMap', () {
    test('returns every club when not filtering', () {
      expect(clubsForMap([a, b, c], {'a'}, false), [a, b, c]);
    });

    test('returns only visited clubs when filtering', () {
      expect(clubsForMap([a, b, c], {'a', 'c'}, true), [a, c]);
    });
  });

  group('boundsFor', () {
    test('returns null for an empty list', () {
      expect(boundsFor([]), isNull);
    });

    test('returns a zero-size box for a single club', () {
      final bounds = boundsFor([a]);
      expect(bounds!.south, a.latitude);
      expect(bounds.north, a.latitude);
      expect(bounds.west, a.longitude);
      expect(bounds.east, a.longitude);
    });

    test('finds the correct SW/NE corners across several clubs', () {
      final bounds = boundsFor([a, b, c]);
      expect(bounds!.south, 45.0);
      expect(bounds.north, 47.0);
      expect(bounds.west, 22.0);
      expect(bounds.east, 24.0);
    });
  });
}
