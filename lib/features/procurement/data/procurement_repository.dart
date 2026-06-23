import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/goods_receipt_items_dao.dart';
import 'package:pos/core/database/daos/goods_receipts_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/procurement_settings_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/core/services/po_number_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/features/procurement/domain/entities/approval_policy.dart';
import 'package:pos/features/procurement/domain/entities/goods_receipt.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/procurement_settings.dart';
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
  final PoNumberService _poNumberService;
  final ProcurementSettingsDao _settingsDao;
  final GoodsReceiptsDao _receiptsDao;
  final GoodsReceiptItemsDao _receiptItemsDao;
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
    required PoNumberService poNumberService,
    required ProcurementSettingsDao settingsDao,
    required GoodsReceiptsDao receiptsDao,
    required GoodsReceiptItemsDao receiptItemsDao,
    ProcurementRemoteDs? remoteDs,
  }) : _suppliersDao = suppliersDao,
       _purchaseOrdersDao = purchaseOrdersDao,
       _purchaseOrderLinesDao = purchaseOrderLinesDao,
       _variantsDao = variantsDao,
       _levelsDao = levelsDao,
       _stockMovement = stockMovement,
       _poNumberService = poNumberService,
       _settingsDao = settingsDao,
       _receiptsDao = receiptsDao,
       _receiptItemsDao = receiptItemsDao,
       _remoteDs = remoteDs;

  @override
  Stream<List<GoodsReceipt>> watchReceipts(String poId) {
    return _receiptsDao
        .watchByPoId(poId)
        .map((rows) => rows.map(GoodsReceipt.fromRow).toList());
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  @override
  Future<ProcurementSettings> getSettings(String businessId) async {
    final row = await _settingsDao.getByBusinessId(businessId);
    return ProcurementSettings(
      businessId: businessId,
      approvalThreshold: row?.approvalThreshold,
    );
  }

  @override
  Future<void> updateApprovalThreshold(
    String businessId,
    double? threshold,
  ) async {
    try {
      await _settingsDao.upsert(
        ProcurementSettingsTableCompanion.insert(
          businessId: businessId,
          approvalThreshold: Value(threshold),
          syncStatus: Value(SyncStatus.pendingUpload.toInt()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      // Best-effort remote write so the server RLS check sees the same threshold.
      // Offline failures are non-fatal — local stays the source of truth.
      try {
        await _remoteDs?.upsertApprovalThreshold(businessId, threshold);
      } catch (e, st) {
        debugPrint('[Procurement] threshold remote upsert deferred: $e\n$st');
      }
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.businessModuleChanged,
        entityType: 'procurement_settings',
        entityId: businessId,
        description: threshold == null
            ? 'PO approval threshold cleared'
            : 'PO approval threshold set to $threshold',
        businessId: businessId,
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in updateApprovalThreshold: $e\n$st');
      rethrow;
    }
  }

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
    double discount = 0,
    double shipping = 0,
    required String createdById,
    required String createdByName,
    required List<PoLineInput> lines,
  }) async {
    try {
      final id = _uuid.v4();
      // Sequential, gapless per-business number (online RPC; offline local
      // counter) — replaces the old random suffix.
      final poNumber = await _poNumberService.claimNext(businessId);
      // Total = subtotal - discount + shipping, rounded to cents.
      final total = _orderTotal(lines, discount, shipping);

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
          discount: Value(discount),
          shipping: Value(shipping),
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
    double? discount,
    double? shipping,
    List<PoLineInput>? lines,
  }) async {
    try {
      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      _assertStatus(po.status, [PoStatus.draft], 'updatePurchaseOrder');

      final effDiscount = discount ?? po.discount;
      final effShipping = shipping ?? po.shipping;
      // Recompute the total when lines, discount, or shipping change. Without new
      // lines, reconstruct the subtotal from the stored total.
      double? total;
      if (lines != null) {
        total = _orderTotal(lines, effDiscount, effShipping);
      } else if (discount != null || shipping != null) {
        final subtotal = po.totalAmount + po.discount - po.shipping;
        total = ((subtotal - effDiscount + effShipping) * 100).round() / 100;
      }

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          notes: Value(notes),
          expectedDelivery: Value(expectedDelivery),
          supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
          supplierName: supplierName != null
              ? Value(supplierName)
              : const Value.absent(),
          discount: discount != null ? Value(discount) : const Value.absent(),
          shipping: shipping != null ? Value(shipping) : const Value.absent(),
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

      // Separation of duties: above the business threshold, a non-owner cannot
      // approve their own PO — a different approver is required. Owners and
      // below-threshold (or unset) orders are exempt. App-level backstop; the
      // RLS policy mirrors this server-side.
      if (approvedById == po.createdById) {
        final settings = await getSettings(po.businessId);
        if (ApprovalPolicy.requiresSeparateApprover(
          total: po.totalAmount,
          threshold: settings.approvalThreshold,
          actorIsOwner: sl<PermissionService>().isOwnerRole,
        )) {
          throw Exception(
            'This purchase order is above the approval threshold and must be '
            'approved by a different person.',
          );
        }
      }

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
    String? receivedById,
    String? receivedByName,
  }) async {
    try {
      // A blank branch would write stock to an empty branch id — orphan
      // inventory that shows in no real branch. Refuse it outright.
      if (branchId.trim().isEmpty) {
        throw Exception('Cannot receive goods without a branch.');
      }
      final po = await _purchaseOrdersDao.getById(poId);
      if (po == null) throw Exception('PO not found: $poId');
      _assertStatus(
        po.status,
        [PoStatus.approved, PoStatus.partiallyReceived],
        'receiveGoods',
      );

      // Receipt number claimed up front (its own counter); a gap on rollback is
      // acceptable, like invoice numbers.
      final receiptId = _uuid.v4();
      final receiptNumber =
          await _poNumberService.claimNextReceipt(po.businessId);
      final receiptItems = <GoodsReceiptItemsTableCompanion>[];

      // Receiving must be atomic: moving-average cost, the stock movement, the
      // PO line's received qty, the GRN document, and the PO status all commit
      // together. A crash mid-loop previously left stock added but the line not
      // marked received, so re-receiving double-counted the goods.
      late final bool allReceived;
      late final String newStatus;
      var unitsReceived = 0.0;
      await _variantsDao.db.transaction(() async {
        // Landed-cost basis: spread order-level shipping (raises cost) and
        // discount (lowers it) across lines by value share, so the moving-average
        // reflects the true cost per unit. Computed once for the whole order.
        final orderLines = await _purchaseOrderLinesDao.getByPoId(poId);
        final orderSubtotal = orderLines.fold<double>(
          0,
          (s, l) => s + l.quantityOrdered * l.unitCost,
        );
        final netAdjust = po.shipping - po.discount;

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

          // Landed unit cost for this line = unit cost + its share of
          // (shipping - discount) spread over the line's ordered units.
          final lineSubtotal = line.quantityOrdered * line.unitCost;
          final lineShare =
              orderSubtotal > 0 ? lineSubtotal / orderSubtotal : 0.0;
          final perUnitAdjust = line.quantityOrdered > 0
              ? (netAdjust * lineShare) / line.quantityOrdered
              : 0.0;
          final landedUnitCost = line.unitCost + perUnitAdjust;

          // Moving-weighted-average costing on the landed unit cost.
          // Read current qty BEFORE the stock movement is applied.
          final levelRow =
              await _levelsDao.getLevel(receive.variantId, branchId);
          final currentQty = levelRow?.quantity ?? 0.0;
          final variant = await _variantsDao.getById(receive.variantId);
          final currentCost = variant?.costPrice ?? 0.0;
          final totalQtyAfter = currentQty + qtyToReceive;
          if (totalQtyAfter > 0) {
            final newCost = (currentQty * currentCost +
                    qtyToReceive * landedUnitCost) /
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

          // Capture this line on the GRN document.
          receiptItems.add(
            GoodsReceiptItemsTableCompanion.insert(
              id: _uuid.v4(),
              businessId: po.businessId,
              goodsReceiptId: receiptId,
              purchaseOrderLineId: receive.lineId,
              variantId: receive.variantId,
              productId: receive.productId,
              productName: line.productName,
              quantityReceived: Value(qtyToReceive),
              unitCost: Value(landedUnitCost),
              syncStatus: Value(SyncStatus.pendingUpload.toInt()),
            ),
          );
        }

        // Record the GRN document for this receiving event (only if anything
        // was actually received).
        if (receiptItems.isNotEmpty) {
          await _receiptsDao.insert(
            GoodsReceiptsTableCompanion.insert(
              id: receiptId,
              businessId: po.businessId,
              purchaseOrderId: poId,
              branchId: branchId,
              receiptNumber: receiptNumber,
              receivedById: Value(receivedById),
              receivedByName: Value(receivedByName),
              syncStatus: Value(SyncStatus.pendingUpload.toInt()),
            ),
          );
          await _receiptItemsDao.insertAll(receiptItems);
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

  @override
  Future<void> closePurchaseOrder(String id) async {
    try {
      final po = await _purchaseOrdersDao.getById(id);
      if (po == null) throw Exception('PO not found: $id');
      final status = PoStatus.fromString(po.status);
      if (!status.canClose) {
        throw Exception('Cannot close PO in status ${po.status}');
      }

      await _purchaseOrdersDao.updatePo(
        id,
        PurchaseOrdersTableCompanion(
          status: const Value('closed'),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.purchaseOrderUpdated,
        entityType: 'purchase_order',
        entityId: id,
        entityName: po.poNumber,
        description:
            'Purchase order ${po.poNumber} closed with outstanding quantity',
      );
    } catch (e, st) {
      debugPrint('[Procurement] Error in closePurchaseOrder: $e\n$st');
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  // Order total = subtotal - discount + shipping, rounded to cents. Rounding the
  // sum (not just line totals) avoids fractional-cent drift across many lines.
  double _orderTotal(List<PoLineInput> lines, double discount, double shipping) {
    final subtotal = lines.fold(0.0, (s, l) => s + l.totalCost);
    return ((subtotal - discount + shipping) * 100).round() / 100;
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
