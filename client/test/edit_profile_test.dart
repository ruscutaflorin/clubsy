import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/pages/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  final checked = <String>[];
  final saved = <Map<String, String?>>[];
  final taken = {'taken_one'};
  Map<String, dynamic> _user = {
    'name': 'Old',
    'email': 'e',
    'role': 'USER',
    'username': 'old_me',
  };

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<Map<String, dynamic>> fetchMe() async => _user;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    checked.add(username);
    return !taken.contains(username);
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? username,
    String? homeCity,
  }) async {
    saved.add({'name': name, 'username': username, 'homeCity': homeCity});
    _user = {
      ..._user,
      'name': ?name,
      'username': ?username,
      'homeCity': ?homeCity,
    };
    return _user;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('edit profile validates, checks availability and saves', (
    tester,
  ) async {
    final fake = FakeAuthService();
    final auth = Get.put(AuthController(authService: fake));
    await tester.pumpWidget(const GetMaterialApp(home: EditProfilePage()));
    await tester.pump();
    await auth.checkAuthStatus();
    await tester.pumpAndSettle();

    Future<void> save() async {
      await tester.tap(find.byKey(const Key('profileSave')));
      await tester.pump();
    }

    // Invalid input blocks the save and never reaches the server.
    await tester.enterText(find.byKey(const Key('profileName')), '  ');
    await tester.enterText(find.byKey(const Key('profileUsername')), 'a b');
    await save();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Use 3-20 characters: letters, digits or _'), findsOne);
    expect(fake.saved, isEmpty);
    expect(fake.checked, isEmpty);

    // The check is debounced: typing quickly asks the server once, lowercased.
    await tester.enterText(find.byKey(const Key('profileUsername')), 'Tak');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(
      find.byKey(const Key('profileUsername')),
      'Taken_One',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(fake.checked, ['taken_one']);
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    await tester.enterText(find.byKey(const Key('profileName')), 'Ana');
    await tester.enterText(find.byKey(const Key('profileUsername')), 'Ana_01');
    await tester.enterText(find.byKey(const Key('profileCity')), ' Cluj ');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await save();
    await tester.pump();
    expect(fake.saved, [
      {'name': 'Ana', 'username': 'ana_01', 'homeCity': 'Cluj'},
    ]);
    expect(auth.user?['username'], 'ana_01');
    // Let the success snackbar's timers expire.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
