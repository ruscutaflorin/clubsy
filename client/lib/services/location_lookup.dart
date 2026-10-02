import 'package:geolocator/geolocator.dart';

/// The user's position, only if location permission is already granted.
/// Never prompts: the permission request belongs to the check-in flow.
Future<Position?> positionIfPermitted() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    return await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition();
  } catch (_) {
    return null;
  }
}
