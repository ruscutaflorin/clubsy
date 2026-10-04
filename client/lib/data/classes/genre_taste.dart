import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';

/// Distinct nights per genre across [checkIns], most nights first then by name.
/// Clubs without genres add nothing.
List<({String genre, int nights})> genreNights(List<CheckInModel> checkIns) {
  final nightsByGenre = <String, Set<DateTime>>{};
  for (final c in checkIns) {
    final night = nightOf(c.checkedInAt.toLocal());
    for (final g in c.club.genres) {
      nightsByGenre.putIfAbsent(g, () => {}).add(night);
    }
  }
  final result = [
    for (final e in nightsByGenre.entries)
      (genre: e.key, nights: e.value.length),
  ];
  result.sort((a, b) {
    final byNights = b.nights.compareTo(a.nights);
    return byNights != 0 ? byNights : a.genre.compareTo(b.genre);
  });
  return result;
}

/// "Your sound: techno · house · latin" (top 3), or null when empty.
String? yourSoundText(List<({String genre, int nights})> g) {
  if (g.isEmpty) return null;
  return 'Your sound: ${g.take(3).map((e) => e.genre).join(' · ')}';
}
