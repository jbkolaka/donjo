library;

import 'package:donjo/feature/bookings/data/models/booking_models.dart';

enum BookingsStatus {
  initial,
  loading,
  loaded,
  failure,
}

class BookingsError {
  const BookingsError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class BookingsState {
  const BookingsState({
    this.status = BookingsStatus.initial,
    this.bookings = const [],
    this.instances = const [],
    this.marketplace = const [],
    this.selectedBooking,
    this.selectedInstance,
    this.waitlistEntries = const [],
    this.waitlistCount = 0,
    this.scanLocations = const [],
    this.checkinResult,
    this.error,
    this.message,
  });

  final BookingsStatus status;
  final List<Booking> bookings;
  final List<TicketInstance> instances;
  final List<TicketInstance> marketplace;
  final Booking? selectedBooking;
  final TicketInstance? selectedInstance;
  final List<WaitlistEntry> waitlistEntries;
  final int waitlistCount;
  final List<ScanLocation> scanLocations;
  final CheckinResult? checkinResult;
  final BookingsError? error;
  final String? message;

  bool get busy => status == BookingsStatus.loading;

  BookingsState copyWith({
    BookingsStatus? status,
    List<Booking>? bookings,
    List<TicketInstance>? instances,
    List<TicketInstance>? marketplace,
    Booking? selectedBooking,
    bool clearSelectedBooking = false,
    TicketInstance? selectedInstance,
    bool clearSelectedInstance = false,
    List<WaitlistEntry>? waitlistEntries,
    int? waitlistCount,
    List<ScanLocation>? scanLocations,
    CheckinResult? checkinResult,
    bool clearCheckinResult = false,
    BookingsError? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return BookingsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      instances: instances ?? this.instances,
      marketplace: marketplace ?? this.marketplace,
      selectedBooking: clearSelectedBooking
          ? null
          : selectedBooking ?? this.selectedBooking,
      selectedInstance: clearSelectedInstance
          ? null
          : selectedInstance ?? this.selectedInstance,
      waitlistEntries: waitlistEntries ?? this.waitlistEntries,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      scanLocations: scanLocations ?? this.scanLocations,
      checkinResult: clearCheckinResult
          ? null
          : checkinResult ?? this.checkinResult,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}