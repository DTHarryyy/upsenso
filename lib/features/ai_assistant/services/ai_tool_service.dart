import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:uuid/uuid.dart';

/// Layer 5 — Tool / Action Layer: All database operations for the AI assistant.
///
/// RULES:
/// - Uses Drift ONLY
/// - No AI logic here
/// - Fully deterministic
/// - AI NEVER directly writes to DB — only this layer does
class AiToolService {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final TransactionsDao _transactionsDao;
  final AppDatabase _db;

  AiToolService({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required TransactionsDao transactionsDao,
    required AppDatabase db,
  })  : _productsDao = productsDao,
        _variantsDao = variantsDao,
        _transactionsDao = transactionsDao,
        _db = db;

  // ─── SALES QUERIES ──────────────────────────────────────────────────────

  /// Get total sales amount for a business within a date range.
  Future<double> getSalesTotal(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) AS total '
      'FROM transactions '
      'WHERE created_at >= ? AND created_at < ? '
      'AND (branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (branch_id IS NULL AND cashier_id = ?))',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    ).getSingle();

    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get sales grouped by category.
  /// Returns a list of { category, total } maps.
  Future<List<CategorySalesResult>> getSalesByCategory(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final rows = await _db.customSelect(
      'SELECT COALESCE(c.name, \'Uncategorized\') AS category_name, '
      'SUM(ti.line_total) AS total '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'JOIN product_variants pv ON pv.id = ti.variant_id '
      'JOIN products p ON p.id = pv.product_id '
      'LEFT JOIN categories c ON c.id = p.category_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      'AND (t.branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (t.branch_id IS NULL AND t.cashier_id = ?)) '
      'GROUP BY c.name '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    ).get();

    return rows.map((r) {
      return CategorySalesResult(
        category: r.data['category_name'] as String? ?? 'Uncategorized',
        total: (r.data['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Get sales grouped by product.
  /// Returns a list of { product, total, quantity } maps.
  Future<List<ProductSalesResult>> getSalesByProduct(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final rows = await _db.customSelect(
      'SELECT ti.product_name, '
      'SUM(ti.line_total) AS total, '
      'SUM(ti.qty) AS quantity '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      'AND (t.branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (t.branch_id IS NULL AND t.cashier_id = ?)) '
      'GROUP BY ti.product_name '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    ).get();

    return rows.map((r) {
      return ProductSalesResult(
        productName: r.data['product_name'] as String? ?? '',
        total: (r.data['total'] as num?)?.toDouble() ?? 0.0,
        quantity: (r.data['quantity'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Get sales filtered by a specific category name.
  Future<double> getSalesBySpecificCategory(
    String businessId,
    String cashierId,
    String categoryName,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(ti.line_total), 0) AS total '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'JOIN product_variants pv ON pv.id = ti.variant_id '
      'JOIN products p ON p.id = pv.product_id '
      'LEFT JOIN categories c ON c.id = p.category_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      'AND (t.branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (t.branch_id IS NULL AND t.cashier_id = ?)) '
      'AND LOWER(c.name) = LOWER(?)',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
        Variable.withString(categoryName),
      ],
    ).getSingle();

    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── PRODUCT QUERIES ───────────────────────────────────────────────────

  /// Get sales filtered by a specific product name.
  Future<ProductSalesResult?> getSalesBySpecificProduct(
    String businessId,
    String cashierId,
    String productName,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final rows = await _db.customSelect(
      'SELECT ti.product_name, '
      'COALESCE(SUM(ti.line_total), 0) AS total, '
      'COALESCE(SUM(ti.qty), 0) AS quantity '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      'AND (t.branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (t.branch_id IS NULL AND t.cashier_id = ?)) '
      'AND LOWER(ti.product_name) LIKE LOWER(?) '
      'GROUP BY ti.product_name',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
        Variable.withString('%$productName%'),
      ],
    ).get();

    if (rows.isEmpty) return null;

    // Aggregate all matching products (fuzzy name match may return multiple)
    double total = 0;
    double quantity = 0;
    String matchedName = productName;
    for (final r in rows) {
      total += (r.data['total'] as num?)?.toDouble() ?? 0.0;
      quantity += (r.data['quantity'] as num?)?.toDouble() ?? 0.0;
      matchedName = r.data['product_name'] as String? ?? productName;
    }

    return ProductSalesResult(
      productName: matchedName,
      total: total,
      quantity: quantity,
    );
  }

  /// Get total number of active products for a business.
  Future<int> getProductCount(String businessId) async {
    final products = await _productsDao.getByBusinessId(businessId);
    return products.where((p) => p.isActive).length;
  }

  /// Get list of active products with their variants.
  Future<List<ActiveProductInfo>> getActiveProducts(
    String businessId,
  ) async {
    final catalog = await getProductCatalog(businessId);
    return catalog.map((pw) {
      return ActiveProductInfo(
        name: pw.product.name,
        variantName: pw.variant.name,
        price: pw.variant.price,
        stock: pw.variant.stock,
      );
    }).toList();
  }

  // ─── TRANSACTION QUERIES ────────────────────────────────────────────────

  /// Get products that have never been sold (no transaction_items).
  Future<List<ActiveProductInfo>> getProductsWithoutSales(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final rows = await _db.customSelect(
      'SELECT p.name AS product_name, pv.name AS variant_name, '
      'pv.price, pv.stock '
      'FROM products p '
      'JOIN product_variants pv ON pv.product_id = p.id '
      'WHERE p.business_id = ? AND p.is_active = 1 AND pv.is_active = 1 '
      'AND NOT EXISTS ('
      '  SELECT 1 FROM transaction_items ti '
      '  JOIN transactions t ON t.id = ti.transaction_id '
      '  WHERE ti.variant_id = pv.id '
      '  AND t.created_at >= ? AND t.created_at < ? '
      '  AND (t.branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      '  OR (t.branch_id IS NULL AND t.cashier_id = ?))'
      ') '
      'ORDER BY p.name',
      variables: [
        Variable.withString(businessId),
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    ).get();

    return rows.map((r) {
      return ActiveProductInfo(
        name: r.data['product_name'] as String? ?? '',
        variantName: r.data['variant_name'] as String? ?? 'Default',
        price: (r.data['price'] as num?)?.toDouble() ?? 0.0,
        stock: (r.data['stock'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Get transaction count for a business within a date range.
  Future<int> getTransactionCount(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter,
  ) async {
    final range = dateFilter.resolve();

    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt '
      'FROM transactions '
      'WHERE created_at >= ? AND created_at < ? '
      'AND (branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
      'OR (branch_id IS NULL AND cashier_id = ?))',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    ).getSingle();

    return (result.data['cnt'] as int?) ?? 0;
  }

  // ─── PRODUCT CATALOG (for matching) ─────────────────────────────────────

  /// Get all active products with their default variants for a business.
  Future<List<ProductWithVariant>> getProductCatalog(
    String businessId,
  ) async {
    final products = await _productsDao.getByBusinessId(businessId);
    final results = <ProductWithVariant>[];

    for (final product in products) {
      if (!product.isActive) continue;

      final variants = await _variantsDao.getByProductId(product.id);
      for (final variant in variants) {
        if (!variant.isActive) continue;
        results.add(ProductWithVariant(product: product, variant: variant));
      }
    }

    return results;
  }

  // ─── TRANSACTION CREATION ───────────────────────────────────────────────

  /// Create a transaction from matched products.
  /// ONLY called after user confirms the preview.
  Future<String> createTransaction({
    required String cashierId,
    required String? branchId,
    required List<TransactionLineItem> lineItems,
  }) async {
    final uuid = const Uuid();
    final txId = uuid.v4();

    double subtotal = 0;
    double totalTax = 0;

    final itemCompanions = <TransactionItemsTableCompanion>[];

    for (final line in lineItems) {
      final lineTotal = line.unitPrice * line.quantity;
      final lineTax = lineTotal * (line.taxRate ?? 0) / 100;
      subtotal += lineTotal;
      totalTax += lineTax;

      itemCompanions.add(TransactionItemsTableCompanion.insert(
        id: uuid.v4(),
        transactionId: txId,
        variantId: line.variantId,
        productName: line.productName,
        variantName: line.variantName,
        unitPrice: line.unitPrice,
        taxRate: Value(line.taxRate),
        qty: line.quantity,
        lineTotal: lineTotal,
        lineTax: lineTax,
      ));
    }

    final totalAmount = subtotal + totalTax;

    final txCompanion = TransactionsTableCompanion.insert(
      id: txId,
      cashierId: cashierId,
      branchId: Value(branchId),
      totalAmount: totalAmount,
      taxAmount: totalTax,
      subtotal: subtotal,
      itemCount: lineItems.length,
      createdAt: Value(DateTime.now()),
      syncStatus: const Value(0), // pendingUpload
    );

    await _transactionsDao.insertTransaction(txCompanion, itemCompanions);

    return txId;
  }
}

// ─── RESULT MODELS ──────────────────────────────────────────────────────────

/// A product paired with one of its variants (for catalog lookups).
class ProductWithVariant {
  final ProductsTableData product;
  final ProductVariantsTableData variant;

  const ProductWithVariant({required this.product, required this.variant});
}

/// A line item ready for transaction creation.
class TransactionLineItem {
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  final double? taxRate;
  final double quantity;

  const TransactionLineItem({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    this.taxRate,
    required this.quantity,
  });
}

/// Sales breakdown per category.
class CategorySalesResult {
  final String category;
  final double total;

  const CategorySalesResult({required this.category, required this.total});
}

/// Sales breakdown per product.
class ProductSalesResult {
  final String productName;
  final double total;
  final double quantity;

  const ProductSalesResult({
    required this.productName,
    required this.total,
    required this.quantity,
  });
}

/// Info about an active product for listing.
class ActiveProductInfo {
  final String name;
  final String variantName;
  final double price;
  final int stock;

  const ActiveProductInfo({
    required this.name,
    required this.variantName,
    required this.price,
    required this.stock,
  });
}
