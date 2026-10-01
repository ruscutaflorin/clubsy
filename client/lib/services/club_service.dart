import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/auth_service.dart';

class ClubService {
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

  Future<List<ClubModel>> getClubs({String? search, String? city}) async {
    try {
      final headers = await _authHeaders();
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (city != null && city.isNotEmpty) 'city': city,
        'limit': '100',
      };

      final uri = Uri.parse('$baseUrl/clubs').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['clubs'] as List)
            .map((club) => ClubModel.fromMap(club))
            .toList();
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to fetch clubs');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  Future<ClubModel> getClubById(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/clubs/$id'), headers: headers);

      if (response.statusCode == 200) {
        return ClubModel.fromMap(json.decode(response.body));
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to fetch club');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
}
