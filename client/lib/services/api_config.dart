import 'package:flutter/foundation.dart';

const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Base URL of the Clubsy API, overridable at build time:
///
///   Physical device:  `--dart-define=API_BASE_URL=http://<LAN-IP>:3000/api`
///   (or an https URL for a deployed server)
///
/// Without the define it points at a local dev server: `10.0.2.2` on Android
/// (the emulator's alias for the host machine), `localhost` elsewhere.
String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return 'http://${isAndroid ? '10.0.2.2' : 'localhost'}:3000/api';
}
