import 'dart:async';

import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_profile.dart';
import 'package:clubsy/services/club_service.dart';

typedef ClubFetch = Future<List<ClubModel>> Function({
  String? search,
  String? city,
});

class ClubSearchController extends GetxController {
  final ClubFetch _fetch;

  /// [fetch] is injectable so tests don't need real HTTP; defaults to
  /// [ClubService.getClubs] in the running app.
  ClubSearchController({ClubFetch? fetch, DateTime Function()? clock})
    : _fetch = fetch ?? ClubService().getClubs,
      _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final results = <ClubModel>[].obs;
  final isLoading = false.obs;
  final query = ''.obs;

  /// Narrows [results] to one music genre; null shows every genre.
  final genre = Rxn<String>();

  /// Keeps only clubs that are open right now.
  final openNow = false.obs;

  List<ClubModel> get filteredResults {
    final byGenre = clubsWithGenre(results, genre.value);
    return openNow.value ? clubsOpenAt(byGenre, _clock()) : byGenre;
  }

  void toggleOpenNow() => openNow.value = !openNow.value;

  void toggleGenre(String value) =>
      genre.value = genre.value == value ? null : value;

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
