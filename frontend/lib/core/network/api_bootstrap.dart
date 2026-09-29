import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'api_client.dart';

class ApiBootstrapException implements Exception {
  const ApiBootstrapException(this.message, {this.detail = ''});

  final String message;
  final String detail;

  @override
  String toString() => detail.isEmpty ? message : '$message\n$detail';
}

/// Brings the API endpoint online before the rest of the app talks to it.
///
/// The app now talks to an **external** Django API server rather than an
/// in-process Python interpreter. On first launch the splash screen will
/// verify the server is reachable via a /health/ probe and then proceed.
/// There is no 45-second startup window, no Python extraction, and no
/// Chaquopy dependency.
///
/// To point the app at your server, build with:
///   flutter build apk --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/
/// During development the Android emulator's default host alias works:
///   --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/
class ApiBootstrap {
  const ApiBootstrap._();

  static final Completer<void> _gate = Completer<void>();

  static bool _attempted = false;
  static bool _configured = false;
  static String _baseUrl = AppConstants.apiBaseUrl;

  /// Completes once [ensureReady] has pointed [ApiClient] at a reachable API.
  static Future<void> get ready => _gate.future;

  static String get baseUrl => _baseUrl;

  /// Checks that the Django API server is reachable.
  ///
  /// On success the gate is opened so every repository can start making
  /// requests. On failure an [ApiBootstrapException] is thrown so the splash
  /// screen can show a retry button.
  static Future<void> ensureReady({
    Duration healthTimeout = const Duration(seconds: 30),
    void Function(String message)? onProgress,
  }) async {
    if (_configured) return;
    _attempted = true;

    // Configure the base URL immediately – it is static on all platforms.
    _setBaseUrl(AppConstants.apiBaseUrl);
    onProgress?.call('Connecting to TripGo server…');

    await _awaitHealthy(healthTimeout, onProgress);
  }

  /// Forgets a failed attempt so the splash screen can retry.
  static void reset() {
    if (_configured) return;
    _attempted = false;
  }

  static bool get hasAttempted => _attempted;

  static void updateBaseUrl(String url) {
    _setBaseUrl(url);
    _attempted = false;
  }

  static void _setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url : '$url/';
    ApiClient.instance.configureBaseUrl(_baseUrl);
  }

  static void _markReady() {
    _configured = true;
    if (!_gate.isCompleted) _gate.complete();
  }

  /// Polls the /health/ endpoint until it answers 200 or [timeout] elapses.
  static Future<void> _awaitHealthy(
    Duration timeout,
    void Function(String message)? onProgress,
  ) async {
    final probe = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    int attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      onProgress?.call(
          'Connecting to TripGo server${attempt > 1 ? ' (attempt $attempt)' : ''}…');
      try {
        final response =
            await probe.get<Map<String, dynamic>>('/health/');
        if (response.statusCode == 200) {
          _markReady();
          return;
        }
        lastError = 'HTTP ${response.statusCode}';
      } on DioException catch (e) {
        lastError = e.message ?? e.type.name;
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    throw ApiBootstrapException(
      'Could not reach the TripGo server.',
      detail:
          'Gave up after ${timeout.inSeconds}s probing $_baseUrl\n'
          'Last error: $lastError\n\n'
          'Make sure the Django server is running and set the API URL:\n'
          '  flutter build apk \\\n'
          '    --dart-define=API_BASE_URL=http://<your-ip>:8000/api/',
    );
  }
}
