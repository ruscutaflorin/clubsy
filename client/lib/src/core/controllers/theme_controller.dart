import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/data/constants.dart';

class ThemeController extends GetxController {
  final _isDarkMode = true.obs;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool(KConstants.themeModeKey) ?? true;
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KConstants.themeModeKey, _isDarkMode.value);
  }
}
