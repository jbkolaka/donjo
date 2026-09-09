library;

import 'package:donjo/feature/events/data/models/event_models.dart';
import 'package:donjo/feature/events/data/repositories/event_repository.dart';

sealed class EventsEvent {
  const EventsEvent();
}

/// Load (and refresh) the event catalogue.
final class EventsLoaded extends EventsEvent {
  const EventsLoaded({this.query});
  final EventListQuery? query;
}

/// Load a single event and its tickets.
final class EventDetailLoaded extends EventsEvent {
  const EventDetailLoaded({required this.id, this.bySlug = false});
  final String id;
  final bool bySlug;
}

/// Load the ticket list for an event.
final class EventTicketsLoaded extends EventsEvent {
  const EventTicketsLoaded({required this.eventId});
  final String eventId;
}

final class EventLiked extends EventsEvent {
  const EventLiked({required this.id});
  final String id;
}

final class EventCreated extends EventsEvent {
  const EventCreated({required this.draft});
  final EventDraft draft;
}

final class EventUpdated extends EventsEvent {
  const EventUpdated({required this.id, required this.draft});
  final String id;
  final EventDraft draft;
}

final class EventDeleted extends EventsEvent {
  const EventDeleted({required this.id});
  final String id;
}

final class EventPublished extends EventsEvent {
  const EventPublished({required this.id});
  final String id;
}

final class EventUnpublished extends EventsEvent {
  const EventUnpublished({required this.id});
  final String id;
}

final class EventTicketCreated extends EventsEvent {
  const EventTicketCreated({required this.eventId, required this.draft});
  final String eventId;
  final TicketDraft draft;
}

final class EventTicketUpdated extends EventsEvent {
  const EventTicketUpdated({
    required this.eventId,
    required this.ticketId,
    required this.draft,
  });
  final String eventId;
  final String ticketId;
  final TicketDraft draft;
}

final class EventTicketDeleted extends EventsEvent {
  const EventTicketDeleted({required this.eventId, required this.ticketId});
  final String eventId;
  final String ticketId;
}

final class EventTicketPurchased extends EventsEvent {
  const EventTicketPurchased({
    required this.eventId,
    required this.ticketId,
    required this.quantity,
  });
  final String eventId;
  final String ticketId;
  final int quantity;
}

/// Load (and refresh) the venue catalogue.
final class VenuesLoaded extends EventsEvent {
  const VenuesLoaded({this.query});
  final EventListQuery? query;
}

final class VenueDetailLoaded extends EventsEvent {
  const VenueDetailLoaded({required this.id});
  final String id;
}

final class VenueCreated extends EventsEvent {
  const VenueCreated({required this.draft});
  final VenueDraft draft;
}

final class VenueUpdated extends EventsEvent {
  const VenueUpdated({required this.id, required this.draft});
  final String id;
  final VenueDraft draft;
}

final class VenueDeleted extends EventsEvent {
  const VenueDeleted({required this.id});
  final String id;
}

/// Clears any transient error message.
final class EventsErrorCleared extends EventsEvent {
  const EventsErrorCleared();
}