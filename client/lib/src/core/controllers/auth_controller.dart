import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/services/local_cache.dart';

class AuthController extends GetxController {
  final _isAuthenticated = false.obs;
  final _user = Rxn<Map<String, dynamic>>();
  final _authService = AuthService();

  bool get isAuthenticated => _isAuthenticated.value;
  RxBool get isAuthenticatedStream => _isAuthenticated;
  Map<String, dynamic>? get user => _user.value;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('AuthController: Checking auth status...');
    final isAuth = await _authService.isAuthenticated();
    debugPrint('AuthController: User is authenticated: $isAuth');
    _isAuthenticated.value = isAuth;
    if (isAuth) {
      _user.value = await _authService.getUser();
      debugPrint('AuthController: User data loaded: ${_user.value?['name']}');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      debugPrint('AuthController: Signing in user...');
      final data = await _authService.signIn(email, password);
      _user.value = data['user'];
      _isAuthenticated.value = true;
      debugPrint(
        'AuthController: Sign in successful, user: ${data['user']['name']}',
      );
    } catch (e) {
      debugPrint('AuthController: Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      debugPrint('AuthController: Signing up user...');
      final data = await _authService.signUp(email, password, name);
      _user.value = data['user'];
      _isAuthenticated.value = true;
      debugPrint(
        'AuthController: Sign up successful, user: ${data['user']['name']}',
      );
    } catch (e) {
      debugPrint('AuthController: Sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('AuthController: Signing out user...');
    await _authService.signOut();
    // Another user must never see the previous user's map.
    await LocalCache().clear();
    _isAuthenticated.value = false;
    _user.value = null;
    debugPrint('AuthController: Sign out complete, auth state cleared');
  }
}
