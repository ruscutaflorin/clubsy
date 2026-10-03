import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/views/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  final names = <String>[];
  Map<String, dynamic> _user = {'name': 'Old', 'email': 'e', 'role': 'USER'};

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<Map<String, dynamic>> fetchMe() async => _user;

  @override
  Future<Map<String, dynamic>> updateName(String name) async {
    names.add(name);
    _user = {..._user, 'name': name};
    return _user;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('edit name validates, saves and updates the header', (
    tester,
  ) async {
    final fake = FakeAuthService();
    Get.put(AuthController(authService: fake));
    Get.put(ThemeController());
    Get.put(ClubController());
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('editName')));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsWidgets);

    await tester.enterText(find.byKey(const Key('nameField')), '   ');
    await tester.tap(find.byKey(const Key('nameSave')));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(fake.names, isEmpty);

    await tester.enterText(find.byKey(const Key('nameField')), 'Ana');
    await tester.tap(find.byKey(const Key('nameSave')));
    await tester.pumpAndSettle();
    expect(fake.names, ['Ana']);
    expect(find.text('Name updated'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });
}
