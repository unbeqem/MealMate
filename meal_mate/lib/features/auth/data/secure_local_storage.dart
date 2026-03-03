import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom [LocalStorage] implementation that stores the Supabase session token
/// in the device Keychain (iOS) / Keystore (Android) via [FlutterSecureStorage].
///
/// This overrides the default [SharedPreferences]-based storage, which stores
/// tokens in plaintext on Android. Pass this to [Supabase.initialize()] via
/// [FlutterAuthClientOptions.localStorage].
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: _sessionKey)) != null;

  @override
  Future<String?> accessToken() async => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() async =>
      _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) async =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}
