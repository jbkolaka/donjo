library;

import 'package:dio/dio.dart';
import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/authentication/data/model/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
    String? twoFactorCode,
  });

  Future<UserModel> register(CreateUserRequest request);

  Future<UserModel> getMe();

  Future<void> logout();

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<bool> hasSavedToken();

  Future<void> clearSession();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;
  final TokenStore _tokenStore;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      final req = LoginRequest(
        email: email,
        password: password,
        twoFactorCode: twoFactorCode,
      );

      final response = await _dio.post(
        '/api/v1/auth/login',
        data: req.toJson(),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['tfa_required'] == true) {
        return const AuthResult(twoFactorRequired: true);
      }

      final userJson = data['user'] as Map<String, dynamic>;
      final tokensJson = data['tokens'] as Map<String, dynamic>;

      final user = UserModel.fromJson(userJson);
      final tokens = TokenResponse.fromJson(tokensJson);

      await _tokenStore.save(tokens.accessToken);

      return AuthResult(user: user, tokens: tokens);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<UserModel> register(CreateUserRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/api/v1/me');
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = _tokenStore.token;
      if (token != null && token.isNotEmpty) {
        await _dio.post('/api/v1/auth/logout', data: {'refresh_token': token});
      }
    } catch (_) {
      // Best-effort logout
    } finally {
      await _tokenStore.clear();
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/api/v1/auth/password/forgot', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/password/reset',
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<bool> hasSavedToken() async {
    final token = await _tokenStore.load();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clearSession() async {
    await _tokenStore.clear();
  }
}
