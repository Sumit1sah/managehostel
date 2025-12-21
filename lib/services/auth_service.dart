import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/hive_storage.dart';

class AuthService {
  Future<AuthResult> login(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      return AuthResult(false, 'Please enter both user ID and password');
    }
    
    // Check for warden account
    if (userId.toLowerCase() == 'warden' && password == 'warden123') {
      await _createSession(userId);
      await SecureStorage.saveCredentials(userId, _hashPassword(password));
      return AuthResult(true, 'Warden login successful');
    }
    
    // Validate credentials
    if (await _validateCredentials(userId, password)) {
      await _createSession(userId);
      return AuthResult(true, 'Login successful');
    } else {
      return AuthResult(false, 'Invalid credentials');
    }
  }
  
  Future<bool> isWarden() async {
    final userId = await getUserId();
    return userId?.toLowerCase() == 'warden';
  }
  
  Future<bool> _validateCredentials(String userId, String password) async {
    // Check if user is in authorized list (created by warden)
    final authorizedUsers = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    
    for (var user in authorizedUsers) {
      if (user['userId'] == userId && user['password'] == password) {
        return true;
      }
    }
    
    return false;
  }
  
  String _generateSystemPassword(String userId) {
    // Generate password based on user ID
    final basePassword = userId.toLowerCase();
    final year = DateTime.now().year.toString();
    return '${basePassword}@$year';
  }
  
  String getSystemPassword(String userId) {
    return _generateSystemPassword(userId);
  }
  
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'hostel_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<void> _createSession(String userId) async {
    final sessionToken = _generateSessionToken();
    final expiryTime = DateTime.now().add(const Duration(hours: 12));
    await SecureStorage.saveSession(userId, sessionToken, expiryTime);
  }
  
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode * 31).toString();
    return _hashPassword(timestamp + random);
  }

  Future<bool> isLoggedIn() async {
    final session = await SecureStorage.getCurrentSession();
    if (session == null) return false;
    
    final expiryTime = DateTime.parse(session['expiry']!);
    if (DateTime.now().isAfter(expiryTime)) {
      await logout();
      return false;
    }
    return true;
  }

  Future<String?> getUserId() async {
    final session = await SecureStorage.getCurrentSession();
    return session?['userId'];
  }

  Future<void> logout() async {
    await SecureStorage.clearSession();
    await HiveStorage.save(HiveStorage.appStateBox, 'last_logout', DateTime.now().toIso8601String());
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final userId = await getUserId();
    if (userId == null) return false;
    
    if (newPassword.length < 6) return false;
    
    // For warden account
    if (userId.toLowerCase() == 'warden') {
      if (oldPassword != 'warden123') return false;
      // Warden password change logic can be added here if needed
      return true;
    }
    
    // For student accounts - update in authorized_users list
    final authorizedUsers = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    bool userFound = false;
    
    for (int i = 0; i < authorizedUsers.length; i++) {
      if (authorizedUsers[i]['userId'] == userId) {
        if (authorizedUsers[i]['password'] != oldPassword) return false;
        authorizedUsers[i]['password'] = newPassword;
        userFound = true;
        break;
      }
    }
    
    if (!userFound) return false;
    
    // Save updated list back to storage
    await HiveStorage.saveList(HiveStorage.appStateBox, 'authorized_users', authorizedUsers);
    
    return true;
  }
  

}

class AuthResult {
  final bool success;
  final String message;
  
  AuthResult(this.success, this.message);
}
