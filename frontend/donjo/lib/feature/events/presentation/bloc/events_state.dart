library;

import 'package:donjo/feature/events/data/models/event_models.dart';

enum EventsStatus {
  initial,
  loading,
  loaded,
  failure,
}

class EventsError {
  const EventsError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class EventsState {
  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.venues = const [],
    this.tickets = const [],
    this.selectedEvent,
    this.selectedVenue,
    this.error,
    this.message,
  });

  final EventsStatus status;
  final List<Event> events;
  final List<Venue> venues;
  final List<Ticket> tickets;
  final Event? selectedEvent;
  final Venue? selectedVenue;
  final EventsError? error;
  final String? message;

  bool get busy => status == EventsStatus.loading;

  EventsState copyWith({
    EventsStatus? status,
    List<Event>? events,
    List<Venue>? venues,
    List<Ticket>? tickets,
    Event? selectedEvent,
    bool clearSelectedEvent = false,
    Venue? selectedVenue,
    bool clearSelectedVenue = false,
    EventsError? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      venues: venues ?? this.venues,
      tickets: tickets ?? this.tickets,
      selectedEvent: clearSelectedEvent ? null : selectedEvent ?? this.selectedEvent,
      selectedVenue: clearSelectedVenue
          ? null
          : selectedVenue ?? this.selectedVenue,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}