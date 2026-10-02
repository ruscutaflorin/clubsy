/// Why we couldn't get a usable position for a check-in.
enum LocationProblem {
  permissionDenied,
  permissionDeniedForever,
  servicesDisabled,
  timeout,
  mocked,
}

/// User-facing wording for each [LocationProblem].
String locationProblemMessage(LocationProblem problem) {
  switch (problem) {
    case LocationProblem.permissionDenied:
      return 'Location permission is required to check in';
    case LocationProblem.permissionDeniedForever:
      return 'Location is blocked for Clubsy — enable it in app settings to check in';
    case LocationProblem.servicesDisabled:
      return 'Location services are off — turn them on to check in';
    case LocationProblem.timeout:
      return "Couldn't get a GPS fix — step outside the entrance and try again";
    case LocationProblem.mocked:
      return "Mock locations aren't allowed for check-ins";
  }
}
