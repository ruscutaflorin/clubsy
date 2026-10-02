import 'package:clubsy/data/classes/club_ranking_model.dart';
import 'package:clubsy/data/classes/pilot_metrics_model.dart';
import 'package:clubsy/views/pages/admin/admin_metrics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = PilotMetricsModel.fromMap({
    'days': 7,
    'signups': 4,
    'activeCheckInUsers': 12,
    'checkIns': 34,
    'nightsOut': 20,
    'activationRate': 0.5,
    'returningUsers': 5,
    'topClubs': [
      {'id': 'c1', 'name': 'Alpha', 'count': 9, 'uniqueVisitors': 6},
    ],
    'daily': [
      {'date': '2026-10-01', 'checkIns': 3, 'activeUsers': 2},
      {'date': '2026-10-02', 'checkIns': 0, 'activeUsers': 0},
    ],
  });

  testWidgets('renders KPI tiles from a model', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MetricsKpiTiles(metrics: fixture),
              DailyBars(daily: fixture.daily),
            ],
          ),
        ),
      ),
    );
    expect(find.text('WACU'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('ClubRankingSection shows rows and the empty state', (
    tester,
  ) async {
    final ranking = ClubRankingModel.fromJson({
      'weeks': 4,
      'clubs': [
        {
          'id': 'c1',
          'name': 'Club A',
          'city': 'Cluj-Napoca',
          'checkIns': 84,
          'uniqueVisitors': 51,
          'previousCheckIns': 72,
          'change': 12,
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ClubRankingSection(ranking: ranking)),
      ),
    );
    expect(find.text('Club ranking'), findsOneWidget);
    expect(find.text('1. Club A · Cluj-Napoca'), findsOneWidget);
    expect(find.text('84 check-ins · 51 visitors'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);

    final empty = ClubRankingModel.fromJson({
      'weeks': 4,
      'clubs': [
        {
          'id': 'c1',
          'name': 'Club A',
          'city': 'Cluj-Napoca',
          'checkIns': 0,
          'uniqueVisitors': 0,
          'previousCheckIns': 0,
          'change': 0,
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ClubRankingSection(ranking: empty)),
      ),
    );
    expect(find.text('No check-ins in the last 4 weeks'), findsOneWidget);
  });
}
