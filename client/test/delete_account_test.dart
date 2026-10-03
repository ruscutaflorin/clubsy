import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/views/pages/profile_page.dart';

class FakeAuthService extends AuthService {
  String? deletedWith;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<void> deleteAccount(String password) async => deletedWith = password;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('Delete account tile opens a confirm dialog', (tester) async {
    final fake = FakeAuthService();
    Get.put(AuthController(authService: fake));
    Get.put(ThemeController());
    Get.put(ClubController());
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('deleteAccountTile')));
    await tester.tap(find.byKey(const Key('deleteAccountTile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deleteAccountPassword')), findsOneWidget);
    TextButton confirm() => tester.widget<TextButton>(
      find.byKey(const Key('deleteAccountConfirm')),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('deleteAccountPassword')),
      'secret',
    );
    await tester.pump();
    expect(confirm().onPressed, isNotNull);
  });
}
