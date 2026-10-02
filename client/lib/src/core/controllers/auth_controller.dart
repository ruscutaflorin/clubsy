import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/services/local_cache.dart';

class AuthController extends GetxController {
  static const revalidateAfter = Duration(hours: 6);

  final _isAuthenticated = false.obs;
  final _user = Rxn<Map<String, dynamic>>();
  final AuthService _authService;
  AppLifecycleListener? _lifecycle;
  DateTime? _lastValidated;
  bool _expiring = false;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool get isAuthenticated => _isAuthenticated.value;
  RxBool get isAuthenticatedStream => _isAuthenticated;
  Map<String, dynamic>? get user => _user.value;
  bool get isAdmin => user?['role'] == 'ADMIN';

  @override
  void onInit() {
    super.onInit();
    ApiClient.globalOnUnauthorized = _onUnauthorized;
    _lifecycle = AppLifecycleListener(onResume: _revalidateIfStale);
    checkAuthStatus();
  }

  @override
  void onClose() {
    _lifecycle?.dispose();
    if (ApiClient.globalOnUnauthorized == _onUnauthorized) {
      ApiClient.globalOnUnauthorized = null;
    }
    super.onClose();
  }

  void _revalidateIfStale() {
    final last = _lastValidated;
    if (_isAuthenticated.value &&
        last != null &&
        DateTime.now().difference(last) > revalidateAfter) {
      checkAuthStatus();
    }
  }

  /// Called for every 401 on an authenticated request. Parallel 401s sign out
  /// once; the guard is reset by the next sign-in.
  Future<void> _onUnauthorized() async {
    if (_expiring || !_isAuthenticated.value) return;
    _expiring = true;
    await signOut();
    if (Get.key.currentState != null) {
      Get.offAllNamed('/login');
      Get.snackbar('Session expired', 'Session expired, please sign in again');
    }
  }

  Future<void> checkAuthStatus() async {
    debugPrint('AuthController: Checking auth status...');
    final isAuth = await _authService.isAuthenticated();
    debugPrint('AuthController: User is authenticated: $isAuth');
    _isAuthenticated.value = isAuth;
    if (isAuth) {
      _user.value = await _authService.getUser();
      debugPrint('AuthController: User data loaded: ${_user.value?['name']}');
      await _validateSession();
    }
  }

  Future<void> _validateSession() async {
    try {
      _user.value = await _authService.fetchMe();
      _lastValidated = DateTime.now();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        await _onUnauthorized();
      }
      // Network error, timeout or 5xx: stay signed in with the cached user.
    } catch (e) {
      debugPrint('AuthController: Session validation failed: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      debugPrint('AuthController: Signing in user...');
      final data = await _authService.signIn(email, password);
      _user.value = data['user'];
      _isAuthenticated.value = true;
      _expiring = false;
      _lastValidated = DateTime.now();
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
      _expiring = false;
      _lastValidated = DateTime.now();
      debugPrint(
        'AuthController: Sign up successful, user: ${data['user']['name']}',
      );
    } catch (e) {
      debugPrint('AuthController: Sign up failed: $e');
      rethrow;
    }
  }

  /// Deletes the account server-side, then clears the local session and cache.
  Future<void> deleteAccount(String password) async {
    await _authService.deleteAccount(password);
    await signOut();
  }

  Future<void> changePassword(String current, String next) =>
      _authService.changePassword(current, next);

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
