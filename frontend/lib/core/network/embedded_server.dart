import 'package:flutter/services.dart';

/// Lifecycle of the Django backend that is embedded in the TripGo APK.
enum EmbeddedServerPhase {
  /// Nothing has been started yet.
  idle,

  /// Python is up, the socket is bound, migrations/demo data are still loading.
  warming,

  /// The API answers requests on the loopback interface.
  serving,

  /// The socket was closed on purpose.
  stopped,

  /// The server could not be started; [EmbeddedServerStatus.detail] says why.
  error,

  /// No host is reachable, e.g. on the web or desktop build.
  unavailable,
}

class EmbeddedServerStatus {
  const EmbeddedServerStatus({
    required this.phase,
    this.port = 0,
    this.detail = '',
  });

  const EmbeddedServerStatus.unavailable()
      : phase = EmbeddedServerPhase.unavailable,
        port = 0,
        detail = '';

  final EmbeddedServerPhase phase;
  final int port;
  final String detail;

  bool get isServing => phase == EmbeddedServerPhase.serving;

  /// Base URL of the API served by the embedded backend.
  String get baseUrl => 'http://127.0.0.1:$port/api/';

  /// Human readable line for the splash screen.
  String get label {
    switch (phase) {
      case EmbeddedServerPhase.warming:
        return detail.isEmpty ? 'Starting the TripGo server' : detail;
      case EmbeddedServerPhase.serving:
        return 'TripGo server ready';
      case EmbeddedServerPhase.error:
        return 'The TripGo server could not start';
      case EmbeddedServerPhase.stopped:
        return 'TripGo server stopped';
      case EmbeddedServerPhase.idle:
        return 'Starting the TripGo server';
      case EmbeddedServerPhase.unavailable:
        return 'TripGo server unavailable';
    }
  }
}

/// Dart side of the bridge to the in-app Python server.
///
/// The native host owns the interpreter and the socket; this class only observes
/// it. Because CPython lives in the app process, the API is already running by the
/// time the UI is interactive.
class EmbeddedServer {
  const EmbeddedServer._();

  static const MethodChannel _channel = MethodChannel('com.example.tripgo/server');

  /// Reads the current state of the embedded server.
  static Future<EmbeddedServerStatus> fetchStatus() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('status');
      if (raw == null) return const EmbeddedServerStatus.unavailable();
      return EmbeddedServerStatus(
        phase: _parsePhase(raw['phase'] as String?),
        port: (raw['port'] as num?)?.toInt() ?? 0,
        detail: (raw['detail'] as String?) ?? '',
      );
    } on MissingPluginException {
      return const EmbeddedServerStatus.unavailable();
    } on PlatformException catch (e) {
      return EmbeddedServerStatus(phase: EmbeddedServerPhase.error, detail: e.message ?? e.code);
    }
  }

  /// Polls the host until the API is serving, the boot fails, or [timeout] elapses.
  static Future<EmbeddedServerStatus> waitUntilServing({
    Duration timeout = const Duration(seconds: 150),
    Duration interval = const Duration(milliseconds: 350),
    void Function(EmbeddedServerStatus status)? onProgress,
  }) async {
    final deadline = DateTime.now().add(timeout);
    var current = const EmbeddedServerStatus(phase: EmbeddedServerPhase.idle);

    while (true) {
      current = await fetchStatus();
      onProgress?.call(current);

      if (current.phase != EmbeddedServerPhase.warming && current.phase != EmbeddedServerPhase.idle) {
        return current;
      }
      if (DateTime.now().isAfter(deadline)) {
        return const EmbeddedServerStatus(
          phase: EmbeddedServerPhase.error,
          detail: 'Timed out while starting the TripGo server.',
        );
      }
      await Future<void>.delayed(interval);
    }
  }

  static EmbeddedServerPhase _parsePhase(String? raw) {
    for (final phase in EmbeddedServerPhase.values) {
      if (phase.name == raw) return phase;
    }
    return EmbeddedServerPhase.idle;
  }
}
