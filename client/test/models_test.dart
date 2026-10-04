import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_data_health_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_ranking_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> clubMap() => {
  'id': 'c1',
  'name': 'Club One',
  'address': '1 Main St',
  'city': 'Cluj',
  'latitude': 46,
  'longitude': 23.5,
  'imageUrl': 'http://img',
};

void main() {
  group('ClubModel.fromMap', () {
    test('parses fields and coerces ints to doubles', () {
      final club = ClubModel.fromMap(clubMap());
      expect(club.name, 'Club One');
      expect(club.latitude, 46.0);
      expect(club.longitude, 23.5);
      expect(club.qrCode, isNull);
    });

    test('defaults isApproved to false when missing', () {
      expect(ClubModel.fromMap(clubMap()).isApproved, isFalse);
    });

    test('keeps isApproved and qrCode when present', () {
      final club = ClubModel.fromMap({
        ...clubMap(),
        'isApproved': true,
        'qrCode': 'abc',
      });
      expect(club.isApproved, isTrue);
      expect(club.qrCode, 'abc');
    });
  });

  group('CheckInModel.fromMap', () {
    test('parses nested club, date and distance', () {
      final checkIn = CheckInModel.fromMap({
        'id': 'k1',
        'clubId': 'c1',
        'checkedInAt': '2026-10-01T22:00:00.000Z',
        'verificationMethod': 'QR_GPS',
        'distanceMeters': 42,
        'club': clubMap(),
      });
      expect(checkIn.distanceMeters, 42.0);
      expect(checkIn.checkedInAt.toUtc().hour, 22);
      expect(checkIn.club.id, 'c1');
    });
  });

  // A full ranking fixture is parsed and rendered in admin_metrics_test.dart.
  group('ClubRankingModel', () {
    test('defaults to an empty list without clubs', () {
      expect(ClubRankingModel.fromJson({}).clubs, isEmpty);
    });
  });

  group('ClubDataHealthModel', () {
    test('parses a fixture', () {
      final m = ClubDataHealthModel.fromJson({
        'invalidCoordinates': [
          {'id': 'c1', 'name': 'Zero', 'city': 'Cluj'},
        ],
        'nearDuplicates': [
          {
            'a': {'id': 'c2', 'name': 'Club X'},
            'b': {'id': 'c3', 'name': 'Club X Bar'},
            'meters': 12,
            'sameName': false,
          },
        ],
        'farFromCity': [
          {'id': 'c4', 'name': 'Club Y', 'city': 'Cluj', 'km': 41.3},
        ],
      });
      expect(m.invalidCoordinates.single.name, 'Zero');
      expect(m.nearDuplicates.single.b.name, 'Club X Bar');
      expect(m.nearDuplicates.single.meters, 12);
      expect(m.farFromCity.single.km, 41.3);
    });
  });
}
