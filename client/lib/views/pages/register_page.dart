import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/widget_tree.dart';
import 'package:clubsy/widgets/auth_widget.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final authController = Get.find<AuthController>();
    final isLoading = false.obs;
    final errorMessage = RxnString();

    Future<void> handleRegister() async {
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          nameController.text.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await authController.signUp(
          emailController.text,
          passwordController.text,
          nameController.text,
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
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A3A),
                  ),
                ),
                const SizedBox(height: 24),
                AuthWidget(
                  emailController: emailController,
                  passwordController: passwordController,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  onAuth: handleRegister,
                  buttonText: 'Sign Up',
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Get.toNamed('/login');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Sign In',
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
