import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/city_progress_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
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

CheckInModel _record(String id, String clubId) => checkIn(id, clubId);

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

    test('checkIn re-fetches stats afterwards', () async {
      final fake = _FakeCheckInService();
      final controller = ClubController(checkInService: fake);
      expect(controller.stats.value, isNull);

      await controller.checkIn(
        clubId: 'a',
        qrPayload: 'qr',
        latitude: 1,
        longitude: 2,
        isMocked: false,
        accuracyMeters: 7,
      );
      await Future<void>.delayed(Duration.zero);

      expect(fake.statsCalls, 1);
      expect(fake.lastAccuracy, 7);
      expect(controller.myCheckIns.single.clubId, 'a');
      expect(controller.stats.value?.totalCheckIns, 5);
    });

    test('a failing stats re-fetch does not fail the check-in', () async {
      final fake = _FakeCheckInService(statsFail: true);
      final controller = ClubController(checkInService: fake);
      final record = await controller.checkIn(
        clubId: 'a',
        qrPayload: 'qr',
        latitude: 1,
        longitude: 2,
      );
      await Future<void>.delayed(Duration.zero);
      expect(record.record.clubId, 'a');
      expect(record.outcome.isFirstVisit, isTrue);
      expect(controller.stats.value, isNull);
    });

    test('removing a club\'s only check-in unvisits it', () async {
      final fake = _FakeCheckInService();
      final controller = ClubController(checkInService: fake);
      controller.myCheckIns.addAll([checkIn('1', 'a'), checkIn('2', 'b')]);
      await controller.removeCheckIn('1');
      expect(controller.visitedClubIds, {'b'});
      expect(fake.statsCalls, 1);
    });

    test('removing one of two check-ins keeps the club visited', () async {
      final controller = ClubController(checkInService: _FakeCheckInService());
      controller.myCheckIns.addAll([checkIn('1', 'a'), checkIn('2', 'a')]);
      await controller.removeCheckIn('1');
      expect(controller.visitedClubIds, {'a'});
      expect(controller.myCheckIns.length, 1);
    });

    test('a service error restores the list', () async {
      final controller = ClubController(
        checkInService: _FakeCheckInService(deleteFail: true),
      );
      controller.myCheckIns.addAll([checkIn('1', 'a'), checkIn('2', 'b')]);
      await expectLater(controller.removeCheckIn('1'), throwsException);
      expect(controller.myCheckIns.map((c) => c.id), ['1', '2']);
    });

    test('toggleFavorite is optimistic and calls the server', () async {
      final service = _FakeClubService();
      final controller = ClubController(clubService: service);
      final pending = controller.toggleFavorite('a');
      expect(controller.favoriteIds, {'a'});
      await pending;
      await controller.toggleFavorite('a');
      expect(controller.favoriteIds, isEmpty);
      expect(service.calls, ['a:true', 'a:false']);
    });

    test('toggleFavorite rolls back when the server call fails', () async {
      final controller = ClubController(
        clubService: _FakeClubService(fail: true),
      );
      await expectLater(controller.toggleFavorite('a'), throwsException);
      expect(controller.favoriteIds, isEmpty);

      controller.favoriteIds.add('b');
      await expectLater(controller.toggleFavorite('b'), throwsException);
      expect(controller.favoriteIds, {'b'});
    });

    test('checking into a favourite for the first time ticks it off', () async {
      final controller = ClubController(checkInService: _FakeCheckInService());
      controller.favoriteIds.add('a');
      final result = await controller.checkIn(
        clubId: 'a',
        qrPayload: 'qr',
        latitude: 1,
        longitude: 2,
      );
      expect(result.tickedOffList, isTrue);
    });

    test(
      'updateDiary applies a vibe and rolls back when the save fails',
      () async {
        final ok = ClubController(checkInService: _FakeCheckInService());
        ok.myCheckIns.add(_record('n1', 'a'));
        await ok.updateDiary('n1', vibe: 4);
        expect(ok.myCheckIns.single.vibe, 4);

        final failing = ClubController(
          checkInService: _FakeCheckInService(deleteFail: true),
        );
        failing.myCheckIns.add(_record('n1', 'a'));
        await expectLater(failing.updateDiary('n1', vibe: 4), throwsException);
        expect(failing.myCheckIns.single.vibe, isNull);
      },
    );

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

class _FakeClubService implements ClubService {
  final bool fail;
  final calls = <String>[];

  _FakeClubService({this.fail = false});

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    calls.add('$id:$favorite');
    if (fail) throw Exception('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCheckInService implements CheckInService {
  final bool statsFail;
  final bool deleteFail;
  int statsCalls = 0;
  double? lastAccuracy;

  _FakeCheckInService({this.statsFail = false, this.deleteFail = false});

  @override
  Future<CheckInModel> checkIn({
    required String clubId,
    required String qrPayload,
    required double latitude,
    required double longitude,
    bool? isMocked,
    double? accuracyMeters,
  }) async {
    lastAccuracy = accuracyMeters;
    return _record('new', clubId);
  }

  @override
  Future<CheckInStatsModel> getMyStats() async {
    statsCalls++;
    if (statsFail) throw Exception('boom');
    return CheckInStatsModel(totalCheckIns: 5, uniqueClubs: 3, uniqueCities: 1);
  }

  @override
  Future<AchievementsModel> getMyAchievements() async =>
      const AchievementsModel(currentStreak: 1);

  @override
  Future<List<CityProgressModel>> getMyCities() async => [];

  @override
  Future<List<CheckInModel>> getMyCheckIns() async => [];

  @override
  Future<void> deleteCheckIn(String id) async {
    if (deleteFail) throw Exception('boom');
  }

  @override
  Future<CheckInModel> updateCheckIn(
    String id, {
    String? note,
    int? vibe,
  }) async {
    if (deleteFail) throw Exception('boom');
    return _record(id, 'a').withDiary(note: note, vibe: vibe);
  }
}
