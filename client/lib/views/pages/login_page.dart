import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/widget_tree.dart';
import 'package:clubsy/widgets/auth_widget.dart';

import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authController = Get.find<AuthController>();
    final isLoading = false.obs;
    final errorMessage = RxnString();

    Future<void> handleLogin() async {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await authController.signIn(
          emailController.text,
          passwordController.text,
        );
        Get.offAll(() => const WidgetTree());
      } catch (e) {
        errorMessage.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161630),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AuthWidget(
                  emailController: emailController,
                  passwordController: passwordController,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  onAuth: handleLogin,
                  buttonText: 'Sign In',
                ),
                TextButton(
                  key: const Key('forgotPasswordLink'),
                  onPressed: () => Get.to(() => const ForgotPasswordPage()),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Get.to(() => const RegisterPage());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.yellow[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
