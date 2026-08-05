import 'package:shared_preferences/shared_preferences.dart';

class SpService {
  static const String _tokenKey = 'auth_token';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return await _prefs.getString(_tokenKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
  }
}