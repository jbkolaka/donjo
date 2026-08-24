library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'zoa.auth.token';

  final FlutterSecureStorage _storage;

  String? _token;

  String? get token => _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<String?> load() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } on Exception {
      _token = null;
    }
    return _token;
  }

  Future<void> save(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _token = null;
    try {
      await _storage.delete(key: _tokenKey);
    } on Exception {}
  }
}
