library;

import 'package:dio/dio.dart';

import 'package:donjo/core/config/backend_uri.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/core/network/donjo_dio.dart';
import 'package:donjo/core/storage/token_store.dart';
import 'package:donjo/feature/events/data/models/event_models.dart';

/// Filters for GET /api/v1/events (and /api/v1/venues).
class EventListQuery {
  const EventListQuery({
    this.creatorId,
    this.category,
    this.status,
    this.city,
    this.upcoming,
    this.limit,
    this.offset,
  });

  final String? creatorId;
  final String? category;
  final String? status;
  final String? city;
  final bool? upcoming;
  final int? limit;
  final int? offset;

  Map<String, dynamic> toQueryParameters() => {
        if (creatorId != null && creatorId!.isNotEmpty) 'creator_id': creatorId,
        if (category != null && category!.isNotEmpty) 'category': category,
        if (status != null && status!.isNotEmpty) 'status': status,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (upcoming != null) 'upcoming': upcoming.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };
}

abstract class EventRepository {
  Future<List<Event>> listEvents({EventListQuery? query});

  Future<Event> getEvent(String id);

  Future<Event> getEventBySlug(String slug);

  Future<List<Ticket>> listTickets(String eventId);

  Future<void> likeEvent(String id);

  Future<Event> createEvent(EventDraft draft);

  Future<Event> updateEvent(String id, EventDraft draft);

  Future<void> deleteEvent(String id);

  Future<Event> publishEvent(String id);

  Future<Event> unpublishEvent(String id);

  Future<Ticket> createTicket(String eventId, TicketDraft draft);

  Future<Ticket> updateTicket(String eventId, String ticketId, TicketDraft draft);

  Future<void> deleteTicket(String eventId, String ticketId);

  /// Returns the updated ticket and quantity purchased.
  Future<({Ticket ticket, int quantity})> purchaseTicket(
    String eventId,
    String ticketId,
    int quantity,
  );

  Future<List<Venue>> listVenues({EventListQuery? query});

  Future<Venue> getVenue(String id);

  Future<Venue> createVenue(VenueDraft draft);

  Future<Venue> updateVenue(String id, VenueDraft draft);

  Future<void> deleteVenue(String id);
}

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          createZoaDio(
            tokenStore: tokenStore ?? TokenStore(),
            baseUrl: BackendUri.backendUri,
          );

  final Dio _dio;

  @override
  Future<List<Event>> listEvents({EventListQuery? query}) async {
    try {
      final response = await _dio.get(
        BackendUri.events,
        queryParameters: query?.toQueryParameters(),
      );
      final data = _asMap(response.data);
      return _parseList(data['events'], Event.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> getEvent(String id) async {
    try {
      final response = await _dio.get('${BackendUri.events}/$id');
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> getEventBySlug(String slug) async {
    try {
      final response = await _dio.get('${BackendUri.events}/slug/$slug');
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Ticket>> listTickets(String eventId) async {
    try {
      final response = await _dio.get('${BackendUri.events}/$eventId/tickets');
      final data = _asMap(response.data);
      return _parseList(data['tickets'], Ticket.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> likeEvent(String id) async {
    try {
      await _dio.post('${BackendUri.events}/$id/like');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> createEvent(EventDraft draft) async {
    try {
      final response = await _dio.post(BackendUri.events, data: draft.toJson());
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> updateEvent(String id, EventDraft draft) async {
    try {
      final response = await _dio.put(
        '${BackendUri.events}/$id',
        data: draft.toJson(),
      );
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete('${BackendUri.events}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> publishEvent(String id) async {
    try {
      final response = await _dio.post('${BackendUri.events}/$id/publish');
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Event> unpublishEvent(String id) async {
    try {
      final response = await _dio.post('${BackendUri.events}/$id/unpublish');
      return Event.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Ticket> createTicket(String eventId, TicketDraft draft) async {
    try {
      final response = await _dio.post(
        '${BackendUri.events}/$eventId/tickets',
        data: draft.toJson(),
      );
      return Ticket.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Ticket> updateTicket(
    String eventId,
    String ticketId,
    TicketDraft draft,
  ) async {
    try {
      final response = await _dio.put(
        '${BackendUri.events}/$eventId/tickets/$ticketId',
        data: draft.toJson(),
      );
      return Ticket.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteTicket(String eventId, String ticketId) async {
    try {
      await _dio.delete('${BackendUri.events}/$eventId/tickets/$ticketId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<({Ticket ticket, int quantity})> purchaseTicket(
    String eventId,
    String ticketId,
    int quantity,
  ) async {
    try {
      final response = await _dio.post(
        '${BackendUri.events}/$eventId/tickets/$ticketId/purchase',
        data: PurchaseTicketRequest(quantity: quantity).toJson(),
      );
      final data = _asMap(response.data);
      return (
        ticket: Ticket.fromJson(_asMap(data['ticket'])),
        quantity: (data['quantity'] as num?)?.toInt() ?? quantity,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Venue>> listVenues({EventListQuery? query}) async {
    try {
      final response = await _dio.get(
        BackendUri.venues,
        queryParameters: query?.toQueryParameters(),
      );
      final data = _asMap(response.data);
      return _parseList(data['venues'], Venue.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Venue> getVenue(String id) async {
    try {
      final response = await _dio.get('${BackendUri.venues}/$id');
      return Venue.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Venue> createVenue(VenueDraft draft) async {
    try {
      final response = await _dio.post(BackendUri.venues, data: draft.toJson());
      return Venue.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Venue> updateVenue(String id, VenueDraft draft) async {
    try {
      final response = await _dio.put(
        '${BackendUri.venues}/$id',
        data: draft.toJson(),
      );
      return Venue.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteVenue(String id) async {
    try {
      await _dio.delete('${BackendUri.venues}/$id');
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