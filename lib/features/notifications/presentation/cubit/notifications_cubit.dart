import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final INotificationsRepository _repository;

  String? _businessId;
  VoidCallback? _unsubscribe;

  NotificationsCubit(this._repository) : super(const NotificationsInitial());

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> load(String businessId) async {
    _businessId = businessId;
    emit(const NotificationsLoading());
    try {
      final items = await _repository.fetchAll(businessId);
      emit(NotificationsLoaded(allItems: items));
      _subscribeRealtime(businessId);
    } catch (e, st) {
      debugPrint('[Notifications] Error in load: $e\n$st');
      emit(NotificationsError(AppErrorMapper.message(e)));
    }
  }

  /// Re-fetches data after an error. Keeps the same business ID.
  Future<void> retry() async {
    if (_businessId != null) await load(_businessId!);
  }

  // ── Realtime subscription ────────────────────────────────────────────────────

  void _subscribeRealtime(String businessId) {
    _unsubscribe?.call();
    _unsubscribe = _repository.subscribe(
      businessId: businessId,
      onInsert: _prependItem,
      onUpdate: _replaceItem,
      onDelete: _removeItem,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    _optimisticallyUpdate(notificationId, (n) => n.copyWith(isRead: true));
    try {
      await _repository.markAsRead(notificationId);
    } catch (_) {
      // Revert on failure by reloading
      if (_businessId != null) await load(_businessId!);
    }
  }

  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final updated = current.allItems
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(current.copyWith(allItems: updated));

    try {
      await _repository.markAllAsRead(businessId: _businessId!);
    } catch (_) {
      if (_businessId != null) await load(_businessId!);
    }
  }

  Future<void> delete(String notificationId) async {
    _removeItem(notificationId);
    try {
      await _repository.delete(notificationId);
    } catch (_) {
      if (_businessId != null) await load(_businessId!);
    }
  }

  void setFilter(NotificationFilter filter) {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(current.copyWith(activeFilter: filter));
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _prependItem(NotificationItem item) {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(current.copyWith(allItems: [item, ...current.allItems]));
    }
  }

  void _replaceItem(NotificationItem item) {
    final current = state;
    if (current is NotificationsLoaded) {
      final updated = current.allItems
          .map((n) => n.id == item.id ? item : n)
          .toList();
      emit(current.copyWith(allItems: updated));
    }
  }

  void _removeItem(String id) {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(
        current.copyWith(
          allItems: current.allItems.where((n) => n.id != id).toList(),
        ),
      );
    }
  }

  void _optimisticallyUpdate(
    String id,
    NotificationItem Function(NotificationItem) updater,
  ) {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(
        current.copyWith(
          allItems: current.allItems
              .map((n) => n.id == id ? updater(n) : n)
              .toList(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _unsubscribe?.call();
    return super.close();
  }
}
