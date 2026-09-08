library;

/// Data models for the donjo_payment microservice (Transaction / Escrow /
/// Wallet).
///
/// Mirrors the JSON contract of:
///   backend/donjo_payment/internal/models/transaction.go

class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.transactionType,
    required this.amount,
    this.currency = 'KES',
    required this.paymentMethod,
    this.paymentChannel,
    this.status = TransactionStatus.pending,
    this.statusReason,
    this.mpesaReceipt,
    this.mpesaRequestId,
    this.mpesaCheckoutRequestId,
    this.mpesaPhoneNumber,
    this.walletBefore,
    this.walletAfter,
    this.platformFee = 0,
    this.processingFee = 0,
    this.netAmount = 0,
    this.reference,
    this.metadata,
    this.initiatedAt,
    this.completedAt,
    this.failedAt,
    this.createdAt,
    this.updatedAt,
    this.escrow,
  });

  final String id;
  final String userId;
  final String? bookingId;
  final String transactionType;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? paymentChannel;
  final String status;
  final String? statusReason;
  final String? mpesaReceipt;
  final String? mpesaRequestId;
  final String? mpesaCheckoutRequestId;
  final String? mpesaPhoneNumber;
  final double? walletBefore;
  final double? walletAfter;
  final double platformFee;
  final double processingFee;
  final double netAmount;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Escrow? escrow;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      transactionType: json['transaction_type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentChannel: json['payment_channel'] as String?,
      status: json['status'] as String? ?? TransactionStatus.pending,
      statusReason: json['status_reason'] as String?,
      mpesaReceipt: json['mpesa_receipt'] as String?,
      mpesaRequestId: json['mpesa_request_id'] as String?,
      mpesaCheckoutRequestId: json['mpesa_checkout_request_id'] as String?,
      mpesaPhoneNumber: json['mpesa_phone_number'] as String?,
      walletBefore: (json['wallet_before'] as num?)?.toDouble(),
      walletAfter: (json['wallet_after'] as num?)?.toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
      reference: json['reference'] as String?,
      metadata: json['metadata'] is Map
          ? (json['metadata'] as Map).cast<String, dynamic>()
          : null,
      initiatedAt: _parseDate(json['initiated_at']),
      completedAt: _parseDate(json['completed_at']),
      failedAt: _parseDate(json['failed_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      escrow: json['escrow'] is Map
          ? Escrow.fromJson((json['escrow'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (bookingId != null) 'booking_id': bookingId,
        'transaction_type': transactionType,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        if (paymentChannel != null) 'payment_channel': paymentChannel,
        'status': status,
        if (statusReason != null) 'status_reason': statusReason,
        if (mpesaReceipt != null) 'mpesa_receipt': mpesaReceipt,
        if (mpesaRequestId != null) 'mpesa_request_id': mpesaRequestId,
        if (mpesaCheckoutRequestId != null)
          'mpesa_checkout_request_id': mpesaCheckoutRequestId,
        if (mpesaPhoneNumber != null) 'mpesa_phone_number': mpesaPhoneNumber,
        if (walletBefore != null) 'wallet_before': walletBefore,
        if (walletAfter != null) 'wallet_after': walletAfter,
        'platform_fee': platformFee,
        'processing_fee': processingFee,
        'net_amount': netAmount,
        if (reference != null) 'reference': reference,
        if (metadata != null) 'metadata': metadata,
        if (initiatedAt != null)
          'initiated_at': initiatedAt!.toIso8601String(),
        if (completedAt != null)
          'completed_at': completedAt!.toIso8601String(),
        if (failedAt != null) 'failed_at': failedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (escrow != null) 'escrow': escrow!.toJson(),
      };
}

class Escrow {
  const Escrow({
    required this.id,
    required this.bookingId,
    required this.totalAmount,
    required this.platformFee,
    required this.organizerAmount,
    this.refundedAmount = 0,
    this.status = EscrowStatus.held,
    this.statusReason,
    this.releaseDate,
    this.releaseCondition = 'event_completed',
    this.releasedBy,
    this.disputeId,
    this.disputedAt,
    this.disputeResolution,
    this.refundId,
    this.refundedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final double totalAmount;
  final double platformFee;
  final double organizerAmount;
  final double refundedAmount;
  final String status;
  final String? statusReason;
  final DateTime? releaseDate;
  final String releaseCondition;
  final String? releasedBy;
  final String? disputeId;
  final DateTime? disputedAt;
  final String? disputeResolution;
  final String? refundId;
  final DateTime? refundedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Escrow.fromJson(Map<String, dynamic> json) {
    return Escrow(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      organizerAmount: (json['organizer_amount'] as num?)?.toDouble() ?? 0,
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? EscrowStatus.held,
      statusReason: json['status_reason'] as String?,
      releaseDate: _parseDate(json['release_date']),
      releaseCondition:
          json['release_condition'] as String? ?? 'event_completed',
      releasedBy: json['released_by'] as String?,
      disputeId: json['dispute_id'] as String?,
      disputedAt: _parseDate(json['disputed_at']),
      disputeResolution: json['dispute_resolution'] as String?,
      refundId: json['refund_id'] as String?,
      refundedAt: _parseDate(json['refunded_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'total_amount': totalAmount,
        'platform_fee': platformFee,
        'organizer_amount': organizerAmount,
        'refunded_amount': refundedAmount,
        'status': status,
        if (statusReason != null) 'status_reason': statusReason,
        if (releaseDate != null)
          'release_date': releaseDate!.toIso8601String(),
        'release_condition': releaseCondition,
        if (releasedBy != null) 'released_by': releasedBy,
        if (disputeId != null) 'dispute_id': disputeId,
        if (disputedAt != null)
          'disputed_at': disputedAt!.toIso8601String(),
        if (disputeResolution != null)
          'dispute_resolution': disputeResolution,
        if (refundId != null) 'refund_id': refundId,
        if (refundedAt != null)
          'refunded_at': refundedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.sourceType,
    this.sourceId,
    this.description,
    this.reference,
    this.status = WalletEntryStatus.completed,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? sourceType;
  final String? sourceId;
  final String? description;
  final String? reference;
  final String status;
  final DateTime? createdAt;

  factory WalletEntry.fromJson(Map<String, dynamic> json) {
    return WalletEntry(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? WalletEntryType.credit,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? WalletEntryStatus.completed,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'balance_after': balanceAfter,
        if (sourceType != null) 'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
        if (description != null) 'description': description,
        if (reference != null) 'reference': reference,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// String constants matching the donjo_payment backend values.
abstract final class TransactionType {
  static const purchase = 'purchase';
  static const refund = 'refund';
  static const walletDeposit = 'wallet_deposit';
  static const walletWithdrawal = 'wallet_withdrawal';
}

abstract final class TransactionStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const failed = 'failed';
  static const refunded = 'refunded';
}

abstract final class PaymentMethod {
  static const mpesa = 'mpesa';
  static const wallet = 'wallet';
}

abstract final class PaymentChannel {
  static const mpesaExpress = 'mpesa_express';
  static const wallet = 'wallet';
}

abstract final class EscrowStatus {
  static const held = 'held';
  static const released = 'released';
  static const disputed = 'disputed';
  static const refunded = 'refunded';
}

abstract final class WalletEntryType {
  static const credit = 'credit';
  static const debit = 'debit';
}

abstract final class WalletEntryStatus {
  static const completed = 'completed';
}
