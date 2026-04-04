import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';

class DashboardRepository {
  final TransactionsDao _txnDao;
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;
  final CategoriesDao _categoriesDao;
  final BranchesDao _branchesDao;

  DashboardRepository({
    required TransactionsDao txnDao,
    required ProductVariantsDao variantsDao,
    required ProductsDao productsDao,
    required CategoriesDao categoriesDao,
    required BranchesDao branchesDao,
  })  : _txnDao = txnDao,
        _variantsDao = variantsDao,
        _productsDao = productsDao,
        _categoriesDao = categoriesDao,
        _branchesDao = branchesDao;

  /// Emits whenever the transactions table changes — used as a reload trigger.
  Stream<void> watchChanges() {
    return _txnDao.watchTransactions().map((_) {});
  }

  Future<DashboardData> load({
    required String businessId,
    String? branchId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final fourteenDaysAgo = today.subtract(const Duration(days: 14));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    // ── Transactions ──────────────────────────────────────────────────────
    final monthTxns = await _txnDao.getTransactionsSince(
      thirtyDaysAgo,
      branchId: branchId,
    );

    // All-branch transactions for branch comparison (last 30 days)
    final allBranchTxns = await _txnDao.getAllTransactionsSince(thirtyDaysAgo);

    // Slice by period
    final todayTxns =
        monthTxns.where((t) => !t.createdAt.isBefore(today)).toList();
    final yesterdayTxns = monthTxns
        .where((t) =>
            !t.createdAt.isBefore(yesterday) && t.createdAt.isBefore(today))
        .toList();
    final weekTxns =
        monthTxns.where((t) => !t.createdAt.isBefore(sevenDaysAgo)).toList();
    final lastWeekTxns = monthTxns
        .where((t) =>
            !t.createdAt.isBefore(fourteenDaysAgo) &&
            t.createdAt.isBefore(sevenDaysAgo))
        .toList();

    // ── Stat card values ──────────────────────────────────────────────────
    double sum(List txns) =>
        txns.fold(0.0, (s, t) => s + (t.totalAmount as double));

    final todaySales = sum(todayTxns);
    final yesterdaySales = sum(yesterdayTxns);
    final weekSales = sum(weekTxns);
    final lastWeekSales = sum(lastWeekTxns);
    final todayCount = todayTxns.length;
    final yesterdayCount = yesterdayTxns.length;
    final avgOrder = todayCount > 0 ? todaySales / todayCount : 0.0;
    final yesterdayAvg =
        yesterdayCount > 0 ? yesterdaySales / yesterdayCount : 0.0;

    // ── 7-day trend ───────────────────────────────────────────────────────
    final sevenDayTotals = <double>[];
    final sevenDayLabels = <String>[];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final total = monthTxns
          .where((t) => !t.createdAt.isBefore(day) && t.createdAt.isBefore(next))
          .fold(0.0, (s, t) => s + t.totalAmount);
      sevenDayTotals.add(total);
      sevenDayLabels.add(dayNames[day.weekday - 1]);
    }

    // ── 30-day trend ──────────────────────────────────────────────────────
    final thirtyDayTotals = <double>[];
    final thirtyDayLabels = <String>[];
    for (int i = 29; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final total = monthTxns
          .where((t) => !t.createdAt.isBefore(day) && t.createdAt.isBefore(next))
          .fold(0.0, (s, t) => s + t.totalAmount);
      thirtyDayTotals.add(total);
      // Label every 5th day
      thirtyDayLabels.add(i % 5 == 0 ? '${day.month}/${day.day}' : '');
    }

    // ── Transaction items for category + top items ─────────────────────
    final txnIds = monthTxns.map((t) => t.id).toList();
    final items = await _txnDao.getItemsForTransactions(txnIds);

    // Top selling items by quantity
    final itemAgg = <String, _ItemAgg>{};
    for (final item in items) {
      final agg = itemAgg.putIfAbsent(item.productName, () => _ItemAgg(item.productName));
      agg.qty += item.qty;
      agg.revenue += item.lineTotal;
    }
    final topItems = (itemAgg.values.toList()..sort((a, b) => b.qty.compareTo(a.qty)))
        .take(5)
        .map((a) => TopItem(name: a.name, sold: a.qty.toInt(), revenue: a.revenue))
        .toList();

    // ── Category performance ──────────────────────────────────────────────
    final variants =
        await _variantsDao.getByBusinessId(businessId);
    final variantToProduct = {for (final v in variants) v.id: v.productId};

    final products = await _productsDao.getByBusinessId(businessId);
    final productToCategory = {for (final p in products) p.id: p.categoryId};

    final categories = await _categoriesDao.getByBusinessId(businessId);
    final categoryName = {for (final c in categories) c.id: c.name};

    final catAgg = <String, double>{};
    for (final item in items) {
      final productId = variantToProduct[item.variantId];
      if (productId == null) continue;
      final catId = productToCategory[productId];
      final name =
          catId != null ? (categoryName[catId] ?? 'Uncategorized') : 'Uncategorized';
      catAgg[name] = (catAgg[name] ?? 0.0) + item.lineTotal;
    }
    final categoryStats = (catAgg.entries
        .map((e) => CategoryStat(name: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total)));

    // ── Payment methods ───────────────────────────────────────────────────
    final payMap = <String, double>{};
    for (final txn in monthTxns) {
      final method = _normalizePayment(txn.paymentMethod);
      payMap[method] = (payMap[method] ?? 0.0) + txn.totalAmount;
    }

    // ── Low stock items ───────────────────────────────────────────────────
    final lowStockVariants =
        await _variantsDao.getLowStockByBusinessId(businessId);
    final productIdToName = {for (final p in products) p.id: p.name};

    final lowStockItems = (lowStockVariants.map((v) {
      final pName = productIdToName[v.productId] ?? 'Unknown';
      final display = v.name == 'Default' ? pName : '$pName (${v.name})';
      return LowStockItem(
        displayName: display,
        currentStock: v.stock,
        reorderAt: v.lowStockAlert, // null = no threshold, stock just hit 0
      );
    }).toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock)));

    // ── Branch comparison ─────────────────────────────────────────────────
    final branches = await _branchesDao.getAll();
    final branchIdToName = {for (final b in branches) b.id: b.name};

    final branchAgg = <String, _BranchAgg>{};
    for (final txn in allBranchTxns) {
      final bId = txn.branchId ?? '__none__';
      final bName = txn.branchId != null
          ? (branchIdToName[txn.branchId!] ?? 'Unknown Branch')
          : 'No Branch';
      final agg = branchAgg.putIfAbsent(bId, () => _BranchAgg(bName));
      agg.txnCount++;
      agg.revenue += txn.totalAmount;
    }

    final branchList = branchAgg.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final topRevenue = branchList.isNotEmpty ? branchList.first.revenue : 0.0;

    final branchStats = branchList
        .map((a) => BranchStat(
              name: a.name,
              txnCount: a.txnCount,
              totalRevenue: a.revenue,
              isTop: a.revenue == topRevenue && topRevenue > 0,
            ))
        .toList();

    return DashboardData(
      todaySales: todaySales,
      weekSales: weekSales,
      todayTransactionCount: todayCount,
      avgOrderValue: avgOrder,
      yesterdaySales: yesterdaySales,
      lastWeekSales: lastWeekSales,
      yesterdayTransactionCount: yesterdayCount,
      yesterdayAvgOrderValue: yesterdayAvg,
      sevenDayTotals: sevenDayTotals,
      sevenDayLabels: sevenDayLabels,
      thirtyDayTotals: thirtyDayTotals,
      thirtyDayLabels: thirtyDayLabels,
      categoryStats: categoryStats,
      topItems: topItems,
      paymentBreakdown: payMap,
      lowStockItems: lowStockItems,
      branchStats: branchStats,
    );
  }

  String _normalizePayment(String method) {
    switch (method.toLowerCase().trim()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'e-wallet':
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method.isNotEmpty ? method[0].toUpperCase() + method.substring(1) : 'Other';
    }
  }
}

class _ItemAgg {
  final String name;
  double qty = 0;
  double revenue = 0;
  _ItemAgg(this.name);
}

class _BranchAgg {
  final String name;
  int txnCount = 0;
  double revenue = 0;
  _BranchAgg(this.name);
}
