import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/pages/change_password_page.dart';

class FakeAuthService extends AuthService {
  final calls = <List<String>>[];
  Object? failWith;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<void> changePassword(String current, String next) async {
    calls.add([current, next]);
    if (failWith != null) throw failWith!;
  }
}

Future<FakeAuthService> pumpPage(WidgetTester tester) async {
  final fake = FakeAuthService();
  Get.put(AuthController(authService: fake));
  await tester.pumpWidget(const MaterialApp(home: ChangePasswordPage()));
  await tester.pump();
  return fake;
}

Future<void> fill(
  WidgetTester tester,
  String cur,
  String next,
  String conf,
) async {
  await tester.enterText(find.byKey(const Key('currentPasswordField')), cur);
  await tester.enterText(find.byKey(const Key('newPasswordField')), next);
  await tester.enterText(find.byKey(const Key('confirmPasswordField')), conf);
  await tester.tap(find.byKey(const Key('changePasswordSubmit')));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('mismatched confirm shows an error and skips the controller', (
    tester,
  ) async {
    final fake = await pumpPage(tester);
    await fill(tester, 'old-password', 'new-password-1', 'new-password-2');
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(fake.calls, isEmpty);
  });

  testWidgets('a short new password is rejected client-side', (tester) async {
    final fake = await pumpPage(tester);
    await fill(tester, 'old-password', 'short', 'short');
    expect(find.byKey(const Key('changePasswordError')), findsOneWidget);
    expect(fake.calls, isEmpty);
  });

  testWidgets('a 401 shows "Wrong password"', (tester) async {
    final fake = await pumpPage(tester);
    fake.failWith = ApiException(401, 'Invalid password');
    await fill(tester, 'old-password', 'new-password-1', 'new-password-1');
    await tester.pump();
    expect(fake.calls, [
      ['old-password', 'new-password-1'],
    ]);
    expect(find.text('Wrong password'), findsOneWidget);
  });
}
