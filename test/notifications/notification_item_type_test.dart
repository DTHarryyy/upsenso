import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';

/// Phase 3: the PO-approval notification type must round-trip, and unknown
/// types must still fall back to `system` (forward-compatibility).
void main() {
  Map<String, dynamic> baseMap(String type) => {
    'id': 'n1',
    'business_id': 'b1',
    'user_id': 'u1',
    'type': type,
    'severity': 'medium',
    'title': 'Purchase order awaiting approval',
    'body': 'PO-1 needs your approval.',
    'is_read': false,
    'reference_id': 'po-1',
    'reference_type': 'purchase_order',
    'created_at': '2026-06-15T10:00:00.000Z',
  };

  test('po_approval parses to NotificationType.poApproval', () {
    final item = NotificationItem.fromMap(baseMap('po_approval'));
    expect(item.type, NotificationType.poApproval);
    expect(item.referenceType, 'purchase_order');
  });

  test('po_approval round-trips through toMap', () {
    final item = NotificationItem.fromMap(baseMap('po_approval'));
    expect(item.toMap()['type'], 'po_approval');
  });

  test('unknown type still falls back to system', () {
    final item = NotificationItem.fromMap(baseMap('something_new'));
    expect(item.type, NotificationType.system);
  });
}
