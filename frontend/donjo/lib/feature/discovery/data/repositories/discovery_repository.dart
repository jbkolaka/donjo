library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/discovery/data/models/discovery_models.dart';
import 'package:donjo/feature/events/data/models/event_models.dart';

/// Response wrapper for GET /api/v1/events/:id/similar.
class SimilarEventsResult {
  const SimilarEventsResult({required this.eventId, this.items = const []});

  final String eventId;
  final List<SimilarEvent> items;
}

abstract class DiscoveryRepository {
  Future<RecResult> recommendations({String type, int limit});

  Future<UserProfile> profile();

  Future<void> recordInteraction(InteractionRequest request);

  Future<Event?> event(String id);

  Future<SimilarEventsResult> similarEvents(String eventId, {int limit});
}

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<RecResult> recommendations({
    String type = RecType.upcoming,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        BackendUri.recommendations,
        queryParameters: {'type': type, 'limit': limit.toString()},
      );
      return RecResult.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<UserProfile> profile() async {
    try {
      final response = await _dio.get(BackendUri.profile);
      return UserProfile.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> recordInteraction(InteractionRequest request) async {
    try {
      await _dio.post(
        BackendUri.interactions,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event?> event(String id) async {
    try {
      final response = await _dio.get('${BackendUri.events}/$id');
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SimilarEventsResult> similarEvents(String eventId, {int limit = 8}) async {
    try {
      final response = await _dio.get(
        '${BackendUri.events}/$eventId/similar',
        queryParameters: {'limit': limit.toString()},
      );
      final data = _asMap(response.data);
      return SimilarEventsResult(
        eventId: data['event_id'] as String? ?? eventId,
        items: data['items'] is List
            ? (data['items'] as List)
                .whereType<Map>()
                .map((e) => SimilarEvent.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
      );
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