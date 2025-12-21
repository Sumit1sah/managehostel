import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyUserId = 'user_id';
  static const String _keyPassword = 'password';

  static Future<void> saveCredentials(String userId, String passwordHash) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: 'password_hash_$userId', value: passwordHash);
  }

  static Future<String?> getPasswordHash(String userId) async {
    return await _storage.read(key: 'password_hash_$userId');
  }

  static Future<void> saveSession(String userId, String token, DateTime expiry) async {
    await _storage.write(key: 'session_user', value: userId);
    await _storage.write(key: 'session_token', value: token);
    await _storage.write(key: 'session_expiry', value: expiry.toIso8601String());
  }

  static Future<Map<String, String>?> getCurrentSession() async {
    final userId = await _storage.read(key: 'session_user');
    final token = await _storage.read(key: 'session_token');
    final expiry = await _storage.read(key: 'session_expiry');
    
    if (userId == null || token == null || expiry == null) return null;
    
    return {
      'userId': userId,
      'token': token,
      'expiry': expiry,
    };
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: 'session_user');
    await _storage.delete(key: 'session_token');
    await _storage.delete(key: 'session_expiry');
  }

  static Future<String?> getUserId() async {
    final session = await getCurrentSession();
    return session?['userId'];
  }

  static Future<String?> getPassword() async {
    return await _storage.read(key: _keyPassword);
  }

  static Future<bool> isLoggedIn() async {
    final session = await getCurrentSession();
    return session != null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
