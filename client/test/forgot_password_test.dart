import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/views/pages/forgot_password_page.dart';

class FakeAuthService extends AuthService {
  final requested = <String>[];
  final resets = <List<String>>[];
  Object? resetFailsWith;

  @override
  Future<void> requestPasswordReset(String email) async => requested.add(email);

  @override
  Future<void> resetPassword(String email, String code, String next) async {
    resets.add([email, code, next]);
    if (resetFailsWith != null) throw resetFailsWith!;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  Future<FakeAuthService> pumpPage(WidgetTester tester) async {
    final fake = FakeAuthService();
    await tester.pumpWidget(
      GetMaterialApp(home: ForgotPasswordPage(authService: fake)),
    );
    return fake;
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('resetSubmit')));
    await tester.pump();
  }

  Future<void> reachStepTwo(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'ana@example.com',
    );
    await tapSubmit(tester);
  }

  testWidgets('step one rejects a bad email, then reveals the code form', (
    tester,
  ) async {
    final fake = await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('resetEmailField')), 'nope');
    await tapSubmit(tester);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(fake.requested, isEmpty);

    await reachStepTwo(tester);
    expect(fake.requested, ['ana@example.com']);
    expect(find.byKey(const Key('resetCodeField')), findsOneWidget);
  });

  testWidgets('step two validates code and passwords before calling', (
    tester,
  ) async {
    final fake = await pumpPage(tester);
    await reachStepTwo(tester);

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123');
    await tapSubmit(tester);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    await tester.enterText(
      find.byKey(const Key('resetPasswordField')),
      'short',
    );
    await tapSubmit(tester);
    expect(
      find.text('New password must be at least 8 characters'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('resetPasswordField')),
      'long-enough-1',
    );
    await tester.enterText(
      find.byKey(const Key('resetConfirmField')),
      'long-enough-2',
    );
    await tapSubmit(tester);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(fake.resets, isEmpty);
  });

  testWidgets('shows the server message when the code is rejected', (
    tester,
  ) async {
    final fake = await pumpPage(tester);
    fake.resetFailsWith = ApiException(400, 'Invalid or expired code');
    await reachStepTwo(tester);
    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    await tester.enterText(
      find.byKey(const Key('resetPasswordField')),
      'long-enough-1',
    );
    await tester.enterText(
      find.byKey(const Key('resetConfirmField')),
      'long-enough-1',
    );
    await tapSubmit(tester);
    await tester.pump();
    expect(fake.resets.single, ['ana@example.com', '123456', 'long-enough-1']);
    expect(find.text('Invalid or expired code'), findsOneWidget);
  });
}
