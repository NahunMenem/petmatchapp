import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _testEmailKey = 'test_email';
  static const _homeIntroSeenKey = 'home_intro_seen';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  static Future<void> saveUsername(String name) =>
      _storage.write(key: _usernameKey, value: name);

  static Future<String?> getUsername() => _storage.read(key: _usernameKey);

  static Future<void> saveTestEmail(String email) =>
      _storage.write(key: _testEmailKey, value: email);

  static Future<String?> getTestEmail() => _storage.read(key: _testEmailKey);

  static Future<void> setHomeIntroSeen(bool seen) =>
      _storage.write(key: _homeIntroSeenKey, value: seen ? 'true' : 'false');

  static Future<bool> getHomeIntroSeen() async =>
      (await _storage.read(key: _homeIntroSeenKey)) == 'true';

  static Future<void> clearAll() => _storage.deleteAll();
}
