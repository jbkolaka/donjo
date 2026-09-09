library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/payments/data/repositories/payment_repository.dart';
import 'package:donjo/feature/payments/presentation/bloc/payments_event.dart';
import 'package:donjo/feature/payments/presentation/bloc/payments_state.dart';

export 'payments_event.dart';
export 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  PaymentsBloc({required this.paymentRepository})
    : super(const PaymentsState()) {
    on<MyTransactionsLoaded>(_onMyTransactionsLoaded);
    on<TransactionDetailLoaded>(_onTransactionDetailLoaded);
    on<EscrowDetailLoaded>(_onEscrowDetailLoaded);
    on<WalletLoaded>(_onWalletLoaded);
    on<PaymentsErrorCleared>(_onErrorCleared);
  }

  final PaymentRepository paymentRepository;

  Future<void> _onMyTransactionsLoaded(
    MyTransactionsLoaded event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(state.copyWith(status: PaymentsStatus.loading, clearError: true));
    try {
      final transactions = await paymentRepository.listMyTransactions();
      emit(
        state.copyWith(status: PaymentsStatus.loaded, transactions: transactions),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onTransactionDetailLoaded(
    TransactionDetailLoaded event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(state.copyWith(status: PaymentsStatus.loading, clearError: true));
    try {
      final transaction = await paymentRepository.transactionDetail(event.id);
      emit(
        state.copyWith(
          status: PaymentsStatus.loaded,
          selectedTransaction: transaction,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onEscrowDetailLoaded(
    EscrowDetailLoaded event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(state.copyWith(status: PaymentsStatus.loading, clearError: true));
    try {
      final escrow = await paymentRepository.escrowDetail(event.id);
      emit(
        state.copyWith(
          status: PaymentsStatus.loaded,
          selectedEscrow: escrow,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onWalletLoaded(
    WalletLoaded event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(state.copyWith(status: PaymentsStatus.loading, clearError: true));
    try {
      final entries = await paymentRepository.myWallet();
      emit(
        state.copyWith(status: PaymentsStatus.loaded, walletEntries: entries),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          error: PaymentsError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(PaymentsErrorCleared event, Emitter<PaymentsState> emit) {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }
}