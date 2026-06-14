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
    // Traceability: what document caused this movement and its id. Stored on the
    // ledger so audit/fraud queries can tell a sale from a manual adjustment.
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
          sourceType: Value(sourceType),
          sourceId: Value(sourceId),
          createdAt: Value(DateTime.now()),
        ),
      );

      // A movement is fractional when the variant tracks decimals or the
      // quantity itself is not a whole number. Routing those through the int
      // path truncates the fraction and silently drops stock (e.g. selling
      // 0.5 kg deducts nothing). Whole-unit movements keep the int path so
      // existing unit-product behaviour is unchanged.
      final variant = await _variantsDao.getById(variantId);
      final bool fractional =
          variant?.stockDecimal != null || delta != delta.roundToDouble();

      await _levelsDao.adjustQuantity(
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        delta: delta.round(),
        deltaDecimal: fractional ? delta : null,
      );

      // Recompute variant-level total from the sum of all branch levels using
      // the effective (decimal-aware) quantity, not the raw int column.
      final allLevels = await _levelsDao.getByVariantId(variantId);
      final double newTotal =
          allLevels.fold(0.0, (s, l) => s + l.effectiveQuantity);

      await _variantsDao.db.customUpdate(
        'UPDATE product_variants SET stock = ?, stock_decimal = ?, '
        'sync_status = 1, local_updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(newTotal.round()),
          Variable<double>(fractional ? newTotal : null),
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
