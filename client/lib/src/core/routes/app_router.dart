import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/pages/welcome_page.dart';
import 'package:clubsy/views/pages/login_page.dart';
import 'package:clubsy/views/pages/register_page.dart';
import 'package:clubsy/views/widget_tree.dart';

class AppRouter {
  static final List<GetPage> routes = [
    GetPage(
      name: '/',
      page: () => const WelcomePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/login',
      page: () => const LoginPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/register',
      page: () => const RegisterPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/home',
      page: () => const WidgetTree(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    final isAuth = authController.isAuthenticated;
    final isAuthRoute =
        route == '/login' || route == '/register' || route == '/';

    if (!isAuth && !isAuthRoute) {
      return const RouteSettings(name: '/');
    }

    if (isAuth && isAuthRoute) {
      return const RouteSettings(name: '/home');
    }

    return null;
  }
}
