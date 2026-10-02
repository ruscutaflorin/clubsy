import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/api_client.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  final ApiClient _api;

  AuthService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: _readToken);

  static Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final data = await _api.post(
      '/auth/signin',
      body: {'email': email, 'password': password},
      authenticated: false,
    ) as Map<String, dynamic>;
    await _saveAuthData(data['token'], data['user']);
    return data;
  }

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String name,
  ) async {
    final data = await _api.post(
      '/auth/signup',
      body: {'email': email, 'password': password, 'name': name},
      authenticated: false,
    ) as Map<String, dynamic>;
    await _saveAuthData(data['token'], data['user']);
    return data;
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
