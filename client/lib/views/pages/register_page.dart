import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/pages/legal_page.dart';
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
    final isAdult = false.obs;
    final acceptedTerms = false.obs;
    final canRegister = false.obs;
    void updateCanRegister() =>
        canRegister.value = isAdult.value && acceptedTerms.value;

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
                Obx(
                  () => CheckboxListTile(
                    key: const Key('ageCheckbox'),
                    value: isAdult.value,
                    onChanged: (v) {
                      isAdult.value = v ?? false;
                      updateCanRegister();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "I'm 18 or older",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Obx(
                  () => CheckboxListTile(
                    key: const Key('termsCheckbox'),
                    value: acceptedTerms.value,
                    onChanged: (v) {
                      acceptedTerms.value = v ?? false;
                      updateCanRegister();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I accept the Terms and Privacy Policy',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      key: const Key('termsLink'),
                      onPressed: () => Get.to(() => const LegalPage.terms()),
                      child: const Text('Terms'),
                    ),
                    TextButton(
                      key: const Key('privacyLink'),
                      onPressed: () => Get.to(() => const LegalPage.privacy()),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AuthWidget(
                  emailController: emailController,
                  passwordController: passwordController,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  onAuth: handleRegister,
                  buttonText: 'Sign Up',
                  enabled: canRegister,
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
