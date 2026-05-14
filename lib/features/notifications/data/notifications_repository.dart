import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';

/// Supabase-backed implementation of [INotificationsRepository].
/// All infrastructure details (SQL, realtime channels) are isolated here.
class NotificationsRepository implements INotificationsRepository {
  final SupabaseClient _client;

  const NotificationsRepository(this._client);

  @override
  Future<List<NotificationItem>> fetchAll(String businessId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => NotificationItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead({required String businessId}) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('business_id', businessId)
        .eq('is_read', false);
  }

  @override
  Future<void> delete(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  @override
  VoidCallback subscribe({
    required String businessId,
    required void Function(NotificationItem item) onInsert,
    required void Function(NotificationItem item) onUpdate,
    required void Function(String id) onDelete,
  }) {
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'business_id',
      value: businessId,
    );

    final channel = _client
        .channel('notifications:$businessId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: filter,
          callback: (p) => onInsert(NotificationItem.fromMap(p.newRecord)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: filter,
          callback: (p) => onUpdate(NotificationItem.fromMap(p.newRecord)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: filter,
          callback: (p) {
            final id = p.oldRecord['id'] as String?;
            if (id != null) onDelete(id);
          },
        )
        .subscribe();

    return channel.unsubscribe;
  }
}
