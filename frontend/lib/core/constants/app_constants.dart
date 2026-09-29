import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'TRIPGO';
  static const tagline = 'Your Journey. One Smart Ticket.';

  static const currency = '₹';

  /// Base URL of the TripGo API.
  ///
  /// Override at build time with
  ///   --dart-define=API_BASE_URL=http://<host>:<port>/api/
  ///
  /// Defaults:
  ///   • Android emulator → 10.0.2.2 maps to the host machine's loopback,
  ///     so `manage.py runserver 0.0.0.0:8000` on the host is reachable.
  ///   • Web / desktop → 127.0.0.1:8000 (Django dev server on the same machine).
  ///
  /// For a **physical device** replace the default with your machine's LAN IP:
  ///   --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb
        ? 'http://127.0.0.1:8000/api/'
        : 'http://10.0.2.2:8000/api/',
  );

  static const seatHoldMinutes = 15;
  static const demoEmail = 'demo@tripgo.app';
  static const demoPassword = 'demo12345';

  /// Identifies the build running on the device, shown on the splash screen.
  static const buildStamp =
      String.fromEnvironment('BUILD_STAMP', defaultValue: 'dev');
}