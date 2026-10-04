import 'package:clubsy/data/classes/feed_model.dart';
import 'package:clubsy/services/feed_service.dart';
import 'package:clubsy/src/core/controllers/feed_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService extends FeedService {
  final pages = <int>[];

  @override
  Future<FeedPage> getFeed({int page = 1}) async {
    pages.add(page);
    return FeedPage.fromMap({
      'hasMore': page == 1,
      'nights': [
        {
          'id': 'c$page',
          'nightDate': '2026-10-0$page',
          'club': {'id': 'k', 'name': 'Club $page', 'city': 'X'},
          'user': {'id': 'u', 'username': 'bob', 'name': 'Bob'},
        },
      ],
    });
  }

  @override
  Future<int> friendCountForClub(String clubId) async => throw Exception('x');
}

void main() {
  test('load then loadMore appends the next page', () async {
    final service = _FakeService();
    final c = FeedController(service: service);
    await c.load();
    expect(c.hasMore.value, isTrue);
    await c.loadMore();
    expect(service.pages, [1, 2]);
    expect(c.nights.map((n) => n.clubName), ['Club 1', 'Club 2']);
    expect(c.nights.first.friendLabel, '@bob');
    expect(c.hasMore.value, isFalse);
  });

  test('friend count falls back to 0 on failure; text pluralises', () async {
    final c = FeedController(service: _FakeService());
    expect(await c.friendCountForClub('k'), 0);
    expect(friendsHaveBeenHereText(1), '1 friend has been here');
    expect(friendsHaveBeenHereText(3), '3 friends have been here');
  });
}
