import 'dart:async';

import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/club_service.dart';

typedef ClubFetch = Future<List<ClubModel>> Function({
  String? search,
  String? city,
});

class ClubSearchController extends GetxController {
  final ClubFetch _fetch;

  /// [fetch] is injectable so tests don't need real HTTP; defaults to
  /// [ClubService.getClubs] in the running app.
  ClubSearchController({ClubFetch? fetch})
    : _fetch = fetch ?? ClubService().getClubs;

  final results = <ClubModel>[].obs;
  final isLoading = false.obs;
  final query = ''.obs;

  Timer? _debounce;

  /// Debounced entry point for the search field's onChanged.
  void search(String text) {
    query.value = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => runSearch(text));
  }

  /// Runs the search immediately - the piece under test, separate from the
  /// debounce timer so it can be awaited directly without faking time.
  Future<void> runSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      results.clear();
      return;
    }

    isLoading.value = true;
    try {
      results.value = await _fetch(search: trimmed);
    } catch (_) {
      results.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
