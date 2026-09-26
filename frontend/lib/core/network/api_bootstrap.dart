import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'api_client.dart';
import 'embedded_server.dart';

class ApiBootstrapException implements Exception {
  const ApiBootstrapException(this.message, {this.detail = ''});

  final String message;
  final String detail;

  @override
  String toString() => detail.isEmpty ? message : '$message\n$detail';
}

/// Brings the API endpoint online before the rest of the app talks to it.
///
/// On Android the backend is embedded in the APK, so the base URL is only known
/// once the native host has bound its loopback socket. Every repository is
/// expected to await [ready] first - see `AuthController.build`.
class ApiBootstrap {
  const ApiBootstrap._();

  static final Completer<void> _gate = Completer<void>();

  static bool _attempted = false;
  static bool _configured = false;
  static String _baseUrl = AppConstants.apiBaseUrl;
  static EmbeddedServerStatus _status = const EmbeddedServerStatus(phase: EmbeddedServerPhase.idle);

  /// Completes once [configure] has pointed [ApiClient] at a reachable API.
  /// Never completes with an error: a failed boot is surfaced on the splash screen
  /// and can be retried, so blocking forever is the safe behaviour here.
  static Future<void> get ready => _gate.future;

  static String get baseUrl => _baseUrl;

  static EmbeddedServerStatus get status => _status;

  /// Resolves the API base URL and waits until the server answers a health probe.
  ///
  /// [onProgress] receives a short human readable line for the splash screen.
  /// Throws [ApiBootstrapException] when the API cannot be reached.
  static Future<void> ensureReady({
    Duration healthTimeout = const Duration(seconds: 45),
    void Function(String message)? onProgress,
  }) async {
    if (_configured) return;
    _attempted = true;

    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      // Web and desktop builds talk to a Django server started separately.
      _applyBaseUrl(AppConstants.apiBaseUrl);
      _status = const EmbeddedServerStatus.unavailable();
      return;
    }

    onProgress?.call('Starting the TripGo server');
    _status = await EmbeddedServer.waitUntilServing(
      onProgress: (status) {
        _status = status;
        onProgress?.call(status.label);
      },
    );

    if (!_status.isServing) {
      throw ApiBootstrapException(
        'The TripGo server could not start.',
        detail: _status.detail,
      );
    }

    _applyBaseUrl(_status.baseUrl);
    await _awaitHealthy(healthTimeout, onProgress);
  }

  /// Forgets a failed attempt so the splash screen can retry.
  static void reset() {
    if (_configured) return;
    _attempted = false;
    _status = const EmbeddedServerStatus(phase: EmbeddedServerPhase.idle);
  }

  static bool get hasAttempted => _attempted;

  static void _applyBaseUrl(String url) {
    _baseUrl = url;
    ApiClient.instance.configureBaseUrl(url);
    _configured = true;
    if (!_gate.isCompleted) _gate.complete();
  }

  /// The socket is bound before the schema exists, so poll the health endpoint to
  /// be sure the first real request from the app will not race the boot.
  static Future<void> _awaitHealthy(Duration timeout, void Function(String message)? onProgress) async {
    final probe = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final deadline = DateTime.now().add(timeout);
    Object? lastError;

    while (DateTime.now().isBefore(deadline)) {
      onProgress?.call('Checking the TripGo server');
      try {
        final response = await probe.get<Map<String, dynamic>>('/health/');
        if (response.statusCode == 200) return;
        lastError = 'HTTP ${response.statusCode}';
      } on DioException catch (e) {
        lastError = e.message ?? e.type.name;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    throw ApiBootstrapException('The TripGo server did not become ready.', detail: '$lastError');
  }
}
