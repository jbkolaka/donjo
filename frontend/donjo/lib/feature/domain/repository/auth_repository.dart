import 'package:dio/dio.dart';
import 'package:donjo/feature/constant/backend_uri.dart';
import 'package:donjo/models/user_model.dart';
import 'package:donjo/services/sp_service.dart';

class AuthRemoteRepository {
  final spService = SpService();

  late final Dio _dio;

  AuthRemoteRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BackendUri.backendUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await spService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await spService.clearAll();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<UserModel> signUp({
    required String full_name,
    required String user_name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/register',
        data: {
          'full_name': full_name,
          'user_name': user_name,
          'email': email,
          'password': password,
        },
      );

      final responseData = Map<String, dynamic>.from(response.data);

      final userMap = Map<String, dynamic>.from(responseData['user'] ?? {});
      final userData = {
        ...userMap,
        'token': responseData['token']?.toString() ?? '',
      };

      if (responseData['token'] != null) {
        await spService.setToken(responseData['token'].toString());
      }

      return UserModel.fromMap(userData);
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];
          if (errors != null) {
            final errorMap = Map<String, dynamic>.from(errors);
            final errorMessages = errorMap.values
                .expand((x) => x as List)
                .join('\n');
            throw errorMessages;
          }
        }
        final message = e.response?.data['message'];
        throw message?.toString() ?? 'Registration failed';
      } else {
        throw e.message ?? 'Network error occurred';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> login({
    required String user_name,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {'user_name': user_name, 'password': password},
      );

      final responseData = Map<String, dynamic>.from(response.data);

      final userMap = Map<String, dynamic>.from(responseData['user'] ?? {});
      final userData = {
        ...userMap,
        'token': responseData['token']?.toString() ?? '',
      };

      if (responseData['token'] != null) {
        await spService.setToken(responseData['token'].toString());
      }

      return UserModel.fromMap(userData);
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'];
        throw message?.toString() ?? 'Login failed';
      } else {
        throw e.message ?? 'Network error occurred';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final token = await spService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _dio.get('/api/user');

      final responseData = Map<String, dynamic>.from(response.data);

      final userData = {...responseData, 'token': token};

      return UserModel.fromMap(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await spService.clearAll();
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } finally {
      await spService.clearAll();
      refreshDio();
    }
  }

  void refreshDio() {
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
