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

class InventoryRepository {
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
  })  : _productsDao = productsDao,
        _variantsDao = variantsDao,
        _branchesDao = branchesDao,
        _levelsDao = levelsDao,
        _ledgerDao = ledgerDao;

  /// Emits whenever inventory_levels or stock_ledger changes.
  Stream<void> watchChanges(String businessId) {
    return _levelsDao.watchByBusinessId(businessId).map((_) {});
  }

  /// Load all inventory items with per-branch stock for [businessId].
  /// If [branchId] is provided, only loads data for that branch.
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
    final branches =
        rawBranches.where((b) => seenIds.add(b.id)).toList();

    // branchInfos always contains ALL branches so the dropdown can show
    // every option regardless of which branch is currently selected for filtering.
    final branchInfos =
        branches.map((b) => BranchInfo(id: b.id, name: b.name)).toList();

    // The branches actually used for computing per-item stock columns.
    // When a branch filter is active only that branch is shown; otherwise all.
    final visibleBranches = branchId != null
        ? branches.where((b) => b.id == branchId).toList()
        : branches;

    // Build a lookup: variantId -> { branchId -> quantity }
    final levelMap = <String, Map<String?, int>>{};
    for (final level in levels) {
      levelMap.putIfAbsent(level.variantId, () => <String?, int>{})[level.branchId] =
          level.quantity;
    }

    final productMap = {for (final p in products) p.id: p};

    // Deduplicate variants by (productId, name) — repeated syncs can insert
    // multiple rows for the same logical variant with different UUIDs.
    final seenVariantKeys = <String>{};
    final dedupedVariants = variants.where((v) {
      return seenVariantKeys.add('${v.productId}:${v.name}');
    }).toList();

    // ignore: avoid_print
    print('[INV] load: ${variants.length} raw variants → ${dedupedVariants.length} after dedup');

    final items = <InventoryItem>[];
    for (final v in dedupedVariants) {
      if (!v.isActive) continue;
      final product = productMap[v.productId];
      if (product == null || !product.isActive) continue;

      final branchStock = levelMap[v.id] ?? {};

      // Compute per-branch stock for the visible (filtered) branches only.
      final stockByBranch = <String, int>{};
      for (final b in visibleBranches) {
        stockByBranch[b.id] = branchStock[b.id] ?? 0;
      }

      // Total: sum of all known inventory_levels rows, or fall back to
      // product_variants.stock if no levels exist yet
      final int total;
      if (branchStock.isEmpty) {
        total = v.stock;
      } else if (branchId != null) {
        total = branchStock[branchId] ?? 0;
      } else {
        total = branchStock.values.fold(0, (s, q) => s + q);
      }

      final displayName = v.name == 'Default' ? product.name : product.name;
      final variantLabel = v.name == 'Default' ? '' : v.name;

      items.add(InventoryItem(
        variantId: v.id,
        productId: v.productId,
        productName: displayName,
        variantName: variantLabel,
        sku: v.sku ?? product.sku,
        stockByBranch: stockByBranch,
        totalStock: total,
        reorderLevel: v.lowStockAlert ?? 0,
      ));
    }

    items.sort((a, b) => a.productName.compareTo(b.productName));

    return InventoryData(items: items, branches: branchInfos);
  }

  /// Adjust stock for a variant at a branch.
  /// Always creates a stock_ledger entry first, then updates inventory_levels
  /// and product_variants.stock (total).
  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming, // true = IN, false = OUT
    required int quantity,
    required String reason,
    String? note,
  }) async {
    assert(quantity > 0, 'quantity must be positive');

    // 1. Insert ledger entry (source of truth for history)
    await _ledgerDao.insertEntry(
      StockLedgerTableCompanion.insert(
        id: _uuid.v4(),
        variantId: variantId,
        productId: productId,
        branchId: Value(branchId),
        businessId: businessId,
        changeType: isIncoming ? 'IN' : 'OUT',
        quantity: quantity,
        reason: reason,
        note: Value(note),
        createdAt: Value(DateTime.now()),
      ),
    );

    // 2. Update per-branch inventory_levels
    final delta = isIncoming ? quantity : -quantity;
    await _levelsDao.adjustQuantity(
      variantId: variantId,
      branchId: branchId,
      businessId: businessId,
      delta: delta,
    );

    // 3. Recalculate total and write directly to product_variants.stock
    final allLevels = await _levelsDao.getByVariantId(variantId);
    var newTotal = 0;
    for (final level in allLevels) {
      // ignore: avoid_dynamic_calls
      newTotal += (level as dynamic)?.quantity as int? ?? 0;
    }

    await _variantsDao.db.customUpdate(
      'UPDATE product_variants SET stock = ?, sync_status = 1, local_updated_at = ? WHERE id = ?',
      variables: [
        Variable.withInt(newTotal),
        Variable.withDateTime(DateTime.now()),
        Variable.withString(variantId),
      ],
    );
  }

  /// Called at checkout to record each sold item in the ledger, deduct it
  /// from [inventory_levels], and decrement [product_variants.stock].
  ///
  /// Only processes variants that have [trackStock] enabled.
  ///
  /// Order matters: the variant's stock is captured BEFORE decrementing it so
  /// that [adjustQuantity] seeds a new [inventory_levels] row from the correct
  /// pre-sale quantity, avoiding double-deduction.
  Future<void> recordSaleDeductions({
    required List<({String variantId, int qty})> items,
    required String businessId,
    required String? branchId,
  }) async {
    for (final item in items) {
      if (item.qty <= 0) continue;

      final variant = await _variantsDao.getById(item.variantId);
      if (variant == null) continue;

      final originalStock = variant.stock;

      // 1. Insert stock ledger entry
      await _ledgerDao.insertEntry(
        StockLedgerTableCompanion.insert(
          id: _uuid.v4(),
          variantId: item.variantId,
          productId: variant.productId,
          branchId: Value(branchId),
          businessId: businessId,
          changeType: 'OUT',
          quantity: item.qty,
          reason: 'Sale',
          createdAt: Value(DateTime.now()),
        ),
      );

      // 2. Deduct from inventory_levels; seed from pre-sale stock when no row
      //    exists yet (first sale for this variant+branch combination).
      await _levelsDao.adjustQuantity(
        variantId: item.variantId,
        branchId: branchId,
        businessId: businessId,
        delta: -item.qty,
        seedQuantity: originalStock,
      );

      // 3. Decrement product_variants.stock (only when trackStock=true)
      await _variantsDao.decrementStockIfTracked(
          item.variantId, item.qty.toDouble());
    }
  }
}
