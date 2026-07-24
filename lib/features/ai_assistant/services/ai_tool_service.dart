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
  }) : _productsDao = productsDao,
       _variantsDao = variantsDao,
       _checkoutService = checkoutService,
       _db = db;

  /// Returns the SQL WHERE clause and variables for branch/ownership filtering.
  ///
  /// - [ownUserId] non-null (own-only scope, e.g. a cashier): hard-restricts to
  ///   this user's own rows, within the business (and [branchId] when known).
  ///   Defence-in-depth on top of the server's own-row RLS.
  /// - [branchId] non-null: filters to that specific branch.
  /// - both null (All Branches): filters to all branches of the business.
  static ({String clause, List<Variable> variables}) branchFilter({
    required String businessId,
    required String cashierId,
    required String? branchId,
    String? ownUserId,
    String tableAlias = '',
  }) {
    final prefix = tableAlias.isNotEmpty ? '$tableAlias.' : '';
    if (ownUserId != null) {
      if (branchId != null) {
        return (
          clause: 'AND ${prefix}cashier_id = ? AND ${prefix}branch_id = ?',
          variables: [
            Variable.withString(ownUserId),
            Variable.withString(branchId),
          ],
        );
      }
      return (
        clause:
            'AND ${prefix}cashier_id = ? '
            'AND ${prefix}branch_id IN (SELECT id FROM branches WHERE business_id = ?)',
        variables: [
          Variable.withString(ownUserId),
          Variable.withString(businessId),
        ],
      );
    }
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
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
    );

    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_amount), 0) AS total '
          'FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          '${bf.clause}',
          variables: [
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
            ...bf.variables,
          ],
        )
        .getSingle();

    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get sales grouped by category.
  /// Returns a list of { category, total } maps.
  Future<List<CategorySalesResult>> getSalesByCategory(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
      tableAlias: 't',
    );

    final rows = await _db
        .customSelect(
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
        )
        .get();

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
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
      tableAlias: 't',
    );

    final rows = await _db
        .customSelect(
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
        )
        .get();

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
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
      tableAlias: 't',
    );

    final result = await _db
        .customSelect(
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
        )
        .getSingle();

    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── INSIGHTS / ANALYTICS ───────────────────────────────────────────────

  /// Total sales for an explicit range — the raw-range form behind the insight
  /// queries (the public sales methods take an [AiDateFilter]).
  Future<double> _salesTotalForRange(
    String businessId,
    String cashierId,
    String? branchId,
    DateTime start,
    DateTime end,
  ) async {
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
    );
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_amount), 0) AS total '
          'FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          '${bf.clause}',
          variables: [
            Variable.withDateTime(start),
            Variable.withDateTime(end),
            ...bf.variables,
          ],
        )
        .getSingle();
    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Sales for [dateFilter] compared against the equal-length window that
  /// immediately precedes it — the primitive behind the "sales up/down vs last
  /// period" insight.
  Future<SalesTrendResult> getSalesTrend(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final prev = previousPeriod(start: range.start, end: range.end);
    final current = await _salesTotalForRange(
      businessId,
      cashierId,
      branchId,
      range.start,
      range.end,
    );
    final previous = await _salesTotalForRange(
      businessId,
      cashierId,
      branchId,
      prev.start,
      prev.end,
    );
    return SalesTrendResult(current: current, previous: previous);
  }

  /// The equal-length window immediately before [start, end). Pure and
  /// deterministic so it is unit-tested directly without a database.
  static ({DateTime start, DateTime end}) previousPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    final duration = end.difference(start);
    return (start: start.subtract(duration), end: start);
  }

  /// Total of approved expenses within [dateFilter] — the realised spend figure
  /// behind expense-trend insights. Scoped to the business, optionally to one
  /// branch. Expenses have no cashier-ownership fallback, so the cashier-based
  /// [branchFilter] is intentionally NOT reused here.
  Future<double> getApprovedExpenseTotal(
    String businessId,
    AiDateFilter dateFilter, {
    String? branchId,
  }) async {
    final range = dateFilter.resolve();
    final branchClause = branchId != null ? 'AND branch_id = ?' : '';
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total '
          'FROM expenses '
          "WHERE status = 'approved' "
          'AND expense_date >= ? AND expense_date < ? '
          'AND business_id = ? '
          '$branchClause',
          variables: [
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
            Variable.withString(businessId),
            if (branchId != null) Variable.withString(branchId),
          ],
        )
        .getSingle();
    return (result.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Top [limit] products by sales value within [dateFilter] — the "best
  /// sellers" insight. A thin ranking wrapper over [getSalesByProduct], which
  /// already returns rows ordered by total descending, so the AI and any other
  /// caller share one definition of "top product".
  Future<List<ProductSalesResult>> getTopProducts(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
    int limit = 5,
  }) async {
    if (limit <= 0) return const [];
    final ranked = await getSalesByProduct(
      businessId,
      cashierId,
      dateFilter,
      branchId: branchId,
    );
    return ranked.take(limit).toList();
  }

  /// Number of active, stock-tracked variants currently at or below their
  /// low-stock threshold — the "running low" insight. Reuses the same DAO
  /// definition the dashboard's low-stock card uses, so the AI's figure always
  /// matches what the owner sees there. Business-scoped on purpose: variant
  /// stock is an all-branches total (product_variants has no branch_id), so a
  /// branch filter would not be meaningful here.
  Future<int> getLowStockCount(String businessId) async {
    final lowStock = await _variantsDao.getLowStockByBusinessId(businessId);
    return lowStock.length;
  }

  /// Products ranked by the gross margin they earned within [dateFilter] — the
  /// "margin movers" insight (top [limit] by margin). The cost basis is the
  /// variant's CURRENT `product_variants.cost_price`, because cost-at-sale is
  /// not stored on the line item; this is therefore an approximation that
  /// drifts if a variant's cost changed after the sale. Variants with no cost
  /// recorded are excluded — their margin is unknowable, and counting them as
  /// zero-cost would overstate margin.
  Future<List<MarginMoverResult>> getMarginMovers(
    String businessId,
    String cashierId,
    AiDateFilter dateFilter, {
    String? branchId,
    int limit = 5,
  }) async {
    if (limit <= 0) return const [];
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      tableAlias: 't',
    );

    final rows = await _db
        .customSelect(
          'SELECT ti.product_name, '
          'COALESCE(SUM(ti.line_total), 0) AS revenue, '
          'COALESCE(SUM(ti.qty * pv.cost_price), 0) AS cost_total, '
          'COALESCE(SUM(ti.line_total), 0) - COALESCE(SUM(ti.qty * pv.cost_price), 0) '
          'AS margin '
          'FROM transaction_items ti '
          'JOIN transactions t ON t.id = ti.transaction_id '
          'JOIN product_variants pv ON pv.id = ti.variant_id '
          'WHERE t.created_at >= ? AND t.created_at < ? '
          'AND pv.cost_price IS NOT NULL '
          '${bf.clause} '
          'GROUP BY ti.product_name '
          'ORDER BY margin DESC '
          'LIMIT ?',
          variables: [
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
            ...bf.variables,
            Variable.withInt(limit),
          ],
        )
        .get();

    return rows.map((r) {
      return MarginMoverResult(
        productName: r.data['product_name'] as String? ?? '',
        revenue: (r.data['revenue'] as num?)?.toDouble() ?? 0.0,
        cost: (r.data['cost_total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // ─── PRODUCT QUERIES ───────────────────────────────────────────────────

  /// Get sales filtered by a specific product name.
  Future<ProductSalesResult?> getSalesBySpecificProduct(
    String businessId,
    String cashierId,
    String productName,
    AiDateFilter dateFilter, {
    String? branchId,
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
      tableAlias: 't',
    );

    final rows = await _db
        .customSelect(
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
        )
        .get();

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
  Future<List<ActiveProductInfo>> getActiveProducts(String businessId) async {
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
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
      tableAlias: 't',
    );

    final rows = await _db
        .customSelect(
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
        )
        .get();

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
    String? ownUserId,
  }) async {
    final range = dateFilter.resolve();
    final bf = branchFilter(
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
      ownUserId: ownUserId,
    );

    final result = await _db
        .customSelect(
          'SELECT COUNT(*) AS cnt '
          'FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          '${bf.clause}',
          variables: [
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
            ...bf.variables,
          ],
        )
        .getSingle();

    return (result.data['cnt'] as int?) ?? 0;
  }

  // ─── PRODUCT CATALOG (for matching) ─────────────────────────────────────

  /// Get all active products with their default variants for a business.
  Future<List<ProductWithVariant>> getProductCatalog(String businessId) async {
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

      itemCompanions.add(
        TransactionItemsTableCompanion.insert(
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
        ),
      );
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
      transactionId: txId,
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

/// Sales for a period vs the equal-length preceding period.
class SalesTrendResult {
  final double current;
  final double previous;

  const SalesTrendResult({required this.current, required this.previous});

  double get delta => current - previous;

  /// Percentage change vs the previous period, or null when the previous period
  /// had zero sales (a percentage from a zero base is undefined — callers should
  /// phrase it as "new" rather than showing an infinite increase).
  double? get deltaPercent => previous == 0 ? null : (delta / previous) * 100;

  bool get isUp => delta > 0;
  bool get isDown => delta < 0;
}

/// Gross margin a product earned over a period. Cost basis is the variant's
/// CURRENT `product_variants.cost_price` (cost-at-sale is not stored), so this
/// is an approximation; variants with no cost are excluded upstream.
class MarginMoverResult {
  final String productName;
  final double revenue;
  final double cost;

  const MarginMoverResult({
    required this.productName,
    required this.revenue,
    required this.cost,
  });

  double get margin => revenue - cost;

  /// Margin as a percentage of revenue, or null when revenue is zero (an
  /// undefined base — callers should phrase it as "n/a" rather than 0%).
  double? get marginPercent => revenue == 0 ? null : (margin / revenue) * 100;
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
