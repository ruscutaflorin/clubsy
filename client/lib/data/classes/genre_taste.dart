import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

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

/// Genres in [clubGenres] (in order, no duplicates) that no previous check-in's
/// club has. Compared trimmed and case-insensitively; keeps [clubGenres]' spelling.
List<String> newGenres(
  List<String> clubGenres,
  List<CheckInModel> previousCheckIns,
) {
  String norm(String g) => g.trim().toLowerCase();
  final seen = <String>{
    for (final c in previousCheckIns) ...c.club.genres.map(norm),
  };
  final result = <String>[];
  for (final g in clubGenres) {
    if (seen.add(norm(g))) result.add(g);
  }
  return result;
}

/// "Your first techno, house and latin night!" (first 3), or null when empty.
String? newGenreText(List<String> genres) {
  if (genres.isEmpty) return null;
  final g = genres.take(3).toList();
  final names = g.length == 1
      ? g.first
      : '${g.sublist(0, g.length - 1).join(', ')} and ${g.last}';
  return 'Your first $names night!';
}

/// "Your sound: techno · house · latin" (top 3), or null when empty.
String? yourSoundText(List<({String genre, int nights})> g) {
  if (g.isEmpty) return null;
  return 'Your sound: ${g.take(3).map((e) => e.genre).join(' · ')}';
}

/// Approved clubs in the same city sharing a genre with [club], most shared
/// genres first then by name. Matching ignores case and surrounding spaces.
List<({ClubModel club, List<String> shared})> similarClubs(
  ClubModel club,
  List<ClubModel> clubs, {
  int limit = 3,
}) {
  String norm(String s) => s.trim().toLowerCase();
  final city = norm(club.city);
  final result = <({ClubModel club, List<String> shared})>[];
  for (final other in clubs) {
    if (!other.isApproved || other.id == club.id) continue;
    if (norm(other.city) != city) continue;
    final otherGenres = other.genres.map(norm).toSet();
    final shared = [
      for (final g in club.genres)
        if (otherGenres.contains(norm(g))) g.trim(),
    ];
    if (shared.isNotEmpty) result.add((club: other, shared: shared));
  }
  result.sort((a, b) {
    final byShared = b.shared.length.compareTo(a.shared.length);
    return byShared != 0
        ? byShared
        : a.club.name.toLowerCase().compareTo(b.club.name.toLowerCase());
  });
  return result.take(limit).toList();
}
