import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FittedBox(
                  child: Text(
                    'Clubsy',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Lottie.asset('assets/lotties/cool.json', height: 200),
                ),
                FilledButton(
                  onPressed: () => Get.toNamed('/register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple[200],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 40.0),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Get.toNamed('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.yellow[500],
                    minimumSize: const Size(double.infinity, 40.0),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: Colors.black),
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
