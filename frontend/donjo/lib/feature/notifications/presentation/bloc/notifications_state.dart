library;

import 'package:donjo/feature/notifications/data/models/notification_models.dart';

enum NotificationsStatus {
  initial,
  loading,
  loaded,
  failure,
}

class NotificationsError {
  const NotificationsError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class NotificationsState {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.feed = const [],
    this.devices = const [],
    this.templates = const [],
    this.error,
    this.message,
  });

  final NotificationsStatus status;
  final List<Notification> notifications;
  final int unreadCount;
  final List<FeedItem> feed;
  final List<PushDevice> devices;
  final List<NotificationTemplate> templates;
  final NotificationsError? error;
  final String? message;

  bool get busy => status == NotificationsStatus.loading;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<Notification>? notifications,
    int? unreadCount,
    List<FeedItem>? feed,
    List<PushDevice>? devices,
    List<NotificationTemplate>? templates,
    NotificationsError? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      feed: feed ?? this.feed,
      devices: devices ?? this.devices,
      templates: templates ?? this.templates,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}