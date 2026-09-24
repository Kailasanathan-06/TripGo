import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'TRIPGO';
  static const tagline = 'Your Journey. One Smart Ticket.';

  static const currency = '₹';

  /// Base URL of the Django REST API.
  /// Android emulator reaches the host machine via 10.0.2.2.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:8000/api/' : 'http://10.0.2.2:8000/api/',
  );

  static const seatHoldMinutes = 15;
  static const demoEmail = 'demo@tripgo.app';
  static const demoPassword = 'demo12345';
}