import 'package:clubsy/data/classes/club_footfall_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/views/pages/admin/admin_club_footfall_page.dart';
import 'package:flutter/material.dart';
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
}
