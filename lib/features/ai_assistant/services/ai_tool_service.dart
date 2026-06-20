import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/services/checkout_service.dart';
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
  final CheckoutService _checkoutService;
  final AppDatabase _db;

  AiToolService({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required CheckoutService checkoutService,
    required AppDatabase db,
  })  : _productsDao = productsDao,
        _variantsDao = variantsDao,
        _checkoutService = checkoutService,
        _db = db;

  /// Returns the SQL WHERE clause and variables for branch filtering.
  /// When [branchId] is non-null, filters to that specific branch.
  /// When [branchId] is null (All Branches), filters to all branches of the business.
  static ({String clause, List<Variable> variables}) branchFilter({
    required String businessId,
    required String cashierId,
    required String? branchId,
    String tableAlias = '',
  }) {
    final prefix = tableAlias.isNotEmpty ? '$tableAlias.' : '';
    if (branchId != null) {
      return (
        clause: 'AND ${prefix}branch_id = ?',
        variables: [Variable.withString(branchId)],
      );
    }
    return (
      clause:
          'AND (${prefix}branch_id IN (SELECT id FROM branches WHERE business_id = ?) '
          'OR (${prefix}branch_id IS NULL AND ${prefix}cashier_id = ?))',
      variables: [
        Variable.withString(businessId),
        Variable.withString(cashierId),
      ],
    );
  }

  // ─── SALES QUERIES ──────────────────────────────────────────────────────

  /// Get total sales amount for a business within a date range.
  Future<double> getSalesTotal(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
    );

    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) AS total '
      'FROM transactions '
      'WHERE created_at >= ? AND created_at < ? '
      '${bf.clause}',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
      ],
    ).getSingle();

    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get sales grouped by category.
  /// Returns a list of { category, total } maps.
  Future<List<CategorySalesResult>> getSalesByCategory(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

    final rows = await _db.customSelect(
      'SELECT COALESCE(c.name, \'Uncategorized\') AS category_name, '
      'SUM(ti.line_total) AS total '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'JOIN product_variants pv ON pv.id = ti.variant_id '
      'JOIN products p ON p.id = pv.product_id '
      'LEFT JOIN categories c ON c.id = p.category_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      '${bf.clause} '
      'GROUP BY c.name '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

    final rows = await _db.customSelect(
      'SELECT ti.product_name, '
      'SUM(ti.line_total) AS total, '
      'SUM(ti.qty) AS quantity '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      '${bf.clause} '
      'GROUP BY ti.product_name '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(ti.line_total), 0) AS total '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'JOIN product_variants pv ON pv.id = ti.variant_id '
      'JOIN products p ON p.id = pv.product_id '
      'LEFT JOIN categories c ON c.id = p.category_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      '${bf.clause} '
      'AND LOWER(c.name) = LOWER(?)',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

    final rows = await _db.customSelect(
      'SELECT ti.product_name, '
      'COALESCE(SUM(ti.line_total), 0) AS total, '
      'COALESCE(SUM(ti.qty), 0) AS quantity '
      'FROM transaction_items ti '
      'JOIN transactions t ON t.id = ti.transaction_id '
      'WHERE t.created_at >= ? AND t.created_at < ? '
      '${bf.clause} '
      'AND LOWER(ti.product_name) LIKE LOWER(?) '
      'GROUP BY ti.product_name',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
        // Display/hint surface — round the decimal stock for the AI model.
        stock: pw.variant.stock.round(),
      );
    }).toList();
  }

  // ─── TRANSACTION QUERIES ────────────────────────────────────────────────

  /// Get products that have never been sold (no transaction_items).
  Future<List<ActiveProductInfo>> getProductsWithoutSales(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

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
      '  ${bf.clause}'
      ') '
      'ORDER BY p.name',
      variables: [
        Variable.withString(businessId),
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
    );

    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt '
      'FROM transactions '
      'WHERE created_at >= ? AND created_at < ? '
      '${bf.clause}',
      variables: [
        Variable.withDateTime(range.start),
        Variable.withDateTime(range.end),
        ...bf.variables,
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
    required String? businessId,
    required String? branchId,
    required List<TransactionLineItem> lineItems,
  }) async {
    // Tenant is mandatory: an AI sale with no business would write a null-tenant
    // row (invisible to reports) and leak stock deductions across tenants.
    if (businessId == null || businessId.trim().isEmpty) {
      throw const AiSaleException(
        'No active business — sign in to a business before completing a sale.',
      );
    }

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
      businessId: Value(businessId),
      branchId: Value(branchId),
      totalAmount: totalAmount,
      taxAmount: totalTax,
      subtotal: subtotal,
      itemCount: lineItems.length,
      createdAt: Value(DateTime.now()),
      syncStatus: const Value(0), // pendingUpload
    );

    // Go through the same single entry point as POS checkout so the AI path
    // gets the invoice number, stock-availability check, and atomic deduction
    // for free — previously it skipped the invoice claim and could oversell.
    await _checkoutService.completeSale(
      transaction: txCompanion,
      items: itemCompanions,
      deductions: lineItems
          .map((l) => (variantId: l.variantId, qty: l.quantity))
          .toList(),
      businessId: businessId,
      branchId: branchId,
    );

    return txId;
  }
}

/// Raised when an AI-driven sale cannot be completed (e.g. no active business).
/// Carries a user-facing message the assistant surface can show directly.
class AiSaleException implements Exception {
  final String message;
  const AiSaleException(this.message);

  @override
  String toString() => message;
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
