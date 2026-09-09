library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/bookings/data/repositories/booking_repository.dart';
import 'package:donjo/feature/bookings/presentation/bloc/bookings_event.dart';
import 'package:donjo/feature/bookings/presentation/bloc/bookings_state.dart';

export 'bookings_event.dart';
export 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  BookingsBloc({required this.bookingRepository})
    : super(const BookingsState()) {
    on<MyBookingsLoaded>(_onMyBookingsLoaded);
    on<BookingDetailLoaded>(_onBookingDetailLoaded);
    on<MyInstancesLoaded>(_onMyInstancesLoaded);
    on<MarketplaceLoaded>(_onMarketplaceLoaded);
    on<InstanceAssigned>(_onInstanceAssigned);
    on<TicketShared>(_onTicketShared);
    on<ShareCancelled>(_onShareCancelled);
    on<ResaleListed>(_onResaleListed);
    on<ResaleUnlisted>(_onResaleUnlisted);
    on<ResaleBought>(_onResaleBought);
    on<TicketClaimed>(_onTicketClaimed);
    on<CheckinPerformed>(_onCheckinPerformed);
    on<WaitlistJoined>(_onWaitlistJoined);
    on<WaitlistLeft>(_onWaitlistLeft);
    on<WaitlistLoaded>(_onWaitlistLoaded);
    on<ScanLocationsLoaded>(_onScanLocationsLoaded);
    on<ScanLocationCreated>(_onScanLocationCreated);
    on<BookingsErrorCleared>(_onErrorCleared);
  }

  final BookingRepository bookingRepository;

  Future<void> _onMyBookingsLoaded(
    MyBookingsLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final bookings = await bookingRepository.listMyBookings();
      emit(state.copyWith(status: BookingsStatus.loaded, bookings: bookings));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onBookingDetailLoaded(
    BookingDetailLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final booking = await bookingRepository.bookingDetail(event.id);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedBooking: booking,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onMyInstancesLoaded(
    MyInstancesLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instances = await bookingRepository.listMyInstances();
      emit(
        state.copyWith(status: BookingsStatus.loaded, instances: instances),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onMarketplaceLoaded(
    MarketplaceLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final marketplace = await bookingRepository.marketplace();
      emit(
        state.copyWith(status: BookingsStatus.loaded, marketplace: marketplace),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onInstanceAssigned(
    InstanceAssigned event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.assignHolder(
        event.instanceId,
        event.request,
      );
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Ticket assigned',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onTicketShared(
    TicketShared event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.shareTicket(
        event.instanceId,
        event.email,
      );
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Ticket offered to ${event.email}',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onShareCancelled(
    ShareCancelled event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.cancelShare(event.instanceId);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Offer withdrawn',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onResaleListed(
    ResaleListed event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.listForResale(
        event.instanceId,
        event.price,
      );
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Listed for resale',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onResaleUnlisted(
    ResaleUnlisted event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.unlistResale(event.instanceId);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Resale unlisted',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onResaleBought(
    ResaleBought event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.buyResale(event.instanceId);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Resale ticket purchased',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onTicketClaimed(
    TicketClaimed event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final instance = await bookingRepository.claimTicket(
        event.email,
        code: event.code,
      );
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          selectedInstance: instance,
          message: 'Ticket claimed',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onCheckinPerformed(
    CheckinPerformed event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final result = await bookingRepository.checkin(
        event.code,
        location: event.location,
      );
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          checkinResult: result,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onWaitlistJoined(
    WaitlistJoined event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      await bookingRepository.joinWaitlist(event.request);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          message: 'Added to the waitlist',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onWaitlistLeft(
    WaitlistLeft event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      await bookingRepository.leaveWaitlist(eventId: event.eventId);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          message: 'Left the waitlist',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onWaitlistLoaded(
    WaitlistLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final result = await bookingRepository.waitlist(eventId: event.eventId);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          waitlistEntries: result.entries,
          waitlistCount: result.count,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onScanLocationsLoaded(
    ScanLocationsLoaded event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final result = await bookingRepository.scanLocations(
        eventId: event.eventId,
      );
      emit(
        state.copyWith(status: BookingsStatus.loaded, scanLocations: result.locations),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onScanLocationCreated(
    ScanLocationCreated event,
    Emitter<BookingsState> emit,
  ) async {
    emit(state.copyWith(status: BookingsStatus.loading, clearError: true));
    try {
      final location = await bookingRepository.createScanLocation(event.payload);
      emit(
        state.copyWith(
          status: BookingsStatus.loaded,
          scanLocations: [...state.scanLocations, location],
          message: 'Scan location created',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingsStatus.failure,
          error: BookingsError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(BookingsErrorCleared event, Emitter<BookingsState> emit) {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }
}