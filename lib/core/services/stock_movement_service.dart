import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';

/// Single entry point for all stock movements.
/// Every module that causes stock to change calls [apply] rather than
/// writing to the three tables directly — ledger + levels + variant total
/// always happen together in one transaction.
class StockMovementService {
  final StockLedgerDao _ledgerDao;
  final InventoryLevelsDao _levelsDao;
  final ProductVariantsDao _variantsDao;

  static const _uuid = Uuid();

  StockMovementService({
    required StockLedgerDao ledgerDao,
    required InventoryLevelsDao levelsDao,
    required ProductVariantsDao variantsDao,
  })  : _ledgerDao = ledgerDao,
        _levelsDao = levelsDao,
        _variantsDao = variantsDao;

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
    // sourceType/sourceId accepted for call-site compat but not stored —
    // stock_ledger table has no such columns in the current schema.
    String? sourceType,
    String? sourceId,
  }) async {
    assert(quantity > 0, 'quantity must be positive');

    final delta = isIncoming ? quantity : -quantity;

    await _ledgerDao.db.transaction(() async {
      final levelBefore = await _levelsDao.getLevel(variantId, branchId);
      final double qtyBefore = _effectiveQty(levelBefore);
      final double qtyAfter = (qtyBefore + delta).clamp(0.0, 999999.0);

      await _ledgerDao.insertEntry(
        StockLedgerTableCompanion.insert(
          id: _uuid.v4(),
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
          createdAt: Value(DateTime.now()),
        ),
      );

      await _levelsDao.adjustQuantity(
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        delta: delta.toInt(),
      );

      // Recompute variant-level total from the sum of all branch levels.
      final allLevels = await _levelsDao.getByVariantId(variantId);
      final newTotal = allLevels.fold(0, (s, l) => s + l.quantity);

      await _variantsDao.db.customUpdate(
        'UPDATE product_variants SET stock = ?, sync_status = 1, '
        'local_updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(newTotal),
          Variable.withDateTime(DateTime.now()),
          Variable.withString(variantId),
        ],
      );
    });
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
    return level?.effectiveQuantity ?? 0.0;
  }
}
