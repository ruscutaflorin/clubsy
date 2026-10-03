import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clubsy/main.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';

void main() {
  testWidgets('MyApp builds a GetMaterialApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.put(ThemeController());
    Get.put(AuthController());

    await tester.pumpWidget(const MyApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    Get.reset();
  });
}
