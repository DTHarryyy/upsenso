import 'package:flutter/foundation.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';

/// Contract for all notification data operations.
/// The presentation layer depends only on this interface — never on Supabase
/// or any other infrastructure detail.
abstract class INotificationsRepository {
  /// Fetch all notifications for [businessId], ordered newest-first.
  Future<List<NotificationItem>> fetchAll(String businessId);

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId);

  /// Mark every unread notification for [businessId] as read.
  Future<void> markAllAsRead({required String businessId});

  /// Permanently delete a notification.
  Future<void> delete(String notificationId);

  /// Subscribe to real-time INSERT / UPDATE / DELETE events for [businessId].
  ///
  /// Returns a [VoidCallback] — call it to cancel the subscription.
  VoidCallback subscribe({
    required String businessId,
    required void Function(NotificationItem item) onInsert,
    required void Function(NotificationItem item) onUpdate,
    required void Function(String id) onDelete,
  });
}
