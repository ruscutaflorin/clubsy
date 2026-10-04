import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/club_directions.dart';
import 'package:clubsy/data/classes/club_model.dart';

final club = ClubModel(
  id: 'a',
  name: 'Club & Co',
  address: '1 Main St',
  city: 'Cluj',
  latitude: 46.77,
  longitude: -23.5,
  imageUrl: '',
  isApproved: true,
);

ClubModel at(String id, String name, double lat, {bool approved = true}) =>
    ClubModel(
      id: id,
      name: name,
      address: '1 Main St',
      city: 'Cluj',
      latitude: lat,
      longitude: 23.5,
      imageUrl: '',
      isApproved: approved,
    );

void main() {
  group('distanceMeters', () {
    test('0.009 degrees of latitude is about 1 km; same point is 0', () {
      expect(distanceMeters(46, 23.5, 46.009, 23.5), closeTo(1000, 5));
      expect(distanceMeters(46, 23.5, 46, 23.5), 0);
    });
  });

  group('nearbyClubs', () {
    final here = at('here', 'Here', 46);

    test('ranks by distance and excludes far, unapproved and self', () {
      final result = nearbyClubs(here, [
        here,
        at('far', 'Far', 46.0072),
        at('near', 'Near', 46.0027),
        at('away', 'Away', 46.0135),
        at('pending', 'Pending', 46.0009, approved: false),
      ]);
      expect(result.map((r) => r.club.id), ['near', 'far']);
    });

    test('respects limit', () {
      final result = nearbyClubs(here, [
        at('a', 'A', 46.001),
        at('b', 'B', 46.002),
        at('c', 'C', 46.003),
      ], limit: 2);
      expect(result.map((r) => r.club.id), ['a', 'b']);
    });
  });

  group('directionsUri', () {
    test('android uses geo: with encoded coordinates and label', () {
      final uri = directionsUri(club, TargetPlatform.android);
      expect(uri.scheme, 'geo');
      expect(uri.toString(), contains('46.77'));
      expect(uri.toString(), contains('Club%20%26%20Co'));
    });

    test('ios uses Apple Maps daddr with encoded coordinates', () {
      final uri = directionsUri(club, TargetPlatform.iOS);
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['daddr'], '46.77,-23.5');
      expect(uri.toString(), contains('daddr=46.77%2C-23.5'));
    });
  });

  test('formatDistance', () {
    expect(formatDistance(0), '0 m');
    expect(formatDistance(350), '350 m');
    expect(formatDistance(999), '999 m');
    expect(formatDistance(1000), '1.0 km');
    expect(formatDistance(1549), '1.5 km');
  });

  test('clubShareText', () {
    expect(clubShareText(club), 'Club & Co in Cluj — on Clubsy');
  });
}
