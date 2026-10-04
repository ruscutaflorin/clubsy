import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/widgets/privacy_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile_test.dart' show FakeAuthService;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('sharing is off by default and the switch turns it on', (
    tester,
  ) async {
    final auth = Get.put(AuthController(authService: FakeAuthService()));
    await auth.checkAuthStatus();
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: PrivacySection())),
    );

    final finder = find.byKey(const Key('shareNightsSwitch'));
    expect(tester.widget<SwitchListTile>(finder).value, isFalse);

    await tester.tap(finder);
    await tester.pump();
    expect(auth.user?['shareNightsWithFriends'], isTrue);
    expect(tester.widget<SwitchListTile>(finder).value, isTrue);
  });
}
