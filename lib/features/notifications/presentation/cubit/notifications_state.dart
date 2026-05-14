import 'package:equatable/equatable.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';

enum NotificationFilter { all, unread, fraud, stock, approvals }

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationItem> allItems;
  final NotificationFilter activeFilter;

  const NotificationsLoaded({
    required this.allItems,
    this.activeFilter = NotificationFilter.all,
  });

  List<NotificationItem> get displayed {
    switch (activeFilter) {
      case NotificationFilter.unread:
        return allItems.where((n) => !n.isRead).toList();
      case NotificationFilter.fraud:
        return allItems.where((n) => n.type == NotificationType.fraud).toList();
      case NotificationFilter.stock:
        return allItems
            .where((n) => n.type == NotificationType.lowStock)
            .toList();
      case NotificationFilter.approvals:
        return allItems
            .where((n) => n.type == NotificationType.expenseApproval)
            .toList();
      case NotificationFilter.all:
        return allItems;
    }
  }

  int get unreadCount => allItems.where((n) => !n.isRead).length;
  int get fraudCount =>
      allItems.where((n) => n.type == NotificationType.fraud).length;
  int get stockCount =>
      allItems.where((n) => n.type == NotificationType.lowStock).length;
  int get approvalsCount =>
      allItems.where((n) => n.type == NotificationType.expenseApproval).length;

  int get unreadFraud => allItems
      .where((n) => n.type == NotificationType.fraud && !n.isRead)
      .length;
  int get unreadStock => allItems
      .where((n) => n.type == NotificationType.lowStock && !n.isRead)
      .length;
  int get unreadApprovals => allItems
      .where((n) => n.type == NotificationType.expenseApproval && !n.isRead)
      .length;

  NotificationsLoaded copyWith({
    List<NotificationItem>? allItems,
    NotificationFilter? activeFilter,
  }) {
    return NotificationsLoaded(
      allItems: allItems ?? this.allItems,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [allItems, activeFilter];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
