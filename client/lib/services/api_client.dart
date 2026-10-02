import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:clubsy/services/api_config.dart';

const connectionErrorMessage =
    "The server didn't respond — check your connection";

/// The single error type thrown by [ApiClient]. [statusCode] is 0 when no
/// response was received (timeout, no network).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final List<String> fieldErrors;
  final Map<String, dynamic>? body;

  ApiException(
    this.statusCode,
    this.message, {
    this.fieldErrors = const [],
    this.body,
  });

  /// Parses an error response. Handles `{message}`, `{errors: [{msg}]}` and
  /// non-JSON bodies. Never throws.
  factory ApiException.fromResponse(
    int status,
    String body, {
    String fallback = 'Something went wrong, please try again',
  }) {
    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) {
        return ApiException(status, fallback);
      }
      final fieldErrors =
          (decoded['errors'] as List?)
              ?.map((e) => (e as Map)['msg']?.toString())
              .whereType<String>()
              .toList() ??
          const <String>[];
      final message =
          decoded['message'] as String? ??
          (fieldErrors.isNotEmpty ? fieldErrors.first : fallback);
      return ApiException(
        status,
        message,
        fieldErrors: fieldErrors,
        body: decoded,
      );
    } catch (_) {
      return ApiException(status, fallback);
    }
  }

  @override
  String toString() => message;
}

class ApiClient {
  /// Fallback for clients without their own [onUnauthorized]; the
  /// AuthController registers it so every service signs out on a 401.
  static void Function()? globalOnUnauthorized;

  final http.Client _client;
  final Future<String?> Function() tokenProvider;
  final void Function()? onUnauthorized;
  final Duration timeout;
  final String baseUrl;

  ApiClient({
    http.Client? client,
    required this.tokenProvider,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 15),
    this.baseUrl = apiBaseUrl,
  }) : _client = client ?? http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  /// [expireSession] false: a 401 is an answer to this request (e.g. a wrong
  /// password), not an expired session, so don't sign the user out.
  Future<dynamic> delete(
    String path, {
    Object? body,
    bool authenticated = true,
    bool expireSession = true,
  }) => _send(
    'DELETE',
    path,
    body: body,
    authenticated: authenticated,
    expireSession: expireSession,
  );

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required bool authenticated,
    bool expireSession = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await tokenProvider();
      if (token == null) throw ApiException(401, 'Not authenticated');
      headers['Authorization'] = 'Bearer $token';
    }

    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = json.encode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw ApiException(0, connectionErrorMessage);
    } catch (_) {
      throw ApiException(0, connectionErrorMessage);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return json.decode(response.body);
      } catch (_) {
        throw ApiException(response.statusCode, 'Unexpected server response');
      }
    }
    if (response.statusCode == 401 && authenticated && expireSession) {
      (onUnauthorized ?? globalOnUnauthorized)?.call();
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }
}
