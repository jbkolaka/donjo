library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/storage/token_store.dart';

Dio createZoaDio({
  required TokenStore tokenStore,
  VoidCallback? Function()? onUnauthorizedProvider,
  String? baseUrl,
  Duration timeout = const Duration(seconds: 15),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? BackendUri.backendUri,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.clear();
          onUnauthorizedProvider?.call()?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
