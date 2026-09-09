# Payments

Transactions, escrows and the wallet balance backing ticket purchases.

## Backend

Talks to the **payments** microservice through the gateway:

- `GET /api/v1/transactions`, `GET /api/v1/transactions/:id`
- `GET /api/v1/escrows`, `GET /api/v1/escrows/:id`
- `GET /api/v1/wallet` (entries + balance)

## Layout

```
lib/feature/payments/
├── data/
│   ├── models/payment_models.dart
│   └── repositories/payment_repository.dart
└── presentation/bloc/                   # payments_event / payments_state / payments_bloc
```

## How it works

1. UI dispatches `TransactionsLoaded`, `TransactionDetailRequested`,
   `EscrowsLoaded`, `WalletLoaded`.
2. `PaymentsBloc` calls `PaymentRepository` for each and emits
   `PaymentsStatus.loading → loaded/failure`.
3. State holds the transaction/escrow lists and the wallet (`WalletEntry` list);
   the `walletBalance` getter derives the current balance from the latest entry's
   `balanceAfter`.
4. Escrow state covers pending/released/cancelled/refunded, mirroring the
   lifecycle of ticket purchases and resale settlements.