import 'package:clubsy/data/classes/check_in_model.dart';

/// Local hour of day from which last night's venue can be rated.
const vibePromptHour = 6;

/// How long after a check-in the morning card is still offered.
const vibePromptWindow = Duration(hours: 36);

/// The check-in to ask "How was the club?" about, or null.
///
/// From 06:00 local on, the most recent unrated check-in made before today's
/// 06:00 and within [vibePromptWindow].
CheckInModel? pendingVibePrompt(
  List<CheckInModel> checkIns,
  DateTime now, {
  Set<String> dismissedIds = const {},
}) {
  if (now.hour < vibePromptHour) return null;
  final cutoff = DateTime(now.year, now.month, now.day, vibePromptHour);
  CheckInModel? best;
  for (final c in checkIns) {
    if (c.vibe != null || dismissedIds.contains(c.id)) continue;
    final at = c.checkedInAt.toLocal();
    if (!at.isBefore(cutoff)) continue;
    if (now.difference(at) > vibePromptWindow) continue;
    if (best == null || at.isAfter(best.checkedInAt.toLocal())) best = c;
  }
  return best;
}
