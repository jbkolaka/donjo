library;

import 'package:donjo/feature/bookings/data/models/booking_models.dart';

sealed class BookingsEvent {
  const BookingsEvent();
}

final class MyBookingsLoaded extends BookingsEvent {
  const MyBookingsLoaded();
}

final class BookingDetailLoaded extends BookingsEvent {
  const BookingDetailLoaded({required this.id});
  final String id;
}

final class MyInstancesLoaded extends BookingsEvent {
  const MyInstancesLoaded();
}

final class MarketplaceLoaded extends BookingsEvent {
  const MarketplaceLoaded();
}

final class InstanceAssigned extends BookingsEvent {
  const InstanceAssigned({required this.instanceId, required this.request});
  final String instanceId;
  final AssignTicketRequest request;
}

final class TicketShared extends BookingsEvent {
  const TicketShared({required this.instanceId, required this.email});
  final String instanceId;
  final String email;
}

final class ShareCancelled extends BookingsEvent {
  const ShareCancelled({required this.instanceId});
  final String instanceId;
}

final class ResaleListed extends BookingsEvent {
  const ResaleListed({required this.instanceId, required this.price});
  final String instanceId;
  final double price;
}

final class ResaleUnlisted extends BookingsEvent {
  const ResaleUnlisted({required this.instanceId});
  final String instanceId;
}

final class ResaleBought extends BookingsEvent {
  const ResaleBought({required this.instanceId});
  final String instanceId;
}

final class TicketClaimed extends BookingsEvent {
  const TicketClaimed({required this.email, this.code});
  final String email;
  final String? code;
}

final class CheckinPerformed extends BookingsEvent {
  const CheckinPerformed({required this.code, this.location});
  final String code;
  final String? location;
}

final class WaitlistJoined extends BookingsEvent {
  const WaitlistJoined({required this.request});
  final WaitlistSignupRequest request;
}

final class WaitlistLeft extends BookingsEvent {
  const WaitlistLeft({required this.eventId});
  final String eventId;
}

final class WaitlistLoaded extends BookingsEvent {
  const WaitlistLoaded({required this.eventId});
  final String eventId;
}

final class ScanLocationsLoaded extends BookingsEvent {
  const ScanLocationsLoaded({required this.eventId});
  final String eventId;
}

final class ScanLocationCreated extends BookingsEvent {
  const ScanLocationCreated({required this.payload});
  final Map<String, dynamic> payload;
}

final class BookingsErrorCleared extends BookingsEvent {
  const BookingsErrorCleared();
}