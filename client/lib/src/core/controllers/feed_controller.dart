import 'package:get/get.dart';
import 'package:clubsy/data/classes/feed_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/feed_service.dart';

class FeedController extends GetxController {
  final FeedService _service;

  /// [service] is injectable so tests don't need real HTTP.
  FeedController({FeedService? service}) : _service = service ?? FeedService();

  final nights = <FeedNight>[].obs;
  final isLoading = false.obs;
  final hasMore = false.obs;
  final error = RxnString();
  int _page = 0;

  Future<void> load() async {
    _page = 0;
    nights.clear();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await _service.getFeed(page: _page + 1);
      _page++;
      nights.addAll(result.nights);
      hasMore.value = result.hasMore;
      error.value = null;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Count only; 0 on any failure so a club page never breaks on it.
  Future<int> friendCountForClub(String clubId) async {
    try {
      return await _service.friendCountForClub(clubId);
    } catch (_) {
      return 0;
    }
  }
}

String friendsHaveBeenHereText(int count) =>
    count == 1 ? '1 friend has been here' : '$count friends have been here';
