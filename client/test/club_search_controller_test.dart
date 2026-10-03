import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/club_search_controller.dart';

ClubModel fixtureClub(String id, String name) => ClubModel(
  id: id,
  name: name,
  address: '1 Main St',
  city: 'Cluj',
  latitude: 46,
  longitude: 23.5,
  imageUrl: 'http://img',
  isApproved: true,
);

void main() {
  group('ClubSearchController.runSearch', () {
    test('forwards the query to fetch and exposes the results', () async {
      String? capturedSearch;
      final controller = ClubSearchController(
        fetch: ({search, city}) async {
          capturedSearch = search;
          return [fixtureClub('a', 'Club Alpha')];
        },
      );

      await controller.runSearch('alpha');

      expect(capturedSearch, 'alpha');
      expect(controller.results.map((c) => c.name), ['Club Alpha']);
      expect(controller.isLoading.value, isFalse);
    });

    test('clears results for a blank query without calling fetch', () async {
      var called = false;
      final controller = ClubSearchController(
        fetch: ({search, city}) async {
          called = true;
          return [];
        },
      );
      controller.results.add(fixtureClub('a', 'Club Alpha'));

      await controller.runSearch('   ');

      expect(called, isFalse);
      expect(controller.results, isEmpty);
    });

    test('clears results and stops loading when fetch throws', () async {
      final controller = ClubSearchController(
        fetch: ({search, city}) async => throw Exception('network error'),
      );

      await controller.runSearch('alpha');

      expect(controller.results, isEmpty);
      expect(controller.isLoading.value, isFalse);
    });
  });
}
