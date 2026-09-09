library;

import 'package:donjo/feature/payments/data/models/payment_models.dart';

enum PaymentsStatus {
  initial,
  loading,
  loaded,
  failure,
}

class PaymentsError {
  const PaymentsError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class PaymentsState {
  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.transactions = const [],
    this.selectedTransaction,
    this.selectedEscrow,
    this.walletEntries = const [],
    this.error,
    this.message,
  });

  final PaymentsStatus status;
  final List<Transaction> transactions;
  final Transaction? selectedTransaction;
  final Escrow? selectedEscrow;
  final List<WalletEntry> walletEntries;
  final PaymentsError? error;
  final String? message;

  bool get busy => status == PaymentsStatus.loading;
  double? get walletBalance =>
      walletEntries.isEmpty ? null : walletEntries.last.balanceAfter;

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Transaction>? transactions,
    Transaction? selectedTransaction,
    bool clearSelectedTransaction = false,
    Escrow? selectedEscrow,
    bool clearSelectedEscrow = false,
    List<WalletEntry>? walletEntries,
    PaymentsError? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return PaymentsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      selectedTransaction: clearSelectedTransaction
          ? null
          : selectedTransaction ?? this.selectedTransaction,
      selectedEscrow: clearSelectedEscrow
          ? null
          : selectedEscrow ?? this.selectedEscrow,
      walletEntries: walletEntries ?? this.walletEntries,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}