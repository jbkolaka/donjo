library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/notifications/data/models/notification_models.dart';
import 'package:donjo/feature/notifications/data/repositories/notification_repository.dart';
import 'package:donjo/feature/notifications/presentation/bloc/notifications_event.dart';
import 'package:donjo/feature/notifications/presentation/bloc/notifications_state.dart';

export 'notifications_event.dart';
export 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required this.notificationRepository})
    : super(const NotificationsState()) {
    on<NotificationsLoaded>(_onNotificationsLoaded);
    on<UnreadCountLoaded>(_onUnreadCountLoaded);
    on<NotificationCreated>(_onNotificationCreated);
    on<NotificationMarkedRead>(_onNotificationMarkedRead);
    on<NotificationMarkedClicked>(_onNotificationMarkedClicked);
    on<FeedLoaded>(_onFeedLoaded);
    on<FeedItemViewed>(_onFeedItemViewed);
    on<FeedItemClicked>(_onFeedItemClicked);
    on<FeedItemInteracted>(_onFeedItemInteracted);
    on<DeviceRegistered>(_onDeviceRegistered);
    on<DevicesLoaded>(_onDevicesLoaded);
    on<DeviceDeleted>(_onDeviceDeleted);
    on<TemplatesLoaded>(_onTemplatesLoaded);
    on<NotificationsErrorCleared>(_onErrorCleared);
  }

  final NotificationRepository notificationRepository;

  Future<void> _onNotificationsLoaded(
    NotificationsLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final notifications = await notificationRepository.listNotifications();
      final unreadCount = notifications.where((n) => n.readAt == null).length;
      emit(
        state.copyWith(
          status: NotificationsStatus.loaded,
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onUnreadCountLoaded(
    UnreadCountLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final count = await notificationRepository.unreadCount();
      emit(state.copyWith(unreadCount: count));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onNotificationCreated(
    NotificationCreated event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final created = await notificationRepository.createNotification(
        event.request,
      );
      emit(
        state.copyWith(
          status: NotificationsStatus.loaded,
          notifications: [created, ...state.notifications],
          message: 'Notification sent',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onNotificationMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.markRead(event.id);
      final updated = state.notifications
          .map((n) =>
              n.id == event.id ? _copyAsRead(n) : n)
          .toList();
      final unread = updated.where((n) => n.readAt == null).length;
      emit(
        state.copyWith(notifications: updated, unreadCount: unread),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onNotificationMarkedClicked(
    NotificationMarkedClicked event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.markClicked(event.id);
      final updated = state.notifications
          .map((n) =>
              n.id == event.id ? _copyAsClicked(n) : n)
          .toList();
      emit(state.copyWith(notifications: updated));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onFeedLoaded(
    FeedLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final feed = await notificationRepository.getFeed();
      emit(state.copyWith(status: NotificationsStatus.loaded, feed: feed));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onFeedItemViewed(
    FeedItemViewed event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.markFeedViewed(event.id);
      emit(state.copyWith(message: 'Viewed'));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onFeedItemClicked(
    FeedItemClicked event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.markFeedClicked(event.id);
      emit(state.copyWith(message: 'Clicked'));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onFeedItemInteracted(
    FeedItemInteracted event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.markFeedInteracted(event.id);
      emit(state.copyWith(message: 'Interaction recorded'));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onDeviceRegistered(
    DeviceRegistered event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final device = await notificationRepository.registerDevice(event.request);
      emit(
        state.copyWith(
          status: NotificationsStatus.loaded,
          devices: [...state.devices, device],
          message: 'Device registered',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onDevicesLoaded(
    DevicesLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final devices = await notificationRepository.listDevices();
      emit(state.copyWith(status: NotificationsStatus.loaded, devices: devices));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onDeviceDeleted(
    DeviceDeleted event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await notificationRepository.deleteDevice(event.id);
      emit(
        state.copyWith(
          devices: state.devices.where((d) => d.id != event.id).toList(),
          message: 'Device deactivated',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: NotificationsError(message: e.toString())));
    }
  }

  Future<void> _onTemplatesLoaded(
    TemplatesLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final templates = await notificationRepository.listTemplates();
      emit(
        state.copyWith(status: NotificationsStatus.loaded, templates: templates),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          error: NotificationsError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(
    NotificationsErrorCleared event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }

  Notification _copyAsRead(Notification n) {
    return Notification(
      id: n.id,
      userId: n.userId,
      channel: n.channel,
      type: n.type,
      subject: n.subject,
      content: n.content,
      htmlContent: n.htmlContent,
      templateId: n.templateId,
      templateData: n.templateData,
      status: n.status,
      sentAt: n.sentAt,
      deliveredAt: n.deliveredAt,
      readAt: n.readAt ?? DateTime.now(),
      clickedAt: n.clickedAt,
      errorMessage: n.errorMessage,
      retryCount: n.retryCount,
      priority: n.priority,
      referenceId: n.referenceId,
      referenceType: n.referenceType,
      metadata: n.metadata,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
  }

  Notification _copyAsClicked(Notification n) {
    return Notification(
      id: n.id,
      userId: n.userId,
      channel: n.channel,
      type: n.type,
      subject: n.subject,
      content: n.content,
      htmlContent: n.htmlContent,
      templateId: n.templateId,
      templateData: n.templateData,
      status: n.status,
      sentAt: n.sentAt,
      deliveredAt: n.deliveredAt,
      readAt: n.readAt,
      clickedAt: n.clickedAt ?? DateTime.now(),
      errorMessage: n.errorMessage,
      retryCount: n.retryCount,
      priority: n.priority,
      referenceId: n.referenceId,
      referenceType: n.referenceType,
      metadata: n.metadata,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
  }
}