import 'package:equatable/equatable.dart';

enum NotificationType {
  fraud,
  lowStock,
  syncConflict,
  expenseApproval,
  cashDiscrepancy,
  system,
}

enum NotificationSeverity { high, medium, low }

class NotificationItem extends Equatable {
  final String id;
  final String businessId;
  final String? userId;
  final NotificationType type;
  final NotificationSeverity severity;
  final String title;
  final String body;
  final bool isRead;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.businessId,
    this.userId,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.isRead,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? businessId,
    String? userId,
    NotificationType? type,
    NotificationSeverity? severity,
    String? title,
    String? body,
    bool? isRead,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      userId: map['user_id'] as String?,
      type: _typeFromString(map['type'] as String),
      severity: _severityFromString(map['severity'] as String? ?? 'low'),
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: map['is_read'] as bool? ?? false,
      referenceId: map['reference_id'] as String?,
      referenceType: map['reference_type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_id': businessId,
    'user_id': userId,
    'type': _typeToString(type),
    'severity': _severityToString(severity),
    'title': title,
    'body': body,
    'is_read': isRead,
    'reference_id': referenceId,
    'reference_type': referenceType,
    'created_at': createdAt.toIso8601String(),
  };

  static NotificationType _typeFromString(String value) {
    switch (value) {
      case 'fraud':
        return NotificationType.fraud;
      case 'low_stock':
        return NotificationType.lowStock;
      case 'sync_conflict':
        return NotificationType.syncConflict;
      case 'expense_approval':
        return NotificationType.expenseApproval;
      case 'cash_discrepancy':
        return NotificationType.cashDiscrepancy;
      default:
        return NotificationType.system;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.fraud:
        return 'fraud';
      case NotificationType.lowStock:
        return 'low_stock';
      case NotificationType.syncConflict:
        return 'sync_conflict';
      case NotificationType.expenseApproval:
        return 'expense_approval';
      case NotificationType.cashDiscrepancy:
        return 'cash_discrepancy';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationSeverity _severityFromString(String value) {
    switch (value) {
      case 'high':
        return NotificationSeverity.high;
      case 'medium':
        return NotificationSeverity.medium;
      default:
        return NotificationSeverity.low;
    }
  }

  static String _severityToString(NotificationSeverity s) {
    switch (s) {
      case NotificationSeverity.high:
        return 'high';
      case NotificationSeverity.medium:
        return 'medium';
      case NotificationSeverity.low:
        return 'low';
    }
  }

  @override
  List<Object?> get props => [
    id,
    businessId,
    userId,
    type,
    severity,
    title,
    body,
    isRead,
    referenceId,
    referenceType,
    createdAt,
  ];
}
