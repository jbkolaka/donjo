library;

sealed class PaymentsEvent {
  const PaymentsEvent();
}

final class MyTransactionsLoaded extends PaymentsEvent {
  const MyTransactionsLoaded();
}

final class TransactionDetailLoaded extends PaymentsEvent {
  const TransactionDetailLoaded({required this.id});
  final String id;
}

final class EscrowDetailLoaded extends PaymentsEvent {
  const EscrowDetailLoaded({required this.id});
  final String id;
}

final class WalletLoaded extends PaymentsEvent {
  const WalletLoaded();
}

final class PaymentsErrorCleared extends PaymentsEvent {
  const PaymentsErrorCleared();
}