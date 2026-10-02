import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/services/data_export_service.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/views/pages/profile_page.dart';

class FakeExportService extends DataExportService {
  int calls = 0;

  @override
  Future<void> exportMyData() async => calls++;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('Download my data tile triggers the export', (tester) async {
    final fake = FakeExportService();
    Get.put<DataExportService>(fake);
    Get.put(AuthController());
    Get.put(ThemeController());
    Get.put(ClubController());
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('exportTile')));
    await tester.tap(find.byKey(const Key('exportTile')));
    await tester.pump();

    expect(fake.calls, 1);
  });
}
