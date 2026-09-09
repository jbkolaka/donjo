library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/bookings/data/models/booking_models.dart';

abstract class BookingRepository {
  Future<List<Booking>> listMyBookings();

  Future<Booking> bookingDetail(String id);

  Future<List<TicketInstance>> listMyInstances();

  Future<TicketInstance> assignHolder(
    String instanceId,
    AssignTicketRequest request,
  );

  Future<TicketInstance> shareTicket(String instanceId, String email);

  Future<TicketInstance> cancelShare(String instanceId);

  Future<TicketInstance> listForResale(String instanceId, double price);

  Future<TicketInstance> unlistResale(String instanceId);

  Future<TicketInstance> buyResale(String instanceId);

  Future<List<TicketInstance>> marketplace();

  Future<TicketInstance> claimTicket(String email, {String? code});

  Future<CheckinResult> checkin(String code, {String? location});

  Future<void> joinWaitlist(WaitlistSignupRequest request);

  Future<void> leaveWaitlist({
    required String eventId,
    String? ticketType,
  });

  Future<({String eventId, int count, List<WaitlistEntry> entries})> waitlist({
    required String eventId,
  });

  Future<ScanLocation> createScanLocation(Map<String, dynamic> payload);

  Future<({String eventId, List<ScanLocation> locations})> scanLocations({
    required String eventId,
  });
}

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<List<Booking>> listMyBookings() async {
    try {
      final response = await _dio.get('${BackendUri.bookings}/me');
      final data = _asMap(response.data);
      return _parseList(data['bookings'], Booking.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Booking> bookingDetail(String id) async {
    try {
      final response = await _dio.get('${BackendUri.bookings}/$id');
      return Booking.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<TicketInstance>> listMyInstances() async {
    try {
      final response = await _dio.get('${BackendUri.instances}/me');
      final data = _asMap(response.data);
      return _parseList(data['instances'], TicketInstance.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> assignHolder(
    String instanceId,
    AssignTicketRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/$instanceId/assign',
        data: request.toJson(),
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> shareTicket(String instanceId, String email) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/$instanceId/share',
        data: ShareTicketRequest(email: email).toJson(),
      );
      final data = _asMap(response.data);
      return TicketInstance.fromJson(_asMap(data['instance']));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> cancelShare(String instanceId) async {
    try {
      final response = await _dio.delete(
        '${BackendUri.instances}/$instanceId/share',
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> listForResale(String instanceId, double price) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/$instanceId/resale',
        data: ResaleTicketRequest(price: price).toJson(),
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> unlistResale(String instanceId) async {
    try {
      final response = await _dio.delete(
        '${BackendUri.instances}/$instanceId/resale',
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> buyResale(String instanceId) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/$instanceId/buy',
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<TicketInstance>> marketplace() async {
    try {
      final response = await _dio.get('${BackendUri.instances}/marketplace');
      final data = _asMap(response.data);
      return _parseList(data['instances'], TicketInstance.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<TicketInstance> claimTicket(String email, {String? code}) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/claim',
        data: ClaimTicketRequest(email: email).toJson(),
        queryParameters: code != null && code.isNotEmpty ? {'code': code} : null,
      );
      return TicketInstance.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<CheckinResult> checkin(String code, {String? location}) async {
    try {
      final response = await _dio.post(
        '${BackendUri.instances}/checkin',
        data: CheckinRequest(code: code, location: location).toJson(),
      );
      return CheckinResult.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      // Rejected scans are returned as 422, not an error, so surface them as
      // a plain result for the caller to render.
      if (e.response?.statusCode == 422 && e.response?.data is Map) {
        return CheckinResult.fromJson(
          (e.response!.data as Map).cast<String, dynamic>(),
        );
      }
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> joinWaitlist(WaitlistSignupRequest request) async {
    try {
      await _dio.post(BackendUri.waitlist, data: request.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> leaveWaitlist({
    required String eventId,
    String? ticketType,
  }) async {
    try {
      await _dio.delete(
        BackendUri.waitlist,
        queryParameters: {
          'event_id': eventId,
          if (ticketType != null && ticketType.isNotEmpty)
            'ticket_type': ticketType,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<({String eventId, int count, List<WaitlistEntry> entries})> waitlist({
    required String eventId,
  }) async {
    try {
      final response = await _dio.get(
        BackendUri.waitlist,
        queryParameters: {'event_id': eventId},
      );
      final data = _asMap(response.data);
      return (
        eventId: data['event_id'] as String? ?? eventId,
        count: (data['count'] as num?)?.toInt() ?? 0,
        entries: _parseList(data['entries'], WaitlistEntry.fromJson),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ScanLocation> createScanLocation(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        BackendUri.scanLocations,
        data: payload,
      );
      return ScanLocation.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<({String eventId, List<ScanLocation> locations})> scanLocations({
    required String eventId,
  }) async {
    try {
      final response = await _dio.get(
        BackendUri.scanLocations,
        queryParameters: {'event_id': eventId},
      );
      final data = _asMap(response.data);
      return (
        eventId: data['event_id'] as String? ?? eventId,
        locations: _parseList(data['locations'], ScanLocation.fromJson),
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