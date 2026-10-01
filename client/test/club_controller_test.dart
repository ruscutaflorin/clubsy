import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

CheckInModel checkIn(String id, String clubId) => CheckInModel(
  id: id,
  clubId: clubId,
  checkedInAt: DateTime.utc(2026, 1, 1),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClubController', () {
    test('visitedClubIds de-duplicates repeat check-ins', () {
      final controller = ClubController();
      controller.myCheckIns.addAll([
        checkIn('1', 'a'),
        checkIn('2', 'a'),
        checkIn('3', 'b'),
      ]);
      expect(controller.visitedClubIds, {'a', 'b'});
    });

    test('refresh while signed out swallows the error', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ClubController();
      await controller.refresh();
      expect(controller.isLoading.value, isFalse);
      expect(controller.clubs, isEmpty);
      expect(controller.myCheckIns, isEmpty);
    });
  });
}
