import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';

/// Handles inventory deductions for recipe-based products.
/// Called by [InventoryRepository] when tracking_method='recipe'.
class RecipeConsumptionService {
  final RecipeLinesDao _recipeLinesDao;
  final StockLedgerDao _ledgerDao;
  final ProductVariantsDao _variantsDao;
  final InventoryLevelsDao _levelsDao;

  static const _uuid = Uuid();

  RecipeConsumptionService({
    required RecipeLinesDao recipeLinesDao,
    required StockLedgerDao ledgerDao,
    required ProductVariantsDao variantsDao,
    required InventoryLevelsDao levelsDao,
  }) : _recipeLinesDao = recipeLinesDao,
       _ledgerDao = ledgerDao,
       _variantsDao = variantsDao,
       _levelsDao = levelsDao;

  /// Deducts ingredient stock for [qty] units sold of [productVariantId].
  /// [sourceId] (the sale's transaction id) is stamped on the stock ledger
  /// entries so server-side RLS can verify the deduction traces to a real sale.
  Future<void> consume({
    required String productVariantId,
    required int qty,
    required String businessId,
    required String branchId,
    required String sourceId,
    bool allowNegativeStock = false,
  }) async {
    final lines = await _recipeLinesDao.getByVariantId(productVariantId);
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final needed = line.quantity * qty;
      final ingredientVariant = await _variantsDao.getById(
        line.ingredientVariantId,
      );
      if (ingredientVariant == null) {
        debugPrint(
          '[Recipe] consume: ingredient variant ${line.ingredientVariantId} not found — skipping',
        );
        continue;
      }

      await _ledgerDao.db.transaction(() async {
        final levelBefore = await _levelsDao.getLevel(
          line.ingredientVariantId,
          branchId,
        );
        final double qtyBefore = levelBefore?.quantity ?? 0.0;
        final rawQtyAfter = qtyBefore - needed;
        final double qtyAfter = allowNegativeStock
            ? rawQtyAfter
            : rawQtyAfter.clamp(0.0, 999999.0);

        await _ledgerDao.insertEntry(
          StockLedgerTableCompanion.insert(
            id: _uuid.v4(),
            variantId: line.ingredientVariantId,
            productId: ingredientVariant.productId,
            branchId: branchId,
            businessId: businessId,
            changeType: 'OUT',
            quantity: needed,
            quantityBefore: Value(qtyBefore),
            quantityAfter: Value(qtyAfter),
            reason: 'Recipe consumption',
            sourceType: const Value('recipe_consumption'),
            sourceId: Value(sourceId),
            createdAt: Value(DateTime.now()),
          ),
        );

        await _levelsDao.adjustQuantity(
          variantId: line.ingredientVariantId,
          branchId: branchId,
          businessId: businessId,
          delta: -needed,
          allowNegativeStock: allowNegativeStock,
        );

        // Recompute the denormalized total from branch levels. This preserves
        // an approved negative balance instead of silently clamping the
        // ingredient variant to zero.
        final allLevels = await _levelsDao.getByVariantId(
          line.ingredientVariantId,
        );
        final double newTotal = allLevels.fold(
          0.0,
          (sum, level) => sum + level.quantity,
        );
        await _variantsDao.db.customUpdate(
          'UPDATE product_variants SET stock = ?, '
          'sync_status = 1, local_updated_at = ? WHERE id = ?',
          variables: [
            Variable<double>(newTotal),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(line.ingredientVariantId),
          ],
        );
      });
    }
  }

  /// Restores ingredient stock for [qty] units refunded of [productVariantId].
  /// Inverse of [consume] — same recipe lines, opposite direction.
  /// [sourceId] (the refund's id) is stamped on the stock ledger entries so
  /// server-side RLS can verify the restock traces to a real refund — never
  /// falls back to [productVariantId], which wouldn't pass that check.
  Future<void> restore({
    required String productVariantId,
    required int qty,
    required String businessId,
    required String branchId,
    required String sourceId,
  }) async {
    final lines = await _recipeLinesDao.getByVariantId(productVariantId);
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final returned = line.quantity * qty;
      final ingredientVariant = await _variantsDao.getById(
        line.ingredientVariantId,
      );
      if (ingredientVariant == null) {
        debugPrint(
          '[Recipe] restore: ingredient variant ${line.ingredientVariantId} not found — skipping',
        );
        continue;
      }

      await _ledgerDao.db.transaction(() async {
        final levelBefore = await _levelsDao.getLevel(
          line.ingredientVariantId,
          branchId,
        );
        final double qtyBefore = levelBefore?.quantity ?? 0.0;
        final double qtyAfter = (qtyBefore + returned).clamp(0.0, 999999.0);

        await _ledgerDao.insertEntry(
          StockLedgerTableCompanion.insert(
            id: _uuid.v4(),
            variantId: line.ingredientVariantId,
            productId: ingredientVariant.productId,
            branchId: branchId,
            businessId: businessId,
            changeType: 'IN',
            quantity: returned,
            quantityBefore: Value(qtyBefore),
            quantityAfter: Value(qtyAfter),
            reason: 'Refund',
            sourceType: const Value('refund'),
            sourceId: Value(sourceId),
            createdAt: Value(DateTime.now()),
          ),
        );

        await _levelsDao.adjustQuantity(
          variantId: line.ingredientVariantId,
          branchId: branchId,
          businessId: businessId,
          delta: returned,
        );

        // Recompute the variant-level total from the sum of all branch
        // levels (decimal-aware), same as StockMovementService.apply —
        // keeps the denormalized variant total from drifting out of sync
        // with the per-branch ledger it's derived from.
        final allLevels = await _levelsDao.getByVariantId(
          line.ingredientVariantId,
        );
        final double newTotal = allLevels.fold(0.0, (s, l) => s + l.quantity);
        await _variantsDao.db.customUpdate(
          'UPDATE product_variants SET stock = ?, '
          'sync_status = 1, local_updated_at = ? WHERE id = ?',
          variables: [
            Variable<double>(newTotal),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(line.ingredientVariantId),
          ],
        );
      });
    }
  }

  /// Returns how many units of [productVariantId] can currently be made,
  /// limited by whichever ingredient is most constrained.
  /// Returns null when there are no recipe lines (treat as unlimited).
  Future<double?> availableUnits({
    required String productVariantId,
    required String branchId,
  }) async {
    final lines = await _recipeLinesDao.getByVariantId(productVariantId);
    if (lines.isEmpty) return null;

    double? minUnits;
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final level = await _levelsDao.getLevel(
        line.ingredientVariantId,
        branchId,
      );
      final available = level?.quantity ?? 0.0;
      final units = available / line.quantity;
      if (minUnits == null || units < minUnits) minUnits = units;
    }
    return minUnits;
  }
}
