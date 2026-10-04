import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
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

CheckInModel _visit(List<String> genres) => CheckInModel(
  id: 'c1',
  clubId: 'a',
  checkedInAt: DateTime(2026, 9, 5, 23),
  verificationMethod: 'QR',
  distanceMeters: 10,
  club: ClubModel(
    id: 'a',
    name: 'A',
    address: '1 Main St',
    city: 'Cluj',
    latitude: 46,
    longitude: 23.5,
    imageUrl: 'http://img',
    isApproved: true,
    genres: genres,
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  for (final (genres, expected) in [
    (['techno'], 'Your sound: techno'),
    (<String>[], null),
  ]) {
    testWidgets('profile your sound for genres $genres', (tester) async {
      Get.put(AuthController(authService: FakeAuthService()));
      Get.put(ThemeController());
      final clubs = Get.put(ClubController());
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pump();
      clubs.myCheckIns.assignAll([_visit(genres)]);
      await tester.pump();
      if (expected == null) {
        expect(find.byKey(const Key('yourSoundText')), findsNothing);
      } else {
        expect(
          tester.widget<Text>(find.byKey(const Key('yourSoundText'))).data,
          expected,
        );
      }
    });
  }

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
