import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/services/auth_service.dart';

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
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/check-ins'),
        headers: headers,
        body: json.encode({
          'clubId': clubId,
          'qrPayload': qrPayload,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 201) {
        return CheckInModel.fromMap(json.decode(response.body));
      } else {
        throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to check in',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
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
}
