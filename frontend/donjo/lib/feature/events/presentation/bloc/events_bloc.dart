library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/events/data/repositories/event_repository.dart';
import 'package:donjo/feature/events/presentation/bloc/events_event.dart';
import 'package:donjo/feature/events/presentation/bloc/events_state.dart';

export 'events_event.dart';
export 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({required this.eventRepository}) : super(const EventsState()) {
    on<EventsLoaded>(_onEventsLoaded);
    on<EventDetailLoaded>(_onEventDetailLoaded);
    on<EventTicketsLoaded>(_onEventTicketsLoaded);
    on<EventLiked>(_onEventLiked);
    on<EventCreated>(_onEventCreated);
    on<EventUpdated>(_onEventUpdated);
    on<EventDeleted>(_onEventDeleted);
    on<EventPublished>(_onEventPublished);
    on<EventUnpublished>(_onEventUnpublished);
    on<EventTicketCreated>(_onEventTicketCreated);
    on<EventTicketUpdated>(_onEventTicketUpdated);
    on<EventTicketDeleted>(_onEventTicketDeleted);
    on<EventTicketPurchased>(_onEventTicketPurchased);
    on<VenuesLoaded>(_onVenuesLoaded);
    on<VenueDetailLoaded>(_onVenueDetailLoaded);
    on<VenueCreated>(_onVenueCreated);
    on<VenueUpdated>(_onVenueUpdated);
    on<VenueDeleted>(_onVenueDeleted);
    on<EventsErrorCleared>(_onErrorCleared);
  }

  final EventRepository eventRepository;

  Future<void> _onEventsLoaded(
    EventsLoaded event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final events = await eventRepository.listEvents(query: event.query);
      emit(state.copyWith(status: EventsStatus.loaded, events: events));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventDetailLoaded(
    EventDetailLoaded event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final selectedEvent = event.bySlug
          ? await eventRepository.getEventBySlug(event.id)
          : await eventRepository.getEvent(event.id);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedEvent: selectedEvent,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventTicketsLoaded(
    EventTicketsLoaded event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final tickets = await eventRepository.listTickets(event.eventId);
      emit(state.copyWith(status: EventsStatus.loaded, tickets: tickets));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventLiked(
    EventLiked event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await eventRepository.likeEvent(event.id);
      emit(state.copyWith(message: 'Event liked'));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: EventsError(message: e.toString())));
    }
  }

  Future<void> _onEventCreated(
    EventCreated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final created = await eventRepository.createEvent(event.draft);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedEvent: created,
          events: [created, ...state.events],
          message: 'Event created',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventUpdated(
    EventUpdated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final updated = await eventRepository.updateEvent(event.id, event.draft);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedEvent: updated,
          message: 'Event updated',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventDeleted(
    EventDeleted event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      await eventRepository.deleteEvent(event.id);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          events: state.events
              .where((e) => e.id != event.id)
              .toList(),
          message: 'Event deleted',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventPublished(
    EventPublished event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final updated = await eventRepository.publishEvent(event.id);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedEvent: updated,
          message: 'Event published',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventUnpublished(
    EventUnpublished event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final updated = await eventRepository.unpublishEvent(event.id);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedEvent: updated,
          message: 'Event unpublished',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventTicketCreated(
    EventTicketCreated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final created = await eventRepository.createTicket(
        event.eventId,
        event.draft,
      );
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          tickets: [...state.tickets, created],
          message: 'Ticket created',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventTicketUpdated(
    EventTicketUpdated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final updated = await eventRepository.updateTicket(
        event.eventId,
        event.ticketId,
        event.draft,
      );
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          tickets: state.tickets
              .map((t) => t.id == event.ticketId ? updated : t)
              .toList(),
          message: 'Ticket updated',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventTicketDeleted(
    EventTicketDeleted event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      await eventRepository.deleteTicket(event.eventId, event.ticketId);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          tickets: state.tickets
              .where((t) => t.id != event.ticketId)
              .toList(),
          message: 'Ticket deleted',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEventTicketPurchased(
    EventTicketPurchased event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final result = await eventRepository.purchaseTicket(
        event.eventId,
        event.ticketId,
        event.quantity,
      );
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          message: 'Purchase confirmed',
          tickets: state.tickets
              .map((t) => t.id == event.ticketId ? result.ticket : t)
              .toList(),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onVenuesLoaded(
    VenuesLoaded event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final venues = await eventRepository.listVenues(query: event.query);
      emit(state.copyWith(status: EventsStatus.loaded, venues: venues));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onVenueDetailLoaded(
    VenueDetailLoaded event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final venue = await eventRepository.getVenue(event.id);
      emit(state.copyWith(status: EventsStatus.loaded, selectedVenue: venue));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onVenueCreated(
    VenueCreated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final created = await eventRepository.createVenue(event.draft);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedVenue: created,
          venues: [created, ...state.venues],
          message: 'Venue created',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onVenueUpdated(
    VenueUpdated event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      final updated = await eventRepository.updateVenue(event.id, event.draft);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          selectedVenue: updated,
          message: 'Venue updated',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onVenueDeleted(
    VenueDeleted event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    try {
      await eventRepository.deleteVenue(event.id);
      emit(
        state.copyWith(
          status: EventsStatus.loaded,
          venues: state.venues.where((v) => v.id != event.id).toList(),
          message: 'Venue deleted',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          error: EventsError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(EventsErrorCleared event, Emitter<EventsState> emit) {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }
}