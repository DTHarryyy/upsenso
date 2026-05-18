import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
// ignore: unused_import — StockLedgerTableCompanion generated into app_database
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

class InventoryRepository implements IInventoryRepository {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final BranchesDao _branchesDao;
  final InventoryLevelsDao _levelsDao;
  final StockLedgerDao _ledgerDao;

  static const _uuid = Uuid();

  InventoryRepository({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required BranchesDao branchesDao,
    required InventoryLevelsDao levelsDao,
    required StockLedgerDao ledgerDao,
  }) : _productsDao = productsDao,
       _variantsDao = variantsDao,
       _branchesDao = branchesDao,
       _levelsDao = levelsDao,
       _ledgerDao = ledgerDao;

  /// Emits whenever inventory_levels or stock_ledger changes.
  @override
  Stream<void> watchChanges(String businessId) {
    return _levelsDao.watchByBusinessId(businessId).map((_) {});
  }

  /// Load all inventory items with per-branch stock for [businessId].
  /// If [branchId] is provided, only loads data for that branch.
  @override
  Future<InventoryData> load({
    required String businessId,
    String? branchId,
  }) async {
    final products = await _productsDao.getByBusinessId(businessId);
    final variants = await _variantsDao.getByBusinessId(businessId);
    final rawBranches = await _branchesDao.getByBusinessId(businessId);
    final levels = await _levelsDao.getByBusinessId(businessId);

    // Deduplicate branches by ID (sync can occasionally insert duplicates)
    final seenIds = <String>{};
    final branches = rawBranches.where((b) => seenIds.add(b.id)).toList();

    // branchInfos always contains ALL branches so the dropdown can show
    // every option regardless of which branch is currently selected.
    final branchInfos = branches
        .map((b) => BranchInfo(id: b.id, name: b.name))
        .toList();

    // The branches actually used for computing per-item stock columns.
    // Build a lookup: variantId -> { branchId -> quantity }
    // branchId is now non-nullable (no "global" rows exist post-v17).
    final levelMap = <String, Map<String, int>>{};
    for (final level in levels) {
      levelMap.putIfAbsent(
        level.variantId,
        () => <String, int>{},
      )[level.branchId] = level.quantity;
    }

    final productMap = {for (final p in products) p.id: p};

    // Deduplicate variants by (productId, name) — repeated syncs can insert
    // multiple rows for the same logical variant with different UUIDs.
    // Active variants take priority: sort active first so the dedup always
    // keeps the active row when both an active and inactive copy exist.
    final sortedVariants = [...variants]
      ..sort((a, b) {
        if (a.isActive == b.isActive) return 0;
        return a.isActive ? -1 : 1; // active first
      });
    final seenVariantKeys = <String>{};
    final dedupedVariants = sortedVariants.where((v) {
      return seenVariantKeys.add('${v.productId}:${v.name}');
    }).toList();

    // ignore: avoid_print
    print(
      '[INV] load: ${variants.length} raw variants → ${dedupedVariants.length} after dedup',
    );

    final items = <InventoryItem>[];
    for (final v in dedupedVariants) {
      if (!v.isActive) continue;
      final product = productMap[v.productId];
      if (product == null || !product.isActive) continue;

      final branchStock = levelMap[v.id] ?? {};

      // Always include ALL branches in stockByBranch so per-branch columns in
      // the table show accurate data regardless of which branch is filtered.
      // A missing inventory_levels row means 0 for that branch.
      final stockByBranch = <String, int>{};
      for (final b in branches) {
        stockByBranch[b.id] = branchStock[b.id] ?? 0;
      }

      // Total stock: sum inventory_levels rows. A branch with no rows is 0.
      // product_variants.stock is NOT used as a fallback — it is a sync/seed
      // value only and must not be assigned as a branch's starting stock.
      final int total;
      if (branchId != null) {
        total = branchStock[branchId] ?? 0;
      } else {
        total = branchStock.values.fold(0, (s, q) => s + q);
      }

      // Per-branch low stock threshold: check for override on the level row,
      // fall back to the global threshold on the variant.
      InventoryLevelsTableData? levelRow;
      if (branchId != null) {
        for (final l in levels) {
          if (l.variantId == v.id && l.branchId == branchId) {
            levelRow = l;
            break;
          }
        }
      }
      final reorderLevel = _levelsDao.getEffectiveLowStockAlert(
        levelRow,
        v.lowStockAlert,
      );

      final displayName = v.name == 'Default' ? product.name : product.name;
      final variantLabel = v.name == 'Default' ? '' : v.name;

      items.add(
        InventoryItem(
          variantId: v.id,
          productId: v.productId,
          productName: displayName,
          variantName: variantLabel,
          sku: v.sku ?? product.sku,
          stockByBranch: stockByBranch,
          totalStock: total,
          reorderLevel: reorderLevel,
          trackStock: v.trackStock,
        ),
      );
    }

    items.sort((a, b) => a.productName.compareTo(b.productName));

    return InventoryData(items: items, branches: branchInfos);
  }

  /// Adjust stock for a variant at a branch.
  /// All three writes (ledger, inventory_levels, product_variants) are wrapped
  /// in a single transaction so a crash mid-way leaves no partial state.
  @override
  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    assert(quantity > 0, 'quantity must be positive');

    if (branchId == null) {
      assert(
        false,
        'adjustStock called without branchId — auth context must include a branch',
      );
      return;
    }

    final delta = isIncoming ? quantity : -quantity;

    await _ledgerDao.db.transaction(() async {
      // Snapshot stock BEFORE the adjustment for the ledger audit trail.
      final levelBefore = await _levelsDao.getLevel(variantId, branchId);
      final double qtyBefore = levelBefore?.quantity.toDouble() ?? 0.0;
      final double qtyAfter = (qtyBefore + delta.toDouble()).clamp(
        0.0,
        999999.0,
      );

      // 1. Insert ledger entry (immutable source of truth)
      await _ledgerDao.insertEntry(
        StockLedgerTableCompanion.insert(
          id: _uuid.v4(),
          variantId: variantId,
          productId: productId,
          branchId: branchId,
          businessId: businessId,
          changeType: isIncoming ? 'IN' : 'OUT',
          quantity: quantity.toDouble(),
          quantityBefore: Value(qtyBefore),
          quantityAfter: Value(qtyAfter),
          reason: reason,
          note: Value(note),
          createdAt: Value(DateTime.now()),
        ),
      );

      // 2. Update per-branch inventory_levels
      await _levelsDao.adjustQuantity(
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        delta: delta,
      );

      // 3. Recalculate global total and write to product_variants.stock
      final allLevels = await _levelsDao.getByVariantId(variantId);
      var newTotal = 0;
      for (final level in allLevels) {
        newTotal += level.quantity;
      }

      await _variantsDao.db.customUpdate(
        'UPDATE product_variants SET stock = ?, sync_status = 1, local_updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(newTotal),
          Variable.withDateTime(DateTime.now()),
          Variable.withString(variantId),
        ],
      );
    });
  }

  /// Called at checkout to record each sold item in the ledger, deduct it
  /// from [inventory_levels], and decrement [product_variants.stock].
  ///
  /// Skips variants where [trackStock] is false. Each item's writes are
  /// wrapped in a transaction so a crash mid-item leaves no partial state.
  @override
  Future<void> recordSaleDeductions({
    required List<({String variantId, int qty})> items,
    required String businessId,
    required String? branchId,
  }) async {
    if (branchId == null) {
      assert(false, 'recordSaleDeductions called without branchId');
      return;
    }

    for (final item in items) {
      if (item.qty <= 0) continue;

      final variant = await _variantsDao.getById(item.variantId);
      if (variant == null || !variant.trackStock) continue;

      await _ledgerDao.db.transaction(() async {
        // Snapshot stock BEFORE deduction for the ledger audit trail.
        final levelBefore = await _levelsDao.getLevel(item.variantId, branchId);
        final double qtyBefore = levelBefore?.quantity.toDouble() ?? 0.0;
        final double qtyAfter = (qtyBefore - item.qty.toDouble()).clamp(
          0.0,
          999999.0,
        );

        // 1. Insert stock ledger entry
        await _ledgerDao.insertEntry(
          StockLedgerTableCompanion.insert(
            id: _uuid.v4(),
            variantId: item.variantId,
            productId: variant.productId,
            branchId: branchId,
            businessId: businessId,
            changeType: 'OUT',
            quantity: item.qty.toDouble(),
            quantityBefore: Value(qtyBefore),
            quantityAfter: Value(qtyAfter),
            reason: 'Sale',
            createdAt: Value(DateTime.now()),
          ),
        );

        // 2. Deduct from this branch's inventory_levels row.
        await _levelsDao.adjustQuantity(
          variantId: item.variantId,
          branchId: branchId,
          businessId: businessId,
          delta: -item.qty,
        );

        // 3. Decrement product_variants.stock
        await _variantsDao.decrementStockIfTracked(
          item.variantId,
          item.qty.toDouble(),
        );
      });
    }
  }
}
