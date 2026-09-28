import 'package:shared_preferences/shared_preferences.dart';

/// An optional address of a TripGo API running on another machine.
///
/// The backend is embedded in the APK, so the app normally needs no server at all.
/// That is the better default, but CPython has to extract its runtime, import
/// Django and migrate the database before the first request can be served, which
/// is slow on a phone and turns into a wait the user cannot see the end of.
///
/// Pointing the app at a Django server on the development machine is the escape
/// hatch for that: the phone holds no data and the API is as quick as the laptop.
/// The address is stored on the device, so the same build can be pointed at a new
/// IP without being rebuilt, which matters because a laptop's address changes
/// every time it rejoins a network.
class ServerOverride {
  ServerOverride._();

  static const _key = 'tripgo.serverOverride';

  static String? _hostPort;

  /// The stored `host:port`, or null when the app should use its own server.
  ///
  /// Returns null rather than asserting when [load] has not finished. The splash
  /// screen reads this while building, which happens before the first `await` in
  /// `initState` has completed, so a check here would throw during the first frame
  /// and take the whole screen down.
  static String? get hostPort => _hostPort;

  /// True when the app has been pointed at a machine on the network.
  static bool get isActive => hostPort != null;

  static String? get baseUrl {
    final address = hostPort;
    return address == null ? null : 'http://$address/api/';
  }

  static bool _loading = false;

  static Future<void> load() async {
    if (_loading || _hostPort != null) return;
    // Set before the first await so concurrent callers share one read.
    _loading = true;
    try {
      final stored = (await SharedPreferences.getInstance()).getString(_key);
      _hostPort = stored == null || stored.isEmpty ? null : stored;
    } catch (_) {
      // A missing or failing preference store must not stop the app from using its
      // own embedded server, which is the default anyway.
      _hostPort = null;
    } finally {
      _loading = false;
    }
  }

  /// Stores [raw] after normalising it, or clears the override when it is null.
  ///
  /// Throws [FormatException] when the value cannot be understood, because a
  /// silently ignored address would leave the app talking to a server that is not
  /// there and looking like a network fault.
  static Future<void> save(String? raw) async {
    final normalised = raw == null ? null : _normalise(raw);
    _hostPort = normalised;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, normalised ?? '');
    } catch (_) {
      // The value stays in effect for this run even if it could not be stored, so
      // the user is not left with a server they just switched away from.
    }
  }

  /// Checks [raw] without storing it, so a dialog can show the problem inline.
  static String normaliseForPreview(String raw) => _normalise(raw);

  /// Reduces what a person is likely to type to a `host:port` pair.
  ///
  /// Accepts `192.168.1.5`, `192.168.1.5:8000` and a full URL such as
  /// `http://192.168.1.5:8000/api/`, since all three are reasonable things to
  /// paste out of a terminal or a browser.
  static String _normalise(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      throw const FormatException('Enter the address of your computer.');
    }

    value = value.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    value = value.replaceAll(RegExp(r'/.*$'), '');

    final parts = value.split(':');
    if (parts.length > 2) {
      throw FormatException('"$raw" is not a valid address.');
    }
    final host = parts.first.trim();
    if (host.isEmpty) {
      throw FormatException('"$raw" has no host name.');
    }

    var port = 8000;
    if (parts.length == 2) {
      final parsed = int.tryParse(parts[1].trim());
      if (parsed == null || parsed < 1 || parsed > 65535) {
        throw FormatException('"${parts[1].trim()}" is not a valid port.');
      }
      port = parsed;
    }

    return '$host:$port';
  }
}
