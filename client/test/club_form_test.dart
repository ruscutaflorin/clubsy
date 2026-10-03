import 'package:clubsy/data/classes/club_form_validation.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/src/core/controllers/admin_controller.dart';
import 'package:clubsy/views/pages/admin/admin_club_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class RejectingService extends AdminService {
  @override
  Future<({ClubModel club, String? qrCode})> createClub(
    Map<String, dynamic> fields,
  ) async => throw ApiException(
    400,
    'Valid latitude is required',
    fieldErrors: [
      'Valid latitude is required',
      'imageUrl must be an https URL',
      'Name is required',
      'Something odd',
    ],
  );
}

void main() {
  group('ClubFormValidation', () {
    test('required', () {
      expect(ClubFormValidation.required('', 'Name'), 'Name is required');
      expect(ClubFormValidation.required('  ', 'Name'), isNotNull);
      expect(ClubFormValidation.required('x', 'Name'), isNull);
    });

    test('latitude boundaries', () {
      expect(ClubFormValidation.latitude('90'), isNull);
      expect(ClubFormValidation.latitude('90.0'), isNull);
      expect(ClubFormValidation.latitude('-90'), isNull);
      expect(ClubFormValidation.latitude('90.0001'), isNotNull);
      expect(ClubFormValidation.latitude('-90.0001'), isNotNull);
      expect(ClubFormValidation.latitude(''), isNotNull);
      expect(ClubFormValidation.latitude('abc'), isNotNull);
      expect(ClubFormValidation.latitude('NaN'), isNotNull);
    });

    test('longitude boundaries', () {
      expect(ClubFormValidation.longitude('180'), isNull);
      expect(ClubFormValidation.longitude('-180'), isNull);
      expect(ClubFormValidation.longitude('180.0001'), isNotNull);
      expect(ClubFormValidation.longitude('-180.0001'), isNotNull);
      expect(ClubFormValidation.longitude(null), isNotNull);
    });

    test('imageUrl is optional but must be https', () {
      expect(ClubFormValidation.imageUrl(''), isNull);
      expect(ClubFormValidation.imageUrl(null), isNull);
      expect(ClubFormValidation.imageUrl('https://x.com/a.png'), isNull);
      expect(ClubFormValidation.imageUrl('http://x.com/a.png'), isNotNull);
      expect(ClubFormValidation.imageUrl('https://'), isNotNull);
      expect(ClubFormValidation.imageUrl('not a url'), isNotNull);
    });

    test('mapServerErrors matches messages to fields', () {
      final m = ClubFormValidation.mapServerErrors([
        'Valid longitude is required',
        'imageUrl must be an https URL',
        'City is required',
        'Something odd',
      ]);
      expect(m['longitude'], 'Valid longitude is required');
      expect(m['imageUrl'], 'imageUrl must be an https URL');
      expect(m['city'], 'City is required');
      expect(m['_form'], 'Something odd');
    });
  });

  test('saveClub lands server field errors on the right fields', () async {
    final c = AdminController(service: RejectingService());
    final saved = await c.saveClub({'name': ''});
    expect(saved, isNull);
    expect(c.fieldErrors['latitude'], 'Valid latitude is required');
    expect(c.fieldErrors['imageUrl'], 'imageUrl must be an https URL');
    expect(c.fieldErrors['name'], 'Name is required');
    expect(c.fieldErrors['_form'], 'Something odd');
    expect(c.isSaving.value, isFalse);
  });

  group('AdminClubFormPage', () {
    setUp(() {
      Get.testMode = true;
      Get.put(AdminController(service: RejectingService()));
    });
    tearDown(Get.reset);

    bool submitEnabled(WidgetTester tester) => tester
        .widget<FilledButton>(find.byKey(const Key('clubFormSubmit')))
        .enabled;

    Future<void> type(WidgetTester tester, String field, String v) async {
      await tester.enterText(find.byKey(Key('clubForm-$field')), v);
      await tester.pump();
    }

    testWidgets('submit is disabled until the form is valid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminClubFormPage(showMap: false)),
      );
      expect(submitEnabled(tester), isFalse);

      await type(tester, 'name', 'Club X');
      await type(tester, 'address', '1 Main St');
      await type(tester, 'city', 'Cluj');
      await type(tester, 'latitude', '91');
      await type(tester, 'longitude', '23.5');
      expect(submitEnabled(tester), isFalse);

      await type(tester, 'latitude', '46.77');
      expect(submitEnabled(tester), isTrue);

      await type(tester, 'imageUrl', 'http://x.com/a.png');
      expect(submitEnabled(tester), isFalse);
      await type(tester, 'imageUrl', 'https://x.com/a.png');
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('use my location fills latitude and longitude', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminClubFormPage(
            showMap: false,
            locate: () async => LatLng(46.5, 23.25),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('clubFormLocate')));
      await tester.pump();
      await tester.pump();
      expect(find.text('46.500000'), findsOneWidget);
      expect(find.text('23.250000'), findsOneWidget);
    });
  });
}
