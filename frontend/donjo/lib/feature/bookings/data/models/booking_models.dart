library;

/// Data models for the donjo_booking microservice (Booking / TicketInstance /
/// ScanLocation / Waitlist / Check-in).
///
/// Mirrors the JSON contract of:
///   backend/donjo_booking/internal/models/booking.go
///   backend/donjo_booking/internal/models/instance.go
///   backend/donjo_booking/internal/models/misc.go
///   backend/donjo_booking/internal/bookingservice/service.go (CheckinResult)

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    this.eventSlug,
    required this.ticketId,
    required this.bookingReference,
    this.orderNumber,
    required this.ticketType,
    required this.ticketName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.serviceFee,
    required this.processingFee,
    required this.platformFee,
    required this.netAmount,
    this.paymentMethod = PaymentMethodMpesa.mpesa,
    this.paymentStatus = BookingPaymentStatus.paid,
    this.paymentDate,
    this.transactionId,
    this.escrowId,
    this.escrowStatus,
    this.status = BookingStatus.confirmed,
    this.statusReason,
    this.attendeeName,
    this.attendeeEmail,
    this.attendeePhone,
    this.attendeeNotes,
    this.customAnswers,
    this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.completedAt,
    this.instances = const [],
  });

  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final String? eventSlug;
  final String ticketId;
  final String bookingReference;
  final String? orderNumber;
  final String ticketType;
  final String ticketName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double serviceFee;
  final double processingFee;
  final double platformFee;
  final double netAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String? transactionId;
  final String? escrowId;
  final String? escrowStatus;
  final String status;
  final String? statusReason;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? attendeePhone;
  final String? attendeeNotes;
  final String? customAnswers;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final List<TicketInstance> instances;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      eventTitle: json['event_title'] as String? ?? '',
      eventSlug: json['event_slug'] as String?,
      ticketId: json['ticket_id'] as String? ?? '',
      bookingReference: json['booking_reference'] as String? ?? '',
      orderNumber: json['order_number'] as String?,
      ticketType: json['ticket_type'] as String? ?? '',
      ticketName: json['ticket_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod:
          json['payment_method'] as String? ?? PaymentMethodMpesa.mpesa,
      paymentStatus:
          json['payment_status'] as String? ?? BookingPaymentStatus.paid,
      paymentDate: _parseDate(json['payment_date']),
      transactionId: json['transaction_id'] as String?,
      escrowId: json['escrow_id'] as String?,
      escrowStatus: json['escrow_status'] as String?,
      status: json['status'] as String? ?? BookingStatus.confirmed,
      statusReason: json['status_reason'] as String?,
      attendeeName: json['attendee_name'] as String?,
      attendeeEmail: json['attendee_email'] as String?,
      attendeePhone: json['attendee_phone'] as String?,
      attendeeNotes: json['attendee_notes'] as String?,
      customAnswers: json['custom_answers'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      completedAt: _parseDate(json['completed_at']),
      instances: json['instances'] is List
          ? (json['instances'] as List)
              .whereType<Map>()
              .map((e) => TicketInstance.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'event_title': eventTitle,
        if (eventSlug != null) 'event_slug': eventSlug,
        'ticket_id': ticketId,
        'booking_reference': bookingReference,
        if (orderNumber != null) 'order_number': orderNumber,
        'ticket_type': ticketType,
        'ticket_name': ticketName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_amount': totalAmount,
        'service_fee': serviceFee,
        'processing_fee': processingFee,
        'platform_fee': platformFee,
        'net_amount': netAmount,
        if (paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        if (paymentDate != null)
          'payment_date': paymentDate!.toIso8601String(),
        if (transactionId != null) 'transaction_id': transactionId,
        if (escrowId != null) 'escrow_id': escrowId,
        if (escrowStatus != null) 'escrow_status': escrowStatus,
        'status': status,
        if (statusReason != null) 'status_reason': statusReason,
        if (attendeeName != null) 'attendee_name': attendeeName,
        if (attendeeEmail != null) 'attendee_email': attendeeEmail,
        if (attendeePhone != null) 'attendee_phone': attendeePhone,
        if (attendeeNotes != null) 'attendee_notes': attendeeNotes,
        if (customAnswers != null) 'custom_answers': customAnswers,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (cancelledAt != null)
          'cancelled_at': cancelledAt!.toIso8601String(),
        if (completedAt != null)
          'completed_at': completedAt!.toIso8601String(),
        if (instances.isNotEmpty)
          'instances': instances.map((i) => i.toJson()).toList(),
      };
}

class TicketInstance {
  const TicketInstance({
    required this.id,
    required this.bookingId,
    required this.ticketId,
    required this.eventId,
    required this.userId,
    this.ticketCode,
    this.qrData,
    this.qrImageUrl,
    this.barcode,
    this.holderName,
    this.holderEmail,
    this.holderPhone,
    this.status = TicketInstanceStatus.active,
    this.usedAt,
    this.usedBy,
    this.transferAllowed = true,
    this.transferred = false,
    this.transferredFrom,
    this.transferredTo,
    this.transferredAt,
    this.transferCode,
    this.listedPrice,
    this.listedAt,
    this.unlistedAt,
    this.resoldPrice,
    this.resoldAt,
    this.checkedIn = false,
    this.checkedInAt,
    this.checkedInBy,
    this.scanCount = 0,
    this.lastScannedAt,
    this.vipAccess = false,
    this.specialNotes,
    this.isValid = true,
    this.invalidationReason,
    this.createdAt,
    this.updatedAt,
    this.eventTitle,
    this.eventSlug,
    this.ticketType,
    this.ticketName,
    this.bookingReference,
  });

  final String id;
  final String bookingId;
  final String ticketId;
  final String eventId;
  final String userId;
  final String? ticketCode;
  final String? qrData;
  final String? qrImageUrl;
  final String? barcode;
  final String? holderName;
  final String? holderEmail;
  final String? holderPhone;
  final String status;
  final DateTime? usedAt;
  final String? usedBy;
  final bool transferAllowed;
  final bool transferred;
  final String? transferredFrom;
  final String? transferredTo;
  final DateTime? transferredAt;
  final String? transferCode;
  final double? listedPrice;
  final DateTime? listedAt;
  final DateTime? unlistedAt;
  final double? resoldPrice;
  final DateTime? resoldAt;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final String? checkedInBy;
  final int scanCount;
  final DateTime? lastScannedAt;
  final bool vipAccess;
  final String? specialNotes;
  final bool isValid;
  final String? invalidationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? eventTitle;
  final String? eventSlug;
  final String? ticketType;
  final String? ticketName;
  final String? bookingReference;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory TicketInstance.fromJson(Map<String, dynamic> json) {
    return TicketInstance(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      ticketCode: json['ticket_code'] as String?,
      qrData: json['qr_data'] as String?,
      qrImageUrl: json['qr_image_url'] as String?,
      barcode: json['barcode'] as String?,
      holderName: json['holder_name'] as String?,
      holderEmail: json['holder_email'] as String?,
      holderPhone: json['holder_phone'] as String?,
      status: json['status'] as String? ?? TicketInstanceStatus.active,
      usedAt: _parseDate(json['used_at']),
      usedBy: json['used_by'] as String?,
      transferAllowed: json['transfer_allowed'] as bool? ?? true,
      transferred: json['transferred'] as bool? ?? false,
      transferredFrom: json['transferred_from'] as String?,
      transferredTo: json['transferred_to'] as String?,
      transferredAt: _parseDate(json['transferred_at']),
      transferCode: json['transfer_code'] as String?,
      listedPrice: (json['listed_price'] as num?)?.toDouble(),
      listedAt: _parseDate(json['listed_at']),
      unlistedAt: _parseDate(json['unlisted_at']),
      resoldPrice: (json['resold_price'] as num?)?.toDouble(),
      resoldAt: _parseDate(json['resold_at']),
      checkedIn: json['checked_in'] as bool? ?? false,
      checkedInAt: _parseDate(json['checked_in_at']),
      checkedInBy: json['checked_in_by'] as String?,
      scanCount: (json['scan_count'] as num?)?.toInt() ?? 0,
      lastScannedAt: _parseDate(json['last_scanned_at']),
      vipAccess: json['vip_access'] as bool? ?? false,
      specialNotes: json['special_notes'] as String?,
      isValid: json['is_valid'] as bool? ?? true,
      invalidationReason: json['invalidation_reason'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      eventTitle: json['event_title'] as String?,
      eventSlug: json['event_slug'] as String?,
      ticketType: json['ticket_type'] as String?,
      ticketName: json['ticket_name'] as String?,
      bookingReference: json['booking_reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'ticket_id': ticketId,
        'event_id': eventId,
        'user_id': userId,
        if (ticketCode != null) 'ticket_code': ticketCode,
        if (qrData != null) 'qr_data': qrData,
        if (qrImageUrl != null) 'qr_image_url': qrImageUrl,
        if (barcode != null) 'barcode': barcode,
        if (holderName != null) 'holder_name': holderName,
        if (holderEmail != null) 'holder_email': holderEmail,
        if (holderPhone != null) 'holder_phone': holderPhone,
        'status': status,
        if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
        if (usedBy != null) 'used_by': usedBy,
        'transfer_allowed': transferAllowed,
        'transferred': transferred,
        if (transferredFrom != null) 'transferred_from': transferredFrom,
        if (transferredTo != null) 'transferred_to': transferredTo,
        if (transferredAt != null)
          'transferred_at': transferredAt!.toIso8601String(),
        if (transferCode != null) 'transfer_code': transferCode,
        if (listedPrice != null) 'listed_price': listedPrice,
        if (listedAt != null) 'listed_at': listedAt!.toIso8601String(),
        if (unlistedAt != null) 'unlisted_at': unlistedAt!.toIso8601String(),
        if (resoldPrice != null) 'resold_price': resoldPrice,
        if (resoldAt != null) 'resold_at': resoldAt!.toIso8601String(),
        'checked_in': checkedIn,
        if (checkedInAt != null)
          'checked_in_at': checkedInAt!.toIso8601String(),
        if (checkedInBy != null) 'checked_in_by': checkedInBy,
        'scan_count': scanCount,
        if (lastScannedAt != null)
          'last_scanned_at': lastScannedAt!.toIso8601String(),
        'vip_access': vipAccess,
        if (specialNotes != null) 'special_notes': specialNotes,
        'is_valid': isValid,
        if (invalidationReason != null)
          'invalidation_reason': invalidationReason,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (eventTitle != null) 'event_title': eventTitle,
        if (eventSlug != null) 'event_slug': eventSlug,
        if (ticketType != null) 'ticket_type': ticketType,
        if (ticketName != null) 'ticket_name': ticketName,
        if (bookingReference != null) 'booking_reference': bookingReference,
      };
}

class QRScanLog {
  const QRScanLog({
    required this.id,
    required this.ticketInstanceId,
    required this.eventId,
    required this.bookingId,
    required this.scannerId,
    required this.userId,
    required this.scanType,
    required this.scanResult,
    this.qrCodeScanned,
    this.scanLocation,
    this.scanLocationName,
    this.scanIp,
    this.scanDeviceInfo,
    this.scannerDeviceId,
    this.scannerAppVersion,
    this.responseMessage,
    this.responseCode,
    this.ticketStatusBefore,
    this.ticketStatusAfter,
    this.metadata,
    this.createdAt,
  });

  final String id;
  final String ticketInstanceId;
  final String eventId;
  final String bookingId;
  final String scannerId;
  final String userId;
  final String scanType;
  final String scanResult;
  final String? qrCodeScanned;
  final String? scanLocation;
  final String? scanLocationName;
  final String? scanIp;
  final String? scanDeviceInfo;
  final String? scannerDeviceId;
  final String? scannerAppVersion;
  final String? responseMessage;
  final String? responseCode;
  final String? ticketStatusBefore;
  final String? ticketStatusAfter;
  final String? metadata;
  final DateTime? createdAt;

  factory QRScanLog.fromJson(Map<String, dynamic> json) {
    return QRScanLog(
      id: json['id'] as String? ?? '',
      ticketInstanceId: json['ticket_instance_id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      scannerId: json['scanner_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      scanType: json['scan_type'] as String? ?? '',
      scanResult: json['scan_result'] as String? ?? '',
      qrCodeScanned: json['qr_code_scanned'] as String?,
      scanLocation: json['scan_location'] as String?,
      scanLocationName: json['scan_location_name'] as String?,
      scanIp: json['scan_ip'] as String?,
      scanDeviceInfo: json['scan_device_info'] as String?,
      scannerDeviceId: json['scanner_device_id'] as String?,
      scannerAppVersion: json['scanner_app_version'] as String?,
      responseMessage: json['response_message'] as String?,
      responseCode: json['response_code'] as String?,
      ticketStatusBefore: json['ticket_status_before'] as String?,
      ticketStatusAfter: json['ticket_status_after'] as String?,
      metadata: json['metadata'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_instance_id': ticketInstanceId,
        'event_id': eventId,
        'booking_id': bookingId,
        'scanner_id': scannerId,
        'user_id': userId,
        'scan_type': scanType,
        'scan_result': scanResult,
        if (qrCodeScanned != null) 'qr_code_scanned': qrCodeScanned,
        if (scanLocation != null) 'scan_location': scanLocation,
        if (scanLocationName != null)
          'scan_location_name': scanLocationName,
        if (scanIp != null) 'scan_ip': scanIp,
        if (scanDeviceInfo != null) 'scan_device_info': scanDeviceInfo,
        if (scannerDeviceId != null) 'scanner_device_id': scannerDeviceId,
        if (scannerAppVersion != null)
          'scanner_app_version': scannerAppVersion,
        if (responseMessage != null) 'response_message': responseMessage,
        if (responseCode != null) 'response_code': responseCode,
        if (ticketStatusBefore != null)
          'ticket_status_before': ticketStatusBefore,
        if (ticketStatusAfter != null)
          'ticket_status_after': ticketStatusAfter,
        if (metadata != null) 'metadata': metadata,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

class ScanLocation {
  const ScanLocation({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.address,
    this.coordinates,
    this.radius = 50,
    this.opensAt,
    this.closesAt,
    this.allowedTicketTypes,
    this.requiresExtraVerification = false,
    this.assignedStaff,
    this.isActive = true,
    this.isPrimary = false,
    this.totalScans = 0,
    this.successScans = 0,
    this.failedScans = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String? description;
  final String? address;
  final String? coordinates;
  final int radius;
  final String? opensAt;
  final String? closesAt;
  final String? allowedTicketTypes;
  final bool requiresExtraVerification;
  final String? assignedStaff;
  final bool isActive;
  final bool isPrimary;
  final int totalScans;
  final int successScans;
  final int failedScans;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ScanLocation.fromJson(Map<String, dynamic> json) {
    return ScanLocation(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      coordinates: json['coordinates'] as String?,
      radius: (json['radius'] as num?)?.toInt() ?? 50,
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
      allowedTicketTypes: json['allowed_ticket_types'] as String?,
      requiresExtraVerification:
          json['requires_extra_verification'] as bool? ?? false,
      assignedStaff: json['assigned_staff'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isPrimary: json['is_primary'] as bool? ?? false,
      totalScans: (json['total_scans'] as num?)?.toInt() ?? 0,
      successScans: (json['success_scans'] as num?)?.toInt() ?? 0,
      failedScans: (json['failed_scans'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'name': name,
        if (description != null) 'description': description,
        if (address != null) 'address': address,
        if (coordinates != null) 'coordinates': coordinates,
        'radius': radius,
        if (opensAt != null) 'opens_at': opensAt,
        if (closesAt != null) 'closes_at': closesAt,
        if (allowedTicketTypes != null)
          'allowed_ticket_types': allowedTicketTypes,
        'requires_extra_verification': requiresExtraVerification,
        if (assignedStaff != null) 'assigned_staff': assignedStaff,
        'is_active': isActive,
        'is_primary': isPrimary,
        'total_scans': totalScans,
        'success_scans': successScans,
        'failed_scans': failedScans,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.eventId,
    required this.userId,
    this.ticketType,
    this.quantity = 1,
    this.status = WaitlistStatus.active,
    this.offerSent = false,
    this.offerSentAt,
    this.offerExpiresAt,
    this.bookingId,
    this.convertedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String? ticketType;
  final int quantity;
  final String status;
  final bool offerSent;
  final DateTime? offerSentAt;
  final DateTime? offerExpiresAt;
  final String? bookingId;
  final DateTime? convertedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      ticketType: json['ticket_type'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? WaitlistStatus.active,
      offerSent: json['offer_sent'] as bool? ?? false,
      offerSentAt: _parseDate(json['offer_sent_at']),
      offerExpiresAt: _parseDate(json['offer_expires_at']),
      bookingId: json['booking_id'] as String?,
      convertedAt: _parseDate(json['converted_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'user_id': userId,
        if (ticketType != null) 'ticket_type': ticketType,
        'quantity': quantity,
        'status': status,
        'offer_sent': offerSent,
        if (offerSentAt != null)
          'offer_sent_at': offerSentAt!.toIso8601String(),
        if (offerExpiresAt != null)
          'offer_expires_at': offerExpiresAt!.toIso8601String(),
        if (bookingId != null) 'booking_id': bookingId,
        if (convertedAt != null)
          'converted_at': convertedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// Response of POST /api/v1/instances/checkin.
class CheckinResult {
  const CheckinResult({
    required this.allowed,
    required this.message,
    this.instance,
  });

  final bool allowed;
  final String message;
  final TicketInstance? instance;

  factory CheckinResult.fromJson(Map<String, dynamic> json) {
    return CheckinResult(
      allowed: json['allowed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      instance: json['instance'] is Map
          ? TicketInstance.fromJson(
              (json['instance'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'message': message,
        if (instance != null) 'instance': instance!.toJson(),
      };
}

/// Request bodies for the booking endpoints.

class AssignTicketRequest {
  const AssignTicketRequest({
    this.name,
    this.email,
    this.phone,
  });

  final String? name;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}

class ShareTicketRequest {
  const ShareTicketRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResaleTicketRequest {
  const ResaleTicketRequest({required this.price});

  final double price;

  Map<String, dynamic> toJson() => {'price': price};
}

class CheckinRequest {
  const CheckinRequest({
    required this.code,
    this.location,
  });

  final String code;
  final String? location;

  Map<String, dynamic> toJson() => {
        'code': code,
        if (location != null) 'location': location,
      };
}

class ClaimTicketRequest {
  const ClaimTicketRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class WaitlistSignupRequest {
  const WaitlistSignupRequest({
    required this.eventId,
    this.ticketType,
    this.quantity = 1,
  });

  final String eventId;
  final String? ticketType;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        if (ticketType != null) 'ticket_type': ticketType,
        'quantity': quantity,
      };
}

/// String constants matching the donjo_booking backend values.
abstract final class BookingStatus {
  static const confirmed = 'confirmed';
}

abstract final class BookingPaymentStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const failed = 'failed';
  static const refunded = 'refunded';
}

abstract final class TicketInstanceStatus {
  static const active = 'active';
  static const pendingClaim = 'pending_claim';
  static const listed = 'listed';
  static const resold = 'resold';
  static const used = 'used';
  static const voided = 'void';
}

abstract final class WaitlistStatus {
  static const active = 'active';
  static const left = 'left';
}

abstract final class ScanResult {
  static const success = 'success';
  static const blocked = 'blocked';
}

/// Payment method constants (shared value names with donjo_payment).
abstract final class PaymentMethodMpesa {
  static const mpesa = 'mpesa';
}
