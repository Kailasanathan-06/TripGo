import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'TRIPGO';
  static const tagline = 'Your Journey. One Smart Ticket.';

  static const currency = '₹';

  /// Loopback port the embedded Django server binds by default. Must match
  /// `PREFERRED_PORT` in `android/app/src/main/python/tripgo_server.py`.
  static const embeddedServerPort = 8765;

  /// Base URL of the TripGo API.
  ///
  /// On Android the Django backend is bundled into the APK and listens on the
  /// loopback interface, so the app talks to `127.0.0.1` and never to a machine on
  /// the network. The port is resolved at startup by `ApiBootstrap`; this value is
  /// only the fallback and is also what the web build uses, pointed at a Django
  /// server started with `manage.py runserver 127.0.0.1:8000`.
  ///
  /// Override at build time with
  /// `--dart-define=API_BASE_URL=http://<host>:8000/api/`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb
        ? 'http://127.0.0.1:8000/api/'
        : 'http://127.0.0.1:$embeddedServerPort/api/',
  );

  static const seatHoldMinutes = 15;
  static const demoEmail = 'demo@tripgo.app';
  static const demoPassword = 'demo12345';
}