import 'package:pos/features/crm/domain/entities/customer.dart';

/// What the till attached to a sale. Three shapes:
///  • [CustomerSelection.record]   — a saved CRM customer (customer_id + name;
///    builds purchase history).
///  • [CustomerSelection.nameOnly] — an ad-hoc label with no saved record
///    (customer_name only). The lightweight, everyone-can-use path.
///  • [CustomerSelection.walkIn]   — no customer at all.
class CustomerSelection {
  /// A saved CRM record, when this selection is a real customer.
  final Customer? customer;

  /// An ad-hoc name typed at the till (no saved record).
  final String? adHocName;

  const CustomerSelection.record(Customer this.customer) : adHocName = null;
  const CustomerSelection.nameOnly(String this.adHocName) : customer = null;
  const CustomerSelection.walkIn()
      : customer = null,
        adHocName = null;

  bool get isWalkIn => customer == null && adHocName == null;

  /// Name to snapshot onto the sale (null for walk-in).
  String? get displayName => customer?.name ?? adHocName;

  /// Saved-record id, or null for name-only / walk-in.
  String? get customerId => customer?.id;
}
