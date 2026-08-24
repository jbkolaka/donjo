library;

import 'package:dio/dio.dart';

abstract final class ApiErrorCode {
  static const validation = 'validation_error';
  static const unauthorized = 'unauthorized';
  static const forbidden = 'forbidden';
  static const notFound = 'not_found';
  static const methodNotAllowed = 'method_not_allowed';
  static const conflict = 'conflict';
  static const internal = 'internal_error';
  static const unavailable = 'service_unavailable';

  static const network = 'network_error';

  static const malformed = 'malformed_response';
}

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const {},
  });

  final String code;

  final String message;

  final int? statusCode;

  final Map<String, String> fields;

  bool get isRetryable =>
      code == ApiErrorCode.network ||
      code == ApiErrorCode.unavailable ||
      code == ApiErrorCode.internal;

  bool get isAuthFailure => code == ApiErrorCode.unauthorized;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map && data['error'] is Map) {
      final detail = (data['error'] as Map).cast<String, dynamic>();
      final rawFields = detail['fields'];

      return ApiException(
        code: detail['code'] as String? ?? ApiErrorCode.internal,
        message: detail['message'] as String? ?? 'Something went wrong.',
        statusCode: response?.statusCode,
        fields: rawFields is Map
            ? rawFields.map((k, v) => MapEntry(k.toString(), v.toString()))
            : const {},
      );
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiException(
        code: ApiErrorCode.network,
        message: 'The connection timed out. Check your network and try again.',
      ),
      DioExceptionType.connectionError => ApiException(
        code: ApiErrorCode.network,
        message: 'Could not reach the Zoa server. Check your connection.',
      ),
      DioExceptionType.cancel => ApiException(
        code: ApiErrorCode.network,
        message: 'The request was cancelled.',
      ),
      _ => ApiException(
        code: ApiErrorCode.internal,
        message: 'Unexpected server response.',
        statusCode: response?.statusCode,
      ),
    };
  }

  @override
  String toString() =>
      'ApiException($code${statusCode != null ? ' $statusCode' : ''}): $message';
}
