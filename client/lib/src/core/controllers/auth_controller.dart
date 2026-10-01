import 'package:get/get.dart';
import 'package:clubsy/services/auth_service.dart';

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
    print('AuthController: Checking auth status...');
    final isAuth = await _authService.isAuthenticated();
    print('AuthController: User is authenticated: $isAuth');
    _isAuthenticated.value = isAuth;
    if (isAuth) {
      _user.value = await _authService.getUser();
      print('AuthController: User data loaded: ${_user.value?['name']}');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      print('AuthController: Signing in user...');
      final data = await _authService.signIn(email, password);
      _user.value = data['user'];
      _isAuthenticated.value = true;
      print(
          'AuthController: Sign in successful, user: ${data['user']['name']}');
    } catch (e) {
      print('AuthController: Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      print('AuthController: Signing up user...');
      final data = await _authService.signUp(email, password, name);
      _user.value = data['user'];
      _isAuthenticated.value = true;
      print(
          'AuthController: Sign up successful, user: ${data['user']['name']}');
    } catch (e) {
      print('AuthController: Sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    print('AuthController: Signing out user...');
    await _authService.signOut();
    _isAuthenticated.value = false;
    _user.value = null;
    print('AuthController: Sign out complete, auth state cleared');
  }
}
