# Notifications

Push/email/in-app notification outbox, unsubscribe/click tracking, the activity
feed and push-device registration.

## Backend

Talks to the **notifications** microservice through the gateway:

- `GET /api/v1/notifications`, `GET /api/v1/notifications/unread-count`
- `POST /api/v1/notifications` (create/send)
- `PUT  /api/v1/notifications/:id/read` and `/clicked`
- feed: `GET /api/v1/feed`, mark a feed item viewed/clicked/interacted
- devices: `POST /api/v1/devices`, `GET /api/v1/devices`, `DELETE /api/v1/devices/:id`
- `GET /api/v1/templates` (notification templates)

## Layout

```
lib/feature/notifications/
├── data/
│   ├── models/notification_models.dart
│   └── repositories/notification_repository.dart
└── presentation/bloc/                   # notifications_event / notifications_state / notifications_bloc
```

## How it works

1. `NotificationsLoaded` pulls the inbox and derives `unreadCount` locally;
   `UnreadCountLoaded` fetches the server count for badges.
2. Reading/clicking dispatches `NotificationMarkedRead/{Clicked}` — the bloc updates
   the local list optimistically (adding `readAt`/`clickedAt`) and re-derives the
   unread count.
3. `FeedLoaded` fills the activity feed; feed items report
   `FeedItemViewed/Clicked/Interacted` back to the server for analytics.
4. `DeviceRegistered/DevicesLoaded/DeviceDeleted` manage push targets;
   `TemplatesLoaded` fetches reusable message templates for compose screens.
5. Single `NotificationsStatus` guards the loading state; transient success shows
   via `message`, failures via `NotificationsError{message, fields}`.