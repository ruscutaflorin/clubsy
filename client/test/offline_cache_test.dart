import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/services/local_cache.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';

ClubModel _club(String id) => ClubModel.fromMap({
  'id': id,
  'name': 'Club $id',
  'address': '1 Main St',
  'city': 'Cluj',
  'latitude': 46,
  'longitude': 23.5,
  'imageUrl': 'http://img',
});

class _FakeClubs implements ClubService {
  Object? error;

  @override
  Future<List<ClubModel>> getClubs({String? search, String? city}) async {
    if (error != null) throw error!;
    return [_club('a')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCheckIns implements CheckInService {
  @override
  Future<List<CheckInModel>> getMyCheckIns() async => [];

  @override
  Future<CheckInStatsModel> getMyStats() async =>
      CheckInStatsModel(totalCheckIns: 1, uniqueClubs: 1, uniqueCities: 1);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeClubs clubsSvc;
  ClubController make() =>
      ClubController(clubService: clubsSvc, checkInService: _FakeCheckIns());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clubsSvc = _FakeClubs();
  });

  test('success clears loadError and writes the cache', () async {
    final c = make();
    c.loadError.value = 'old';
    await c.refresh();
    expect(c.loadError.value, isNull);
    expect(c.isOffline.value, isFalse);
    final cached = await LocalCache().read();
    expect(cached?.clubs.single.id, 'a');
    expect(cached?.stats?.totalCheckIns, 1);
  });

  test('failure sets loadError and keeps cached clubs', () async {
    await make().refresh();
    final c = make();
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.clubs.single.id, 'a');

    clubsSvc.error = ApiException(0, connectionErrorMessage);
    await c.refresh();
    expect(c.loadError.value, connectionErrorMessage);
    expect(c.isOffline.value, isTrue);
    expect(c.clubs.single.id, 'a');
  });

  test('server error is not offline; Not authenticated is ignored', () async {
    final c = make();
    clubsSvc.error = ApiException(500, 'Boom');
    await c.refresh();
    expect(c.loadError.value, 'Boom');
    expect(c.isOffline.value, isFalse);

    final d = make();
    clubsSvc.error = ApiException(401, 'Not authenticated');
    await d.refresh();
    expect(d.loadError.value, isNull);
  });

  test('sign-out empties the cache', () async {
    await make().refresh();
    expect(await LocalCache().read(), isNotNull);
    await AuthController().signOut();
    expect(await LocalCache().read(), isNull);
  });

  testWidgets('banner shows time and Retry calls the callback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorBanner(
            error: 'x',
            savedAt: DateTime(2026, 1, 1, 21, 4),
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(
      find.text("Couldn't refresh — showing data from 21:04"),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
