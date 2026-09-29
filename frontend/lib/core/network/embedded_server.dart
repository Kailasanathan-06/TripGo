/// Stub – the embedded in-process server has been removed.
///
/// TripGo now talks to a Django API that is started separately (either via
/// `manage.py runserver` during development, or a production deployment).
/// Set the API base URL at build time with
///   --dart-define=API_BASE_URL=http://<host>:<port>/api/
/// The default is http://10.0.2.2:8000/api/ which maps to the host machine
/// from inside the Android emulator.

/// Phase of the (now removed) embedded server – kept so the rest of the
/// code base compiles without changes.
enum EmbeddedServerPhase {
  idle,
  warming,
  serving,
  stopped,
  error,
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

  String get baseUrl => 'http://127.0.0.1:$port/api/';

  String get label {
    switch (phase) {
      case EmbeddedServerPhase.warming:
        return detail.isEmpty ? 'Connecting…' : detail;
      case EmbeddedServerPhase.serving:
        return 'Connected';
      case EmbeddedServerPhase.error:
        return 'Could not connect to the server';
      case EmbeddedServerPhase.stopped:
        return 'Server stopped';
      case EmbeddedServerPhase.idle:
        return 'Initialising…';
      case EmbeddedServerPhase.unavailable:
        return 'Server unavailable';
    }
  }
}

/// No-op stub – the embedded server no longer exists.
class EmbeddedServer {
  const EmbeddedServer._();

  static Future<EmbeddedServerStatus> fetchStatus() async =>
      const EmbeddedServerStatus.unavailable();

  static Future<EmbeddedServerStatus> waitUntilServing({
    Duration timeout = const Duration(seconds: 30),
    Duration interval = const Duration(milliseconds: 350),
    void Function(EmbeddedServerStatus status)? onProgress,
  }) async =>
      const EmbeddedServerStatus.unavailable();
}
