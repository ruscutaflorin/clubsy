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

void main() {
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
