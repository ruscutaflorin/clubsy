import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'http://localhost:3000/api'; // Update with your API URL
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  /// Reads the server's `{message}` error shape, or the first
  /// express-validator `{errors: [{msg}]}` entry when `message` is absent.
  static String _errorMessage(String body, String fallback) {
    final decoded = json.decode(body);
    if (decoded['message'] != null) return decoded['message'];
    final errors = decoded['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      return errors.first['msg'] ?? fallback;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveAuthData(data['token'], data['user']);
      return data;
    }
    throw Exception(_errorMessage(response.body, 'Failed to sign in'));
  }

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String name,
  ) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'name': name}),
      );
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await _saveAuthData(data['token'], data['user']);
      return data;
    }
    throw Exception(_errorMessage(response.body, 'Failed to sign up'));
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return token;
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);
    if (userStr != null) {
      return json.decode(userStr);
    }
    return null;
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, json.encode(user));
  }
}
