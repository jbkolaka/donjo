library;

/// Data models for the donjo_notifications microservice (Notification /
/// Feed / Device / Template).
///
/// Mirrors the JSON contract of:
///   backend/donjo_notifications/internal/notificationservice/models.go
///   backend/donjo_notifications/internal/server/routes.go

class Notification {
  const Notification({
    required this.id,
    required this.userId,
    this.channel = NotificationChannel.inApp,
    this.type = NotificationType.generic,
    this.subject,
    this.content = '',
    this.htmlContent,
    this.templateId,
    this.templateData,
    this.status = NotificationStatus.pending,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.clickedAt,
    this.errorMessage,
    this.retryCount = 0,
    this.priority = NotificationPriority.medium,
    this.referenceId,
    this.referenceType,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String channel;
  final String type;
  final String? subject;
  final String content;
  final String? htmlContent;
  final String? templateId;
  final Map<String, dynamic>? templateData;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? clickedAt;
  final String? errorMessage;
  final int retryCount;
  final String priority;
  final String? referenceId;
  final String? referenceType;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      channel: json['channel'] as String? ?? NotificationChannel.inApp,
      type: json['type'] as String? ?? NotificationType.generic,
      subject: json['subject'] as String?,
      content: json['content'] as String? ?? '',
      htmlContent: json['html_content'] as String?,
      templateId: json['template_id'] as String?,
      templateData: json['template_data'] is Map
          ? (json['template_data'] as Map).cast<String, dynamic>()
          : null,
      status: json['status'] as String? ?? NotificationStatus.pending,
      sentAt: _parseDate(json['sent_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      readAt: _parseDate(json['read_at']),
      clickedAt: _parseDate(json['clicked_at']),
      errorMessage: json['error_message'] as String?,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      priority: json['priority'] as String? ?? NotificationPriority.medium,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      metadata: json['metadata'] is Map
          ? (json['metadata'] as Map).cast<String, dynamic>()
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'channel': channel,
        'type': type,
        if (subject != null) 'subject': subject,
        'content': content,
        if (htmlContent != null) 'html_content': htmlContent,
        if (templateId != null) 'template_id': templateId,
        if (templateData != null) 'template_data': templateData,
        'status': status,
        if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
        if (deliveredAt != null)
          'delivered_at': deliveredAt!.toIso8601String(),
        if (readAt != null) 'read_at': readAt!.toIso8601String(),
        if (clickedAt != null) 'clicked_at': clickedAt!.toIso8601String(),
        if (errorMessage != null) 'error_message': errorMessage,
        'retry_count': retryCount,
        'priority': priority,
        if (referenceId != null) 'reference_id': referenceId,
        if (referenceType != null) 'reference_type': referenceType,
        if (metadata != null) 'metadata': metadata,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class FeedItem {
  const FeedItem({
    required this.id,
    required this.userId,
    this.notificationId,
    required this.feedType,
    this.priority = 0,
    this.position,
    this.title,
    this.message,
    this.imageUrl,
    this.viewed = false,
    this.viewedAt,
    this.clicked = false,
    this.clickedAt,
    this.interacted = false,
    this.interactedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? notificationId;
  final String feedType;
  final int priority;
  final int? position;
  final String? title;
  final String? message;
  final String? imageUrl;
  final bool viewed;
  final DateTime? viewedAt;
  final bool clicked;
  final DateTime? clickedAt;
  final bool interacted;
  final DateTime? interactedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      notificationId: json['notification_id'] as String?,
      feedType: json['feed_type'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt(),
      title: json['title'] as String?,
      message: json['message'] as String?,
      imageUrl: json['image_url'] as String?,
      viewed: json['viewed'] as bool? ?? false,
      viewedAt: _parseDate(json['viewed_at']),
      clicked: json['clicked'] as bool? ?? false,
      clickedAt: _parseDate(json['clicked_at']),
      interacted: json['interacted'] as bool? ?? false,
      interactedAt: _parseDate(json['interacted_at']),
      expiresAt: _parseDate(json['expires_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (notificationId != null) 'notification_id': notificationId,
        'feed_type': feedType,
        'priority': priority,
        if (position != null) 'position': position,
        if (title != null) 'title': title,
        if (message != null) 'message': message,
        if (imageUrl != null) 'image_url': imageUrl,
        'viewed': viewed,
        if (viewedAt != null) 'viewed_at': viewedAt!.toIso8601String(),
        'clicked': clicked,
        if (clickedAt != null) 'clicked_at': clickedAt!.toIso8601String(),
        'interacted': interacted,
        if (interactedAt != null)
          'interacted_at': interactedAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class NotificationTemplate {
  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.subjectTemplate,
    required this.contentTemplate,
    this.htmlTemplate,
    this.requiredVariables = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String? subjectTemplate;
  final String contentTemplate;
  final String? htmlTemplate;
  final List<String> requiredVariables;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      subjectTemplate: json['subject_template'] as String?,
      contentTemplate: json['content_template'] as String? ?? '',
      htmlTemplate: json['html_template'] as String?,
      requiredVariables:
          (json['required_variables'] as List?)?.cast<String>() ?? const [],
      isActive: json['is_active'] as bool? ?? true,
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
        'name': name,
        'type': type,
        if (subjectTemplate != null) 'subject_template': subjectTemplate,
        'content_template': contentTemplate,
        if (htmlTemplate != null) 'html_template': htmlTemplate,
        'required_variables': requiredVariables,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class PushDevice {
  const PushDevice({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    this.deviceId,
    this.deviceName,
    this.isActive = true,
    this.lastUsedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String deviceToken;
  final String platform;
  final String? deviceId;
  final String? deviceName;
  final bool isActive;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PushDevice.fromJson(Map<String, dynamic> json) {
    return PushDevice(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      deviceToken: json['device_token'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastUsedAt: json['last_used_at'] is String
          ? DateTime.tryParse(json['last_used_at'] as String)
          : null,
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
        'user_id': userId,
        'device_token': deviceToken,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
        'is_active': isActive,
        if (lastUsedAt != null)
          'last_used_at': lastUsedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// Body of POST /api/v1/notifications.
class CreateNotificationRequest {
  const CreateNotificationRequest({
    this.channel = NotificationChannel.inApp,
    this.type = NotificationType.generic,
    this.subject,
    this.content = '',
    this.htmlContent,
    this.templateId,
    this.templateData,
    this.status,
    this.priority,
    this.referenceId,
    this.referenceType,
    this.metadata,
    this.feedType,
    this.feedTitle,
    this.feedMessage,
    this.feedImageUrl,
    this.feedPriority,
    this.userId,
  });

  final String channel;
  final String type;
  final String? subject;
  final String content;
  final String? htmlContent;
  final String? templateId;
  final Map<String, dynamic>? templateData;
  final String? status;
  final String? priority;
  final String? referenceId;
  final String? referenceType;
  final Map<String, dynamic>? metadata;
  final String? feedType;
  final String? feedTitle;
  final String? feedMessage;
  final String? feedImageUrl;
  final int? feedPriority;

  /// Only honoured with an `X-Service-Token` (service-to-service pushes);
  /// ignored for normal JWT requests where the identity comes from the token.
  final String? userId;

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'type': type,
        if (subject != null) 'subject': subject,
        'content': content,
        if (htmlContent != null) 'html_content': htmlContent,
        if (templateId != null) 'template_id': templateId,
        if (templateData != null) 'template_data': templateData,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (referenceId != null) 'reference_id': referenceId,
        if (referenceType != null) 'reference_type': referenceType,
        if (metadata != null) 'metadata': metadata,
        if (feedType != null) 'feed_type': feedType,
        if (feedTitle != null) 'feed_title': feedTitle,
        if (feedMessage != null) 'feed_message': feedMessage,
        if (feedImageUrl != null) 'feed_image_url': feedImageUrl,
        if (feedPriority != null) 'feed_priority': feedPriority,
        if (userId != null) 'user_id': userId,
      };
}

/// Body of POST /api/v1/devices.
class RegisterDeviceRequest {
  const RegisterDeviceRequest({
    required this.deviceToken,
    required this.platform,
    this.deviceId,
    this.deviceName,
  });

  final String deviceToken;
  final String platform;
  final String? deviceId;
  final String? deviceName;

  Map<String, dynamic> toJson() => {
        'device_token': deviceToken,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
      };
}

/// String constants matching the donjo_notifications backend values.
abstract final class NotificationChannel {
  static const inApp = 'in_app';
  static const email = 'email';
  static const push = 'push';
}

abstract final class NotificationType {
  static const generic = 'generic';
  static const purchaseConfirmation = 'purchase_confirmation';
  static const saleAlert = 'sale_alert';
  static const eventDiscovery = 'event_discovery';
}

abstract final class NotificationStatus {
  static const pending = 'pending';
  static const delivered = 'delivered';
  static const failed = 'failed';
}

abstract final class NotificationPriority {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
}

abstract final class FeedType {
  static const purchase = 'purchase';
  static const sale = 'sale';
  static const eventDiscovery = 'event_discovery';
}
