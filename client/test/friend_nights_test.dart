import 'package:clubsy/data/classes/feed_model.dart';
import 'package:clubsy/services/feed_service.dart';
import 'package:clubsy/views/pages/friend_nights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedService extends FeedService {
  final FeedPage fixture;
  _FakeFeedService(this.fixture);

  @override
  Future<FeedPage> getFriendNights(String userId, {int page = 1}) async =>
      fixture;
}

Future<void> _pump(WidgetTester tester, FeedPage fixture) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FriendNightsPage(
        userId: 'u2',
        label: '@ana',
        service: _FakeFeedService(fixture),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows shared club count and the friend nights', (tester) async {
    await _pump(
      tester,
      const FeedPage(
        sharedClubCount: 3,
        nights: [
          FeedNight(
            id: 'c1',
            nightDate: '2026-09-12',
            clubId: 'k1',
            clubName: 'Club X',
            city: 'Cluj',
            friendLabel: '',
          ),
        ],
      ),
    );
    expect(find.text("You've both been to 3 clubs"), findsOneWidget);
    expect(find.textContaining('Club X'), findsOneWidget);
  });

  testWidgets('empty fixture shows the empty state and no header', (
    tester,
  ) async {
    await _pump(tester, const FeedPage());
    expect(find.textContaining('No shared nights yet'), findsOneWidget);
    expect(find.byKey(const Key('sharedClubCount')), findsNothing);
  });
}
