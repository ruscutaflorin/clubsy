/// Client-side mirror of the server's profile rules (`authRoutes.js`).
final _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

/// Usernames are stored lowercase, so input is normalised before checking.
String normalizeUsername(String input) => input.trim().toLowerCase();

/// Null when [input] is acceptable (an empty username means "none").
String? validateUsername(String input) {
  final u = normalizeUsername(input);
  if (u.isEmpty) return null;
  if (!_usernamePattern.hasMatch(u)) {
    return 'Use 3-20 characters: letters, digits or _';
  }
  return null;
}

String? validateDisplayName(String input) {
  final n = input.trim();
  if (n.isEmpty) return 'Name is required';
  if (n.length > 50) return 'Name must be at most 50 characters';
  return null;
}

String? validateHomeCity(String input) =>
    input.trim().length > 80 ? 'City must be at most 80 characters' : null;
