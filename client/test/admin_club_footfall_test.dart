import 'package:clubsy/data/classes/club_footfall_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/views/pages/admin/admin_club_footfall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final club = ClubModel(
    id: 'c1',
    name: 'Alpha',
    address: 'a',
    city: 'Cluj',
    latitude: 1,
    longitude: 1,
    imageUrl: 'https://x/y.png',
    isApproved: true,
  );
  final fixture = ClubFootfallModel.fromMap({
    'totalCheckIns': 41,
    'uniqueVisitors': 27,
    'returningVisitorRate': 0.25,
    'firstTimeShare': 0.75,
    'weekly': [
      {'weekStart': '2026-09-28', 'checkIns': 5, 'uniqueVisitors': 4},
      {'weekStart': '2026-10-05', 'checkIns': 0, 'uniqueVisitors': 0},
    ],
    'byWeekday': [0, 0, 0, 0, 0, 3, 2],
  });

  testWidgets('shows the unique visitor count from a fixture', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminClubFootfallPage(club: club, footfall: fixture),
      ),
    );
    expect(find.text('27'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('copy summary puts the text on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminClubFootfallPage(club: club, footfall: fixture),
      ),
    );
    await tester.tap(find.byKey(const Key('copyFootfallSummary')));
    await tester.pump();
    expect(find.text('Summary copied'), findsOneWidget);
    expect(copied, contains('Unique visitors'));
  });

  // A full distance block is parsed and rendered in the marginal-warning test below.
  test('distance defaults to null, and to null figures when insufficient', () {
    expect(fixture.distance, isNull);
    final empty = DistanceHealth.fromMap({
      'count': 0,
      'status': 'insufficient',
    });
    expect(empty.medianMeters, isNull);
  });

  testWidgets('shows distance health with marginal warning', (tester) async {
    final data = ClubFootfallModel.fromMap({
      'weekly': [],
      'distance': {
        'count': 10,
        'medianMeters': 42,
        'p90Meters': 118,
        'nearLimitShare': 0.3,
        'status': 'marginal',
      },
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminClubFootfallPage(club: club, footfall: data),
      ),
    );
    expect(find.textContaining('Median 42 m'), findsOneWidget);
    expect(
      find.textContaining('close to the 150 m limit: check'),
      findsOneWidget,
    );
  });
}
