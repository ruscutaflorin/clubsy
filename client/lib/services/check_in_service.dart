import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/services/auth_service.dart';

/// A failed check-in attempt, carrying enough of the server's response for
/// the UI to show why: how far away the user was, or which field was
/// rejected, rather than a bare "Failed to check in".
class CheckInException implements Exception {
  final String message;
  final double? distanceMeters;
  final List<String> fieldErrors;

  CheckInException({
    required this.message,
    this.distanceMeters,
    this.fieldErrors = const [],
  });

  /// Parses a check-in error response body. Never throws: a non-JSON or
  /// unexpected body falls back to a generic message.
  factory CheckInException.fromResponse(int status, String body) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      final distanceMeters = (decoded['distanceMeters'] as num?)?.toDouble();
      final fieldErrors = (decoded['errors'] as List?)
              ?.map((e) => (e as Map)['msg']?.toString())
              .whereType<String>()
              .toList() ??
          const <String>[];
      final message = decoded['message'] as String? ??
          (fieldErrors.isNotEmpty ? fieldErrors.first : 'Failed to check in');
      return CheckInException(
        message: message,
        distanceMeters: distanceMeters,
        fieldErrors: fieldErrors,
      );
    } catch (_) {
      return CheckInException(message: 'Failed to check in');
    }
  }

  @override
  String toString() => message;
}

class CheckInService {
  static const String baseUrl = 'http://localhost:3000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<CheckInModel> checkIn({
    required String clubId,
    required String qrPayload,
    required double latitude,
    required double longitude,
  }) async {
    final headers = await _authHeaders();
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/check-ins'),
        headers: headers,
        body: json.encode({
          'clubId': clubId,
          'qrPayload': qrPayload,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } catch (_) {
      throw CheckInException(message: 'Failed to connect to the server');
    }

    if (response.statusCode == 201) {
      return CheckInModel.fromMap(json.decode(response.body));
    }
    throw CheckInException.fromResponse(response.statusCode, response.body);
  }

  Future<List<CheckInModel>> getMyCheckIns() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/check-ins/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['checkIns'] as List)
            .map((checkIn) => CheckInModel.fromMap(checkIn))
            .toList();
      } else {
        throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to fetch check-ins',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  Future<CheckInStatsModel> getMyStats() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/check-ins/me/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return CheckInStatsModel.fromMap(json.decode(response.body));
      } else {
        throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to fetch stats',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
}
