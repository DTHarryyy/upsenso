import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/notifications/domain/billing_notice_service.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final INotificationsRepository _repository;
  final BillingNoticeService _notices;

  String? _businessId;
  VoidCallback? _unsubscribe;

  NotificationsCubit(this._repository, this._notices)
    : super(const NotificationsInitial()) {
    _notices.revision.addListener(_onNoticesChanged);
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> load(String businessId) async {
    _businessId = businessId;
    emit(const NotificationsLoading());
    try {
      await _notices.reArm(businessId);
      final items = await _repository.fetchAll(businessId);
      emit(NotificationsLoaded(allItems: _withBillingNotice(items)));
      _subscribeRealtime(businessId);
    } catch (e, st) {
      debugPrint('[Notifications] Error in load: $e\n$st');
      emit(NotificationsError(AppErrorMapper.message(e)));
    }
  }

  // A trial ending, a payment recovering, or a reactivation can all happen
  // while this page is open — keep the synthetic notice in step.
  void _onNoticesChanged() {
    final current = state;
    if (current is! NotificationsLoaded) return;
    final businessId = _businessId;
    if (businessId != null) unawaited(_notices.reArm(businessId));
    emit(current.copyWith(allItems: _withBillingNotice(current.allItems)));
  }

  List<NotificationItem> _withBillingNotice(List<NotificationItem> items) {
    final real = items
        .where((n) => !BillingNoticeService.isSyntheticId(n.id))
        .toList();
    final businessId = _businessId;
    if (businessId == null) return real;
    final notice = _notices.build(businessId);
    return notice == null ? real : [notice, ...real];
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
    // Synthetic — no row to update. Acknowledging it removes it outright
    // rather than leaving a read-but-visible row that never goes away.
    if (BillingNoticeService.isSyntheticId(notificationId)) {
      await _acknowledgeNotice(notificationId);
      return;
    }
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

    // Synthetic notices have no row to mark — acknowledging drops them
    // outright rather than leaving a read-but-visible row forever.
    final synthetic = current.allItems
        .where((n) => BillingNoticeService.isSyntheticId(n.id))
        .toList();
    final updated = current.allItems
        .where((n) => !BillingNoticeService.isSyntheticId(n.id))
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(current.copyWith(allItems: updated));
    for (final n in synthetic) {
      await _persistAck(n.id);
    }

    try {
      await _repository.markAllAsRead(businessId: _businessId!);
    } catch (_) {
      if (_businessId != null) await load(_businessId!);
    }
  }

  Future<void> _acknowledgeNotice(String id) async {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(
        current.copyWith(
          allItems: current.allItems.where((n) => n.id != id).toList(),
        ),
      );
    }
    await _persistAck(id);
  }

  Future<void> _persistAck(String id) async {
    final businessId = _businessId;
    if (businessId == null) return;
    for (final kind in BillingNoticeKind.values) {
      if (kind.id == id) {
        await _notices.acknowledge(kind, businessId);
        return;
      }
    }
  }

  Future<void> delete(String notificationId) async {
    // Synthetic — no delete affordance is shown for it in the UI; guard
    // anyway rather than sending a fake id to the repository.
    if (BillingNoticeService.isSyntheticId(notificationId)) return;
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
    _notices.revision.removeListener(_onNoticesChanged);
    return super.close();
  }
}
