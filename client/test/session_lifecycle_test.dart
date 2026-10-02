import 'dart:convert';

import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  final Future<Map<String, dynamic>> Function() onMe;
  FakeAuthService(this.onMe);

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Map<String, dynamic>?> getUser() async => {
    'name': 'Cached',
    'role': 'USER',
  };

  @override
  Future<Map<String, dynamic>> fetchMe() => onMe();

  @override
  Future<void> signOut() async {}
}

ApiClient apiWith(int status, void Function() onUnauthorized) => ApiClient(
  client: MockClient((_) async => http.Response('{"message":"no"}', status)),
  tokenProvider: () async => 'tok',
  onUnauthorized: onUnauthorized,
  baseUrl: 'http://test/api',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('401 handling', () {
    test('getClubs and getMyCheckIns invoke the callback once each', () async {
      var calls = 0;
      final api = apiWith(401, () => calls++);
      await expectLater(ClubService(api: api).getClubs(), throwsA(anything));
      expect(calls, 1);
      await expectLater(
        CheckInService(api: api).getMyCheckIns(),
        throwsA(anything),
      );
      expect(calls, 2);
    });

    test('sign-in 401 and 200 do not invoke it', () async {
      var calls = 0;
      final api401 = apiWith(401, () => calls++);
      await expectLater(
        AuthService(api: api401).signIn('a@b.c', 'bad'),
        throwsA(isA<ApiException>()),
      );
      final ok = ApiClient(
        client: MockClient((_) async => http.Response('{"clubs":[]}', 200)),
        tokenProvider: () async => 'tok',
        onUnauthorized: () => calls++,
        baseUrl: 'http://test/api',
      );
      await ClubService(api: ok).getClubs();
      expect(calls, 0);
    });
  });

  group('AuthController', () {
    test('startup 200 updates the user; isAdmin only for ADMIN', () async {
      final c = AuthController(
        authService: FakeAuthService(
          () async => {'name': 'Fresh', 'role': 'ADMIN'},
        ),
      );
      await c.checkAuthStatus();
      expect(c.user?['name'], 'Fresh');
      expect(c.isAdmin, isTrue);
      expect(c.isAuthenticated, isTrue);

      final u = AuthController(
        authService: FakeAuthService(() async => {'name': 'U', 'role': 'USER'}),
      );
      await u.checkAuthStatus();
      expect(u.isAdmin, isFalse);
    });

    test('startup 401 and 404 sign out', () async {
      for (final status in [401, 404]) {
        final c = AuthController(
          authService: FakeAuthService(
            () async => throw ApiException(status, 'nope'),
          ),
        );
        await c.checkAuthStatus();
        expect(c.isAuthenticated, isFalse, reason: '$status');
        expect(c.user, isNull);
      }
    });

    test('startup network error stays signed in', () async {
      final c = AuthController(
        authService: FakeAuthService(
          () async => throw ApiException(0, connectionErrorMessage),
        ),
      );
      await c.checkAuthStatus();
      expect(c.isAuthenticated, isTrue);
      expect(c.user?['name'], 'Cached');
    });
  });

  test('fetchMe parses and caches the user', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(json.encode({'name': 'N'}), 200),
      ),
      tokenProvider: () async => 'tok',
      baseUrl: 'http://test/api',
    );
    final service = AuthService(api: api);
    expect((await service.fetchMe())['name'], 'N');
    expect((await service.getUser())?['name'], 'N');
  });
}
