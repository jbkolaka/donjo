library;

import 'package:donjo/feature/notifications/data/models/notification_models.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

final class NotificationsLoaded extends NotificationsEvent {
  const NotificationsLoaded();
}

final class UnreadCountLoaded extends NotificationsEvent {
  const UnreadCountLoaded();
}

final class NotificationCreated extends NotificationsEvent {
  const NotificationCreated({required this.request});
  final CreateNotificationRequest request;
}

final class NotificationMarkedRead extends NotificationsEvent {
  const NotificationMarkedRead({required this.id});
  final String id;
}

final class NotificationMarkedClicked extends NotificationsEvent {
  const NotificationMarkedClicked({required this.id});
  final String id;
}

final class FeedLoaded extends NotificationsEvent {
  const FeedLoaded();
}

final class FeedItemViewed extends NotificationsEvent {
  const FeedItemViewed({required this.id});
  final String id;
}

final class FeedItemClicked extends NotificationsEvent {
  const FeedItemClicked({required this.id});
  final String id;
}

final class FeedItemInteracted extends NotificationsEvent {
  const FeedItemInteracted({required this.id});
  final String id;
}

final class DeviceRegistered extends NotificationsEvent {
  const DeviceRegistered({required this.request});
  final RegisterDeviceRequest request;
}

final class DevicesLoaded extends NotificationsEvent {
  const DevicesLoaded();
}

final class DeviceDeleted extends NotificationsEvent {
  const DeviceDeleted({required this.id});
  final String id;
}

final class TemplatesLoaded extends NotificationsEvent {
  const TemplatesLoaded();
}

final class NotificationsErrorCleared extends NotificationsEvent {
  const NotificationsErrorCleared();
}