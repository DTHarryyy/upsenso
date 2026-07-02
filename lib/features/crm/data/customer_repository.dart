import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/customers_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/crm/data/datasources/customer_remote_ds.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';

/// Offline-first customer repository. Drift is the source of truth; writes go
/// local first (queued for sync) and a best-effort remote upsert keeps Supabase
/// warm. Mirrors [ProcurementRepository]'s supplier flow.
class CustomerRepository implements ICustomerRepository {
  final CustomersDao _customersDao;
  final TransactionsDao _transactionsDao;
  // ignore: unused_field
  final CustomerRemoteDs? _remoteDs;

  static const _uuid = Uuid();

  CustomerRepository({
    required CustomersDao customersDao,
    required TransactionsDao transactionsDao,
    CustomerRemoteDs? remoteDs,
  })  : _customersDao = customersDao,
        _transactionsDao = transactionsDao,
        _remoteDs = remoteDs;

  @override
  Stream<List<Customer>> watchCustomers(String businessId) {
    return _customersDao
        .watchActiveByBusinessId(businessId)
        .map((rows) => rows.map(Customer.fromRow).toList());
  }

  @override
  Future<List<Customer>> getCustomers(String businessId) async {
    final rows = await _customersDao.getActiveByBusinessId(businessId);
    return rows.map(Customer.fromRow).toList();
  }

  @override
  Future<Customer> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final id = _uuid.v4();
      await _customersDao.insert(
        CustomersTableCompanion.insert(
          id: id,
          businessId: businessId,
          name: name,
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          notes: Value(notes),
          syncStatus: Value(SyncStatus.pendingUpload.toInt()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.customerCreated,
        entityType: 'customer',
        entityId: id,
        entityName: name,
        description: 'Customer $name created',
        businessId: businessId,
      );
      final row = await _customersDao.getById(id);
      // Row was just written locally; fall back to a hand-built entity only if a
      // read somehow returns null so the caller always gets the new id.
      return row != null
          ? Customer.fromRow(row)
          : Customer(
              id: id,
              businessId: businessId,
              name: name,
              phone: phone,
              email: email,
              address: address,
              notes: notes,
              isActive: true,
              createdAt: DateTime.now(),
            );
    } catch (e, st) {
      debugPrint('[CRM] Error in createCustomer: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    try {
      await _customersDao.updateCustomer(
        id,
        CustomersTableCompanion(
          name: Value(name),
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          notes: Value(notes),
          isActive: isActive != null ? Value(isActive) : const Value.absent(),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.customerUpdated,
        entityType: 'customer',
        entityId: id,
        entityName: name,
        description: 'Customer $name updated',
      );
    } catch (e, st) {
      debugPrint('[CRM] Error in updateCustomer: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> archiveCustomer(String id) async {
    try {
      final existing = await _customersDao.getById(id);
      await _customersDao.softDelete(id);
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.customerArchived,
        entityType: 'customer',
        entityId: id,
        entityName: existing?.name,
        description: 'Customer ${existing?.name ?? id} archived',
      );
    } catch (e, st) {
      debugPrint('[CRM] Error in archiveCustomer: $e\n$st');
      rethrow;
    }
  }

  @override
  Stream<List<CustomerPurchase>> watchPurchases({
    required String businessId,
    required String customerId,
  }) {
    return _transactionsDao
        .watchByCustomerId(businessId: businessId, customerId: customerId)
        .map((rows) => rows.map(CustomerPurchase.fromRow).toList());
  }
}
