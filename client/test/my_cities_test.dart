import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:clubsy/data/classes/city_progress_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/my_cities_page.dart';

class _FakeClubController extends ClubController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

Future<void> pump(WidgetTester tester, List<CityProgressModel> cities) async {
  final controller = _FakeClubController();
  controller.cityProgress.value = cities;
  Get.put<ClubController>(controller);
  await tester.pumpWidget(const GetMaterialApp(home: MyCitiesPage()));
}

void main() {
  tearDown(Get.reset);

  test('CityProgressModel parses a fixture', () {
    final m = CityProgressModel.fromMap({
      'city': 'Cluj',
      'visitedClubs': 4,
      'totalClubs': 11,
      'lastVisitedAt': '2026-09-03T22:00:00.000Z',
    });
    expect(m.city, 'Cluj');
    expect(m.visitedClubs, 4);
    expect(m.totalClubs, 11);
    expect(m.lastVisitedAt, DateTime.utc(2026, 9, 3, 22));
    expect(m.fraction, closeTo(4 / 11, 1e-9));
  });

  testWidgets('shows "4 of 11 clubs" per city', (tester) async {
    await pump(tester, [
      CityProgressModel(city: 'Cluj', visitedClubs: 4, totalClubs: 11),
    ]);
    expect(find.text('Cluj'), findsOneWidget);
    expect(find.text('4 of 11 clubs'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    await pump(tester, []);
    expect(
      find.text('Check in somewhere to start your collection'),
      findsOneWidget,
    );
  });
}
