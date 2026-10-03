import 'dart:async';
import 'dart:convert';

import 'package:clubsy/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient clientFor(
  MockClient mock, {
  String? token = 'tok',
  void Function()? onUnauthorized,
  Duration timeout = const Duration(seconds: 1),
}) => ApiClient(
  client: mock,
  tokenProvider: () async => token,
  onUnauthorized: onUnauthorized,
  timeout: timeout,
  baseUrl: 'http://test/api',
);

void main() {
  test('sets the Authorization header and decodes JSON', () async {
    String? auth;
    final api = clientFor(
      MockClient((req) async {
        auth = req.headers['Authorization'];
        return http.Response(json.encode({'ok': true}), 200);
      }),
    );
    expect(await api.get('/x'), {'ok': true});
    expect(auth, 'Bearer tok');
  });

  test('a missing token throws before any request', () async {
    var called = false;
    final api = clientFor(
      MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      }),
      token: null,
    );
    await expectLater(
      api.get('/x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Not authenticated',
        ),
      ),
    );
    expect(called, isFalse);
  });

  test('400 {errors} gives fieldErrors and the first message', () async {
    final api = clientFor(
      MockClient(
        (req) async => http.Response(
          json.encode({
            'errors': [
              {'msg': 'bad email'},
              {'msg': 'bad name'},
            ],
          }),
          400,
        ),
      ),
    );
    await expectLater(
      api.post('/x', body: {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'bad email')
            .having((e) => e.fieldErrors, 'fieldErrors', [
              'bad email',
              'bad name',
            ]),
      ),
    );
  });

  test('{message} is used and a 500 HTML body gives a generic message', () {
    expect(
      ApiException.fromResponse(404, '{"message":"Club not found"}').message,
      'Club not found',
    );
    final e = ApiException.fromResponse(500, '<html>oops</html>');
    expect(e.statusCode, 500);
    expect(e.message, isNot(contains('<html>')));
    expect(e.message, isNotEmpty);
  });

  test('a timeout gives the connection message', () async {
    final api = clientFor(
      MockClient((req) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(
      api.get('/x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          connectionErrorMessage,
        ),
      ),
    );
  });

  test('onUnauthorized fires once per 401, not for auth endpoints', () async {
    var calls = 0;
    final api = clientFor(
      MockClient((req) async => http.Response('{"message":"no"}', 401)),
      onUnauthorized: () => calls++,
    );
    await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
    expect(calls, 1);
    await expectLater(
      api.post('/auth/signin', authenticated: false),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
  });
}
