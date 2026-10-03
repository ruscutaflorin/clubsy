/// Base URL of the Clubsy API, overridable at build time:
///
///   Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api`
///   Physical device:  `--dart-define=API_BASE_URL=http://<LAN-IP>:3000/api`
///   (or an https URL for a deployed server)
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api',
);
