import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/data/constants.dart';
import 'package:clubsy/src/core/controllers/navigation_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationController', () {
    test('starts on the first page and changes page', () {
      final controller = NavigationController();
      expect(controller.selectedPage, 0);
      controller.changePage(2);
      expect(controller.selectedPage, 2);
    });
  });

  group('ThemeController', () {
    test('defaults to dark mode when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isDarkMode, isTrue);
    });

    test('loads stored preference', () async {
      SharedPreferences.setMockInitialValues({KConstants.themeModeKey: false});
      final controller = ThemeController();
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isDarkMode, isFalse);
    });

    test('toggleTheme flips and persists the value', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      await controller.toggleTheme();
      expect(controller.isDarkMode, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(KConstants.themeModeKey), isFalse);
    });
  });
}
