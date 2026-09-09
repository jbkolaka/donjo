library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/search/data/models/search_models.dart';

abstract class SearchRepository {
  Future<SearchResult> search(SearchFilters filters);
}

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<SearchResult> search(SearchFilters filters) async {
    try {
      final response = await _dio.get(
        BackendUri.search,
        queryParameters: filters.toQueryParameters(),
      );
      return SearchResult.fromJson(_asMap(response.data));
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
}