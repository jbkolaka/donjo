library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/notifications/data/models/notification_models.dart';

abstract class NotificationRepository {
  Future<List<Notification>> listNotifications();

  Future<int> unreadCount();

  Future<Notification> createNotification(CreateNotificationRequest request);

  Future<void> markRead(String id);

  Future<void> markClicked(String id);

  Future<List<FeedItem>> getFeed();

  Future<void> markFeedViewed(String id);

  Future<void> markFeedClicked(String id);

  Future<void> markFeedInteracted(String id);

  Future<PushDevice> registerDevice(RegisterDeviceRequest request);

  Future<List<PushDevice>> listDevices();

  Future<void> deleteDevice(String id);

  Future<List<NotificationTemplate>> listTemplates();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<List<Notification>> listNotifications() async {
    try {
      final response = await _dio.get(BackendUri.notifications);
      final data = _asMap(response.data);
      return _parseList(data['items'], Notification.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('${BackendUri.notifications}/unread-count');
      final data = _asMap(response.data);
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Notification> createNotification(CreateNotificationRequest request) async {
    try {
      final response = await _dio.post(
        BackendUri.notifications,
        data: request.toJson(),
      );
      return Notification.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.patch('${BackendUri.notifications}/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markClicked(String id) async {
    try {
      await _dio.patch(
        '${BackendUri.notifications}/$id/clicked',
        );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<FeedItem>> getFeed() async {
    try {
      final response = await _dio.get(BackendUri.feed);
      final data = _asMap(response.data);
      return _parseList(data['items'], FeedItem.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markFeedViewed(String id) async {
    try {
      await _dio.patch('${BackendUri.feed}/$id/view');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markFeedClicked(String id) async {
    try {
      await _dio.patch('${BackendUri.feed}/$id/click');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markFeedInteracted(String id) async {
    try {
      await _dio.patch(
        '${BackendUri.feed}/$id/interact',
        );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<PushDevice> registerDevice(RegisterDeviceRequest request) async {
    try {
      final response = await _dio.post(BackendUri.devices, data: request.toJson());
      return PushDevice.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<PushDevice>> listDevices() async {
    try {
      final response = await _dio.get('${BackendUri.devices}/me');
      final data = _asMap(response.data);
      return _parseList(data['items'], PushDevice.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteDevice(String id) async {
    try {
      await _dio.delete('${BackendUri.devices}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<NotificationTemplate>> listTemplates() async {
    try {
      final response = await _dio.get(BackendUri.templates);
      final data = _asMap(response.data);
      return _parseList(data['items'], NotificationTemplate.fromJson);
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