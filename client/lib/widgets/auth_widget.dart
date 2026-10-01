import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final RxBool isLoading;
  final RxnString errorMessage;
  final Future<void> Function() onAuth;
  final String buttonText;

  const AuthWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onAuth,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email',
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
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
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
        const SizedBox(height: 16),
        Obx(() {
          if (errorMessage.value != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                errorMessage.value!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() => ElevatedButton(
              onPressed: isLoading.value ? null : onAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(buttonText),
            )),
      ],
    );
  }
}
