/// Pure validators for the admin club form, mirroring the rules in
/// `server/src/routes/clubRoutes.js`. Each returns an error message or null.
class ClubFormValidation {
  static const fields = [
    'name',
    'address',
    'city',
    'latitude',
    'longitude',
    'imageUrl',
  ];

  /// Optional profile fields, kept apart from [fields] (which are the form's
  /// required text controllers).
  static const profileFields = [
    'description',
    'genres',
    'openingHours',
    'instagramUrl',
    'websiteUrl',
  ];

  static String? required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  static String? latitude(String? value) => _range(value, 'Latitude', 90);

  static String? longitude(String? value) => _range(value, 'Longitude', 180);

  /// Optional, but when present it must be an https URL with a host.
  static String? imageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Image URL must be an https URL';
    }
    return null;
  }

  /// Optional https link (Instagram, website).
  static String? httpsUrl(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return '$label must be an https URL';
    }
    return null;
  }

  static String? description(String? value) => (value?.trim().length ?? 0) > 500
      ? 'Description must be at most 500 characters'
      : null;

  static String? _range(String? value, String label, double limit) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final number = double.tryParse(text);
    if (number == null || number.isNaN || number < -limit || number > limit) {
      return 'Enter a valid ${label.toLowerCase()} (-${limit.toInt()} to ${limit.toInt()})';
    }
    return null;
  }

  /// True when every field passes.
  static bool isValid({
    String? name,
    String? address,
    String? city,
    String? latitude,
    String? longitude,
    String? imageUrl,
  }) =>
      required(name, 'Name') == null &&
      required(address, 'Address') == null &&
      required(city, 'City') == null &&
      ClubFormValidation.latitude(latitude) == null &&
      ClubFormValidation.longitude(longitude) == null &&
      ClubFormValidation.imageUrl(imageUrl) == null;

  /// Server errors carry only a message, so match them to a field by the
  /// field name they mention. Messages that match nothing are returned under
  /// the `_form` key.
  static Map<String, String> mapServerErrors(List<String> messages) {
    final result = <String, String>{};
    for (final message in messages) {
      final lower = message.toLowerCase();
      final field = lower.contains('imageurl') || lower.contains('image')
          ? 'imageUrl'
          : [...fields, ...profileFields].firstWhere(
              (f) => lower.contains(f.toLowerCase()),
              orElse: () => '_form',
            );
      result.putIfAbsent(field, () => message);
    }
    return result;
  }
}
