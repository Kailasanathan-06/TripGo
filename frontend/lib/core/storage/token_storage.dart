import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps secure token persistence. Never store credentials in editable prefs.
class TokenStorage {
  TokenStorage._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const accessKey = 'tripgo_access';
  static const refreshKey = 'tripgo_refresh';

  static Future<String?> readAccess() => _storage.read(key: accessKey);
  static Future<String?> readRefresh() => _storage.read(key: refreshKey);

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: accessKey, value: access);
    await _storage.write(key: refreshKey, value: refresh);
  }

  static Future<void> clear() async {
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
  }

  static Future<bool> hasTokens() async {
    final access = await readAccess();
    return access != null && access.isNotEmpty;
  }
}