import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order_line.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';

class ProcurementRepository implements IProcurementRepository {
  final SuppliersDao _suppliersDao;
  final PurchaseOrdersDao _purchaseOrdersDao;
  final PurchaseOrderLinesDao _purchaseOrderLinesDao;
  final ProductVariantsDao _variantsDao;
  final InventoryLevelsDao _levelsDao;
  final StockMovementService _stockMovement;
  // ignore: unused_field
  final ProcurementRemoteDs? _remoteDs;

  static const _uuid = Uuid();

  ProcurementRepository({
    required SuppliersDao suppliersDao,
    required PurchaseOrdersDao purchaseOrdersDao,
    required PurchaseOrderLinesDao purchaseOrderLinesDao,
    required ProductVariantsDao variantsDao,
    required InventoryLevelsDao levelsDao,
    required StockMovementService stockMovement,
    ProcurementRemoteDs? remoteDs,
  }) : _suppliersDao = suppliersDao,
       _purchaseOrdersDao = purchaseOrdersDao,
       _purchaseOrderLinesDao = purchaseOrderLinesDao,
       _variantsDao = variantsDao,
       _levelsDao = levelsDao,
       _stockMovement = stockMovement,
       _remoteDs = remoteDs;

  // ── Suppliers ───────────────────────────────────────────────────────────────

  @override
  Stream<List<Supplier>> watchSuppliers(String businessId) {
    return _suppliersDao
        .watchActiveByBusinessId(businessId)
        .map((rows) => rows.map(Supplier.fromRow).toList());
  }

  @override
  Future<List<Supplier>> getSuppliers(String businessId) async {
    final rows = await _suppliersDao.getActiveByBusinessId(businessId);
    return rows.map(Supplier.fromRow).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final row = await _suppliersDao.getById(id);
    return row != null ? Supplier.fromRow(row) : null;
  }

  @override
  Future<void> createSupplier({
    required String businessId,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
  }) async {
    try {
      final id = _uuid.v4();
      await _suppliersDao.insert(
        SuppliersTableCompanion.insert(
          id: id,
          businessId: businessId,
          name: name,
          contactName: Value(contactName),
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          taxId: Value(taxId),
          notes: Value(notes),
          syncStatus: Value(SyncStatus.pendingUpload.toInt()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.supplierCreated,
        entityType: 'supplier',
        entityId: id,
        entityName: name,
        description: 'Supplier $name created',
        businessId: businessId,
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in createSupplier: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
    bool? isActive,
  }) async {
    try {
      await _suppliersDao.updateSupplier(
        id,
        SuppliersTableCompanion(
          name: Value(name),
          contactName: Value(contactName),
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          taxId: Value(taxId),
          notes: Value(notes),
          isActive: isActive != null ? Value(isActive) : const Value.absent(),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.supplierUpdated,
        entityType: 'supplier',
        entityId: id,
        entityName: name,
        description: 'Supplier $name updated',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in updateSupplier: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      final existing = await _suppliersDao.getById(id);
      await _suppliersDao.softDelete(id);
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.supplierDeleted,
        entityType: 'supplier',
        entityId: id,
        entityName: existing?.name,
        description: 'Supplier ${existing?.name ?? id} deleted',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in deleteSupplier: $e\n$st');
      rethrow;
    }
  }

  // ── Purchase Orders ─────────────────────────────────────────────────────────

  @override
  Stream<List<PurchaseOrder>> watchPurchaseOrders(String businessId) {
    return _purchaseOrdersDao.watchByBusinessIdWithProgress(businessId).map(
      (rows) => rows
          .map(
            (r) => PurchaseOrder.fromRow(
              r.po,
              quantityOrdered: r.ordered,
              quantityReceived: r.received,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders(String businessId) async {
    final rows = await _purchaseOrdersDao.getByBusinessId(businessId);
    return rows.map((r) => PurchaseOrder.fromRow(r)).toList();
  }

  @override
  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final row = await _purchaseOrdersDao.getById(id);
    if (row == null) return null;
    final lineRows = await _purchaseOrderLinesDao.getByPoId(id);
    final lines = lineRows.map(PurchaseOrderLine.fromRow).toList();
    return PurchaseOrder.fromRow(row, lines: lines);
  }

  @override
  Stream<List<PurchaseOrderLine>> watchPurchaseOrderLines(String poId) {
    return _purchaseOrderLinesDao
        .watchByPoId(poId)
        .map((rows) => rows.map(PurchaseOrderLine.fromRow).toList());
  }

  @override
  Future<List<PurchaseOrderLine>> getPurchaseOrderLines(String poId) async {
    final rows = await _purchaseOrderLinesDao.getByPoId(poId);
    return rows.map(PurchaseOrderLine.fromRow).toList();
  }

  @override
  Future<String> createPurchaseOrder({
    required String businessId,
    String? branchId,
    String? supplierId,
    String? supplierName,
    String? notes,
    DateTime? expectedDelivery,
    required String createdById,
    required String createdByName,
    required List<PoLineInput> lines,
  }) async {
    try {
      final id = _uuid.v4();
      final poNumber = _generatePoNumber();
      // Round the sum too — adding already-rounded line totals can still
      // drift by a fraction of a cent after enough lines.
      final total =
          (lines.fold(0.0, (s, l) => s + l.totalCost) * 100).round() / 100;

      await _purchaseOrdersDao.insert(
        PurchaseOrdersTableCompanion.insert(
          id: id,
          businessId: businessId,
          branchId: Value(branchId),
          supplierId: Value(supplierId),
          supplierName: Value(supplierName),
          poNumber: poNumber,
          notes: Value(notes),
          expectedDelivery: Value(expectedDelivery),
          totalAmount: Value(total),
          createdById: Value(createdById),
          createdByName: Value(createdByName),
          syncStatus: Value(SyncStatus.pendingUpload.toInt()),
        ),
      );

      await _purchaseOrderLinesDao.insertAll(
        lines.map((l) => _lineCompanion(id, businessId, l)).toList(),
      );

      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderCreated,
        entityType: 'purchase_order',
        entityId: id,
        entityName: poNumber,
        description: 'Purchase order $poNumber created',
        metadata: {
          'supplier': supplierName,
          'lines': lines.length,
          'total': total,
        },
        businessId: businessId,
        branchId: branchId,
      );

      return id;
    } catch (e, st) {
      debugPrint('[Procurement] Error in createPurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> updatePurchaseOrder({
    required String id,
    String? notes,
    DateTime? expectedDelivery,
    String? supplierId,
    String? supplierName,
    List<PoLineInput>? lines,
  }) async {
    try {
      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      _assertStatus(po.status, [PoStatus.draft], 'updatePurchaseOrder');

      final rawTotal = lines?.fold(0.0, (s, l) => s + l.totalCost);
      final total = rawTotal != null ? (rawTotal * 100).round() / 100 : null;

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          notes: Value(notes),
          expectedDelivery: Value(expectedDelivery),
          supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
          supplierName: supplierName != null
              ? Value(supplierName)
              : const Value.absent(),
          totalAmount: total != null ? Value(total) : const Value.absent(),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );

      if (lines != null) {
        await _purchaseOrderLinesDao.softDeleteByPoId(id);
        await _purchaseOrderLinesDao.insertAll(
          lines.map((l) => _lineCompanion(id, po.businessId, l)).toList(),
        );
      }

      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderUpdated,
        entityType: 'purchase_order',
        entityId: id,
        entityName: po.poNumber,
        description: 'Purchase order ${po.poNumber} updated',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in updatePurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> submitPurchaseOrder(String id) async {
    try {
      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      _assertStatus(po.status, [PoStatus.draft], 'submitPurchaseOrder');

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          status: const Value('submitted'),
          submittedAt: Value(DateTime.now()),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderSubmitted,
        entityType: 'purchase_order',
        entityId: id,
        entityName: po.poNumber,
        description: 'Purchase order ${po.poNumber} submitted for approval',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in submitPurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> approvePurchaseOrder({
    required String id,
    required String approvedById,
    required String approvedByName,
  }) async {
    try {
      // Authorisation belongs in business logic, not just the cubit — a direct
      // repository call (sync worker, test, future caller) must not bypass it.
      // guard() resolves the permission key via AppPermission and audit-logs
      // any denial.
      final guardResult = await sl<PermissionService>().guard(
        AppPermission.approvePurchaseOrder,
        entityType: 'purchase_order',
        entityId: id,
      );
      if (!guardResult.granted) {
        throw Exception(
          guardResult.deniedReason ?? 'Not authorised to approve purchase orders',
        );
      }

      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      // Only a submitted PO may be approved — matches PoStatus.canApprove.
      _assertStatus(
        po.status,
        [PoStatus.submitted],
        'approvePurchaseOrder',
      );

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          status: const Value('approved'),
          approvedAt: Value(DateTime.now()),
          approvedById: Value(approvedById),
          approvedByName: Value(approvedByName),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderApproved,
        entityType: 'purchase_order',
        entityId: id,
        entityName: po.poNumber,
        description: 'Purchase order ${po.poNumber} approved by $approvedByName',
        metadata: {'approved_by': approvedByName},
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in approvePurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> receiveGoods({
    required String poId,
    required String branchId,
    required List<ReceiveLineInput> lines,
  }) async {
    try {
      final po = await _purchaseOrdersDao.getById(poId);
      if (po == null) throw Exception('PO not found: $poId');
      _assertStatus(
        po.status,
        [PoStatus.approved, PoStatus.partiallyReceived],
        'receiveGoods',
      );

      // Receiving must be atomic: moving-average cost, the stock movement, the
      // PO line's received qty, and the PO status all commit together. A crash
      // mid-loop previously left stock added but the line not marked received,
      // so re-receiving double-counted the goods.
      late final bool allReceived;
      late final String newStatus;
      var unitsReceived = 0.0;
      await _variantsDao.db.transaction(() async {
        for (final receive in lines) {
          if (receive.quantityToReceive <= 0) continue;

          final line = await _purchaseOrderLinesDao.getById(receive.lineId);
          if (line == null) continue;

          // Guard against over-receipt: never accept more than the outstanding
          // balance. A repeated or oversized receive can't inflate stock past
          // what was ordered. Clamp here in business logic, not just the UI.
          final remaining = line.quantityOrdered - line.quantityReceived;
          if (remaining <= 0) continue;
          final qtyToReceive = receive.quantityToReceive > remaining
              ? remaining
              : receive.quantityToReceive;

          // Moving-weighted-average costing.
          // Read current qty BEFORE the stock movement is applied.
          final levelRow =
              await _levelsDao.getLevel(receive.variantId, branchId);
          final currentQty = levelRow != null
              ? (levelRow.quantityDecimal ?? levelRow.quantity.toDouble())
              : 0.0;
          final variant = await _variantsDao.getById(receive.variantId);
          final currentCost = variant?.costPrice ?? 0.0;
          final totalQtyAfter = currentQty + qtyToReceive;
          if (totalQtyAfter > 0) {
            final newCost = (currentQty * currentCost +
                    qtyToReceive * receive.unitCost) /
                totalQtyAfter;
            await _variantsDao.updateCostPrice(receive.variantId, newCost);
          }

          await _stockMovement.apply(
            variantId: receive.variantId,
            productId: receive.productId,
            businessId: po.businessId,
            branchId: branchId,
            isIncoming: true,
            quantity: qtyToReceive,
            reason: 'Purchase',
            note: 'PO ${po.poNumber}',
            sourceType: 'purchase_order',
            sourceId: poId,
          );

          unitsReceived += qtyToReceive;
          final newReceived = line.quantityReceived + qtyToReceive;
          await _purchaseOrderLinesDao.updateLine(
            receive.lineId,
            PurchaseOrderLinesTableCompanion(
              quantityReceived: Value(newReceived),
              syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
              localUpdatedAt: Value(DateTime.now()),
            ),
          );
        }

        // Determine new PO status.
        final allLines = await _purchaseOrderLinesDao.getByPoId(poId);
        allReceived = allLines.every(
          (l) => l.quantityReceived >= l.quantityOrdered,
        );
        newStatus = allReceived
            ? PoStatus.received.value
            : PoStatus.partiallyReceived.value;
        await _purchaseOrdersDao.updatePo(
          poId,
          PurchaseOrdersTableCompanion(
            status: Value(newStatus),
            syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
            localUpdatedAt: Value(DateTime.now()),
          ),
        );
      });

      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderReceived,
        entityType: 'purchase_order',
        entityId: poId,
        entityName: po.poNumber,
        description: allReceived
            ? 'Purchase order ${po.poNumber} fully received'
            : 'Purchase order ${po.poNumber} partially received',
        metadata: {'units_received': unitsReceived, 'status': newStatus},
        branchId: branchId,
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in receiveGoods: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> cancelPurchaseOrder(String id) async {
    try {
      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      final status = PoStatus.fromString(po.status);
      if (!status.canCancel) {
        throw Exception(
          'Cannot cancel PO in status ${po.status}',
        );
      }

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          status: const Value('cancelled'),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderCancelled,
        entityType: 'purchase_order',
        entityId: id,
        entityName: po.poNumber,
        description: 'Purchase order ${po.poNumber} cancelled',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in cancelPurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _generatePoNumber() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix =
        _uuid.v4().replaceAll('-', '').substring(0, 4).toUpperCase();
    return 'PO-$date-$suffix';
  }

  PurchaseOrderLinesTableCompanion _lineCompanion(
    String poId,
    String businessId,
    PoLineInput l,
  ) => PurchaseOrderLinesTableCompanion.insert(
    id: _uuid.v4(),
    purchaseOrderId: poId,
    businessId: businessId,
    productId: l.productId,
    variantId: l.variantId,
    productName: l.productName,
    variantName: l.variantName,
    sku: Value(l.sku),
    quantityOrdered: Value(l.quantityOrdered),
    unitCost: Value(l.unitCost),
    syncStatus: Value(SyncStatus.pendingUpload.toInt()),
  );

  void _assertStatus(
    String currentRaw,
    List<PoStatus> allowed,
    String operation,
  ) {
    final current = PoStatus.fromString(currentRaw);
    if (!allowed.contains(current)) {
      throw Exception(
        '$operation requires status ${allowed.map((s) => s.value).join('/')} '
        'but PO is $currentRaw',
      );
    }
  }
}
