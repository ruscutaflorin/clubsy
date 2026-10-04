import 'package:flutter/material.dart';
import 'package:clubsy/data/classes/check_in_outcome.dart';
import 'package:clubsy/data/classes/club_model.dart';

/// The headline of the success sheet.
String checkInHeadline(CheckInOutcome outcome, ClubModel club) =>
    outcome.isFirstVisit
    ? 'New place on your map!'
    : 'Visit #${outcome.visitNumber} at ${club.name}';

/// The line under the headline; null for a repeat visit.
String? checkInDetail(CheckInOutcome outcome) {
  if (!outcome.isFirstVisit) return null;
  final n = outcome.totalClubsVisited;
  final clubs = "That's $n ${n == 1 ? 'club' : 'clubs'}";
  if (outcome.isNewCity && outcome.city != null) {
    return '$clubs and your first in ${outcome.city}!';
  }
  return '$clubs.';
}

/// Shows the sheet; completes with true when the user chose "View on map".
Future<bool> showCheckInSuccessSheet(
  BuildContext context, {
  required CheckInOutcome outcome,
  required ClubModel club,
  List<Widget> extras = const [],
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    builder: (_) =>
        CheckInSuccessSheet(outcome: outcome, club: club, extras: extras),
  );
  return result ?? false;
}

class CheckInSuccessSheet extends StatelessWidget {
  final CheckInOutcome outcome;
  final ClubModel club;

  /// Slot for extra content, e.g. unlocked badges.
  final List<Widget> extras;

  const CheckInSuccessSheet({
    super.key,
    required this.outcome,
    required this.club,
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    final detail = checkInDetail(outcome);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Column(
                children: [
                  Icon(
                    outcome.isFirstVisit
                        ? Icons.location_on
                        : Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    checkInHeadline(outcome, club),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
            ],
            ...extras,
            const SizedBox(height: 12),
            const Text(
              'Rate tonight later - we\'ll ask tomorrow morning.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('View on map'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
