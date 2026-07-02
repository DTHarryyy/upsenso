import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';

/// Contract for customer (CRM) data access. Implemented by
/// [CustomerRepository] (local Drift source of truth + best-effort remote).
abstract class ICustomerRepository {
  /// Live stream of the business's active (non-archived) customers, name-sorted.
  Stream<List<Customer>> watchCustomers(String businessId);

  /// One-shot read of the active customers (used by the POS picker search).
  Future<List<Customer>> getCustomers(String businessId);

  /// Creates a customer and returns the persisted entity (the caller needs the
  /// new id — e.g. the checkout quick-add attaches it to the sale).
  Future<Customer> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<void> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  });

  /// Soft-delete (archive) — keeps the row for historical transactions.
  Future<void> archiveCustomer(String id);

  /// Live purchase history (completed sales) for one customer, newest first.
  Stream<List<CustomerPurchase>> watchPurchases({
    required String businessId,
    required String customerId,
  });
}
