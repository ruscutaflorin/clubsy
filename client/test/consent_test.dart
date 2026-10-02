import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/views/pages/check_in_primer_page.dart';
import 'package:clubsy/views/pages/legal_page.dart';
import 'package:clubsy/views/pages/register_page.dart';

final _club = ClubModel(
  id: 'a',
  name: 'Club A',
  address: 'x',
  city: 'y',
  latitude: 0,
  longitude: 0,
  imageUrl: '',
  isApproved: true,
);

Widget _scanner(ClubModel c) =>
    const Scaffold(body: Text('SCANNER', key: Key('scanner')));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  ElevatedButton signUp(WidgetTester t) =>
      t.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('Register is disabled until both boxes are checked', (t) async {
    Get.put(AuthController());
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(const GetMaterialApp(home: RegisterPage()));
    expect(signUp(t).onPressed, isNull);

    await t.tap(find.byKey(const Key('ageCheckbox')));
    await t.pump();
    expect(signUp(t).onPressed, isNull);

    await t.tap(find.byKey(const Key('termsCheckbox')));
    await t.pump();
    expect(signUp(t).onPressed, isNotNull);

    await t.tap(find.byKey(const Key('ageCheckbox')));
    await t.pump();
    expect(signUp(t).onPressed, isNull);
  });

  testWidgets('Terms link pushes LegalPage', (t) async {
    Get.put(AuthController());
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(const GetMaterialApp(home: RegisterPage()));
    await t.tap(find.byKey(const Key('termsLink')));
    await t.pumpAndSettle();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.textContaining('DRAFT'), findsWidgets);
  });

  testWidgets('primer shows on first check-in only', (t) async {
    await t.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openCheckIn(_club, checkInBuilder: _scanner),
            child: const Text('go'),
          ),
        ),
      ),
    );

    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byType(CheckInPrimerPage), findsOneWidget);
    await t.tap(find.byKey(const Key('primerContinue')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('scanner')), findsOneWidget);

    Get.back();
    await t.pumpAndSettle();
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byType(CheckInPrimerPage), findsNothing);
    expect(find.byKey(const Key('scanner')), findsOneWidget);
  });
}
