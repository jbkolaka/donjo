import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/app/data/models/app_model.dart';

class AppRepository {
  AppRepository({required this.tokenStore, this.onUnauthorized}) {
    _dio = createZoaDio(
      tokenStore: tokenStore,
      onUnauthorizedProvider: () => onUnauthorized,
    );
  }

  final TokenStore tokenStore;
  late final Dio _dio;
  VoidCallback? onUnauthorized;

  String get baseUrl => _dio.options.baseUrl;

  Future<HealthStatus> health() async {
    try {
      final response = await _dio.get<dynamic>('/health');
      return HealthStatus.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<MetaCatalog> meta() async {
    try {
      final response = await _dio.get<dynamic>('/meta');
      return MetaCatalog.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('The server sent an unexpected response.');
  }
}
