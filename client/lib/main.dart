import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/routes/app_router.dart';
import 'package:clubsy/src/core/theme/app_theme.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/src/core/controllers/navigation_controller.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ThemeController());
  Get.put(NavigationController());
  Get.put(AuthController());
  Get.put(ClubController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'Clubsy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          getPages: AppRouter.routes,
        ));
  }
}
