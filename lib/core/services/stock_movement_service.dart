import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/services/fraud_detection_engine.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// Single entry point for all stock movements.
/// Every module that causes stock to change calls [apply] rather than
/// writing to the three tables directly — ledger + levels + variant total
/// always happen together in one transaction.
///
/// Manual movements (no automated source document) are audit-logged HERE so
/// no adjustment path can skip the tamper-evident chain. Sale / PO / recipe
/// movements are already covered by their own audit events — logging them
/// again would double the chain volume for every sale.
class StockMovementService {
  final StockLedgerDao _ledgerDao;
  final InventoryLevelsDao _levelsDao;
  final ProductVariantsDao _variantsDao;
  final AuditLogService _auditLogService;
  final FraudDetectionEngine? _fraudEngine;

  static const _uuid = Uuid();

  StockMovementService({
    required StockLedgerDao ledgerDao,
    required InventoryLevelsDao levelsDao,
    required ProductVariantsDao variantsDao,
    required AuditLogService auditLogService,
    FraudDetectionEngine? fraudEngine,
  })  : _ledgerDao = ledgerDao,
        _levelsDao = levelsDao,
        _variantsDao = variantsDao,
        _auditLogService = auditLogService,
        _fraudEngine = fraudEngine;

  /// Apply a stock movement atomically.
  /// [isIncoming] true = stock IN, false = stock OUT.
  /// [quantity] must be positive; direction is controlled by [isIncoming].
  Future<void> apply({
    required String variantId,
    required String productId,
    required String businessId,
    required String branchId,
    required bool isIncoming,
    required double quantity,
    required String reason,
    String? note,
    // Traceability: what document caused this movement and its id. Stored on the
    // ledger so audit/fraud queries can tell a sale from a manual adjustment.
    String? sourceType,
    String? sourceId,
  }) async {
    assert(quantity > 0, 'quantity must be positive');

    final delta = isIncoming ? quantity : -quantity;
    final ledgerId = _uuid.v4();
    // Manual movement = no automated source document behind it. It's the one
    // stock path that must carry its own audit entry (ORPHANED_RECORD checks
    // stock_ledger too), so it stages the entry INSIDE the transaction.
    final isManual = sourceType == null || sourceType == 'adjustment';

    await _ledgerDao.db.transaction(() async {
      final levelBefore = await _levelsDao.getLevel(variantId, branchId);
      final double qtyBefore = _effectiveQty(levelBefore);
      final double qtyAfter = (qtyBefore + delta).clamp(0.0, 999999.0);

      await _ledgerDao.insertEntry(
        StockLedgerTableCompanion.insert(
          id: ledgerId,
          variantId: variantId,
          productId: productId,
          branchId: branchId,
          businessId: businessId,
          changeType: isIncoming ? 'IN' : 'OUT',
          quantity: quantity,
          quantityBefore: Value(qtyBefore),
          quantityAfter: Value(qtyAfter),
          reason: reason,
          note: Value(note),
          sourceType: Value(sourceType),
          sourceId: Value(sourceId),
          createdAt: Value(DateTime.now()),
        ),
      );

      // Single decimal quantity — holds whole units and fractions alike, so
      // there's no int path to truncate a fractional movement (e.g. 0.5 kg).
      await _levelsDao.adjustQuantity(
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        delta: delta,
      );

      // Recompute the variant-level total from the sum of all branch levels.
      final allLevels = await _levelsDao.getByVariantId(variantId);
      final double newTotal = allLevels.fold(0.0, (s, l) => s + l.quantity);

      await _variantsDao.db.customUpdate(
        'UPDATE product_variants SET stock = ?, '
        'sync_status = 1, local_updated_at = ? WHERE id = ?',
        variables: [
          Variable<double>(newTotal),
          Variable.withDateTime(DateTime.now()),
          Variable.withString(variantId),
        ],
      );

      if (isManual) {
        final variant = await _variantsDao.getById(variantId);
        final label = variant?.name ?? variantId;
        // Staged with the ledger write — the adjustment and its audit intent
        // commit together, so a write-off can never exist without its audit
        // trail (the stock-side of the 2026-07-03 orphan false positive).
        await _auditLogService.enqueueInTransaction(
          actionType: AuditLogActionType.stockAdjusted,
          entityType: 'stock_ledger',
          entityId: ledgerId,
          entityName: label,
          description:
              '${isIncoming ? 'Stock in' : 'Stock out'}: $quantity of $label — $reason',
          metadata: {
            'is_incoming': isIncoming,
            'quantity': quantity,
            'quantity_before': qtyBefore,
            'quantity_after': qtyAfter,
            'reason': reason,
            'note': ?note,
            'variant_id': variantId,
            'product_id': productId,
          },
          businessId: businessId,
          branchId: branchId,
        );
      }
    });

    if (isManual) {
      // Post-commit, fire-and-forget: materialize the staged entry, then run
      // the shrinkage rule right away instead of waiting for a sweep.
      unawaited(_auditLogService.drainOutbox());
      _fraudEngine?.runIncremental(const {'SHRINKAGE_SPIKE'});
    }
  }

  /// Convenience wrapper for integer-quantity (unit) products.
  Future<void> applyInt({
    required String variantId,
    required String productId,
    required String businessId,
    required String branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
    String? sourceType,
    String? sourceId,
  }) =>
      apply(
        variantId: variantId,
        productId: productId,
        businessId: businessId,
        branchId: branchId,
        isIncoming: isIncoming,
        quantity: quantity.toDouble(),
        reason: reason,
        note: note,
        sourceType: sourceType,
        sourceId: sourceId,
      );

  double _effectiveQty(InventoryLevelsTableData? level) {
    return level?.quantity ?? 0.0;
  }
}
