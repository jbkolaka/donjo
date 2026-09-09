library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/payments/data/models/payment_models.dart';

abstract class PaymentRepository {
  Future<List<Transaction>> listMyTransactions();

  Future<Transaction> transactionDetail(String id);

  Future<Escrow> escrowDetail(String id);

  Future<List<WalletEntry>> myWallet();
}

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<List<Transaction>> listMyTransactions() async {
    try {
      final response = await _dio.get('${BackendUri.transactions}/me');
      final data = _asMap(response.data);
      return _parseList(data['transactions'], Transaction.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Transaction> transactionDetail(String id) async {
    try {
      final response = await _dio.get('${BackendUri.transactions}/$id');
      final data = _asMap(response.data);
      return Transaction.fromJson(_asMap(data['transaction']));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Escrow> escrowDetail(String id) async {
    try {
      final response = await _dio.get('${BackendUri.escrows}/$id');
      final data = _asMap(response.data);
      return Escrow.fromJson(_asMap(data['escrow']));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<WalletEntry>> myWallet() async {
    try {
      final response = await _dio.get('${BackendUri.wallet}/me');
      final data = _asMap(response.data);
      return _parseList(data['entries'], WalletEntry.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    throw ApiException(
      code: ApiErrorCode.malformed,
      message: 'The server sent an unexpected response.',
    );
  }

  List<T> _parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}