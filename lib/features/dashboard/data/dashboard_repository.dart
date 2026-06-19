import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/domain/repositories/i_dashboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardRepository implements IDashboardRepository {
  final TransactionsDao _txnDao;
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;
  final CategoriesDao _categoriesDao;
  final BranchesDao _branchesDao;
  final ExpensesDao _expensesDao;
  final SharedPreferences _prefs;

  DashboardRepository({
    required TransactionsDao txnDao,
    required ProductVariantsDao variantsDao,
    required ProductsDao productsDao,
    required CategoriesDao categoriesDao,
    required BranchesDao branchesDao,
    required ExpensesDao expensesDao,
    required SharedPreferences prefs,
  }) : _txnDao = txnDao,
       _variantsDao = variantsDao,
       _productsDao = productsDao,
       _categoriesDao = categoriesDao,
       _branchesDao = branchesDao,
       _expensesDao = expensesDao,
       _prefs = prefs;

  // ─── Branch name cache ────────────────────────────────────────────────────

  static String _cacheKey(String businessId) =>
      'branch_names_cache_$businessId';

  /// Key prefix used by BranchCubit to persist branch options (scoped by businessId).
  static const String _branchCubitOptionsKeyPrefix = 'cached_branch_options';

  /// Persist branch id→name map so it survives offline sessions.
  Future<void> _cacheBranchNames(
    String businessId,
    Map<String, String> names,
  ) async {
    if (names.isEmpty) return;
    await _prefs.setString(_cacheKey(businessId), jsonEncode(names));
  }

  /// Build a merged id→name map from every available offline source:
  ///   1. BranchCubit's cached options (populated on every login)
  ///   2. Dashboard's own persisted cache
  /// Sources are merged in ascending priority so fresher data wins.
  Future<Map<String, String>> _loadCachedBranchNames(String businessId) async {
    final merged = <String, String>{};

    // Layer 1 — BranchCubit cache (scoped by businessId): [{"name": "...", "id": "..."}]
    try {
      final scopedKey = '${_branchCubitOptionsKeyPrefix}_$businessId';
      final raw = _prefs.getString(scopedKey);
      if (raw != null) {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final id = item['id']?.toString().trim();
            final name = item['name']?.toString().trim();
            if (id != null &&
                id.isNotEmpty &&
                name != null &&
                name.isNotEmpty) {
              merged[id] = name;
            }
          }
        }
      }
    } catch (e, st) {
      debugPrint('[DashboardRepo] Error reading BranchCubit cache: $e\n$st');
    }

    // Layer 2 — Dashboard's own cache: {"id": "name"}  (wins over layer 1)
    try {
      final raw = _prefs.getString(_cacheKey(businessId));
      if (raw != null) {
        final map = jsonDecode(raw);
        if (map is Map) {
          map.forEach((k, v) {
            final id = k.toString().trim();
            final name = v.toString().trim();
            if (id.isNotEmpty && name.isNotEmpty) merged[id] = name;
          });
        }
      }
    } catch (e, st) {
      debugPrint('[DashboardRepo] Error reading dashboard cache: $e\n$st');
    }

    return merged;
  }

  // ─── Stream trigger ───────────────────────────────────────────────────────

  /// Emits whenever transactions, product variants, or expenses change.
  @override
  Stream<void> watchChanges({required String businessId}) {
    final controller = StreamController<void>.broadcast();
    final subs = [
      _txnDao.watchTransactions().listen((_) {
        if (!controller.isClosed) controller.add(null);
      }),
      _variantsDao.watchByBusinessId(businessId).listen((_) {
        if (!controller.isClosed) controller.add(null);
      }),
      _expensesDao.watchByBusinessId(businessId).listen((_) {
        if (!controller.isClosed) controller.add(null);
      }),
    ];
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }

  // ─── Main load ────────────────────────────────────────────────────────────

  @override
  Future<DashboardData> load({
    required String businessId,
    String? branchId,
  }) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final fourteenDaysAgo = today.subtract(const Duration(days: 14));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    // ── Transactions ──────────────────────────────────────────────────────
    final monthTxns = await _txnDao.getTransactionsSince(
      thirtyDaysAgo,
      businessId: businessId,
      branchId: branchId,
    );
    final allBranchTxns = await _txnDao.getAllTransactionsSince(
      thirtyDaysAgo,
      businessId: businessId,
    );

    final todayTxns = monthTxns
        .where((t) => !t.createdAt.toUtc().isBefore(today))
        .toList();
    final yesterdayTxns = monthTxns
        .where(
          (t) =>
              !t.createdAt.toUtc().isBefore(yesterday) &&
              t.createdAt.toUtc().isBefore(today),
        )
        .toList();
    final weekTxns = monthTxns
        .where((t) => !t.createdAt.toUtc().isBefore(sevenDaysAgo))
        .toList();
    final lastWeekTxns = monthTxns
        .where(
          (t) =>
              !t.createdAt.toUtc().isBefore(fourteenDaysAgo) &&
              t.createdAt.toUtc().isBefore(sevenDaysAgo),
        )
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
    final yesterdayAvg = yesterdayCount > 0
        ? yesterdaySales / yesterdayCount
        : 0.0;

    // ── 7-day trend ───────────────────────────────────────────────────────
    final sevenDayTotals = <double>[];
    final sevenDayLabels = <String>[];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final total = monthTxns
          .where(
            (t) =>
                !t.createdAt.toUtc().isBefore(day) &&
                t.createdAt.toUtc().isBefore(next),
          )
          .fold(0.0, (s, t) => s + t.totalAmount);
      sevenDayTotals.add(total);
      sevenDayLabels.add(dayNames[day.weekday - 1]);
    }

    // ── 30-day trend ──────────────────────────────────────────────────────
    final thirtyDayTotals = <double>[];
    final thirtyDayLabels = <String>[];
    for (int i = 29; i >= 0; i--) {
      final day = DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final total = monthTxns
          .where(
            (t) =>
                !t.createdAt.toUtc().isBefore(day) &&
                t.createdAt.toUtc().isBefore(next),
          )
          .fold(0.0, (s, t) => s + t.totalAmount);
      thirtyDayTotals.add(total);
      thirtyDayLabels.add(i % 5 == 0 ? '${day.month}/${day.day}' : '');
    }

    // ── Category + top items ──────────────────────────────────────────────
    final txnIds = monthTxns.map((t) => t.id).toList();
    final items = await _txnDao.getItemsForTransactions(txnIds);

    final itemAgg = <String, _ItemAgg>{};
    for (final item in items) {
      final agg = itemAgg.putIfAbsent(
        item.productName,
        () => _ItemAgg(item.productName),
      );
      agg.qty += item.qty;
      agg.revenue += item.lineTotal;
    }
    final topItems =
        (itemAgg.values.toList()..sort((a, b) => b.qty.compareTo(a.qty)))
            .take(5)
            .map(
              (a) => TopItem(
                name: a.name,
                sold: a.qty.toInt(),
                revenue: a.revenue,
              ),
            )
            .toList();

    // ── Category performance ──────────────────────────────────────────────
    final variants = await _variantsDao.getByBusinessId(businessId);
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
      final name = catId != null
          ? (categoryName[catId] ?? 'Uncategorized')
          : 'Uncategorized';
      catAgg[name] = (catAgg[name] ?? 0.0) + item.lineTotal;
    }
    final categoryStats =
        (catAgg.entries
            .map((e) => CategoryStat(name: e.key, total: e.value))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total)));

    // ── Payment methods ───────────────────────────────────────────────────
    final payMap = <String, double>{};
    for (final txn in monthTxns) {
      final method = _normalizePayment(txn.paymentMethod);
      payMap[method] = (payMap[method] ?? 0.0) + txn.totalAmount;
    }

    // ── Low stock ─────────────────────────────────────────────────────────
    final lowStockVariants = await _variantsDao.getLowStockByBusinessId(
      businessId,
    );
    final productIdToName = {for (final p in products) p.id: p.name};
    final lowStockItems = (lowStockVariants.map((v) {
      final pName = productIdToName[v.productId] ?? 'Unknown';
      final display = v.name == 'Default' ? pName : '$pName (${v.name})';
      return LowStockItem(
        displayName: display,
        currentStock: v.stock,
        reorderAt: v.lowStockAlert,
      );
    }).toList()..sort((a, b) => a.currentStock.compareTo(b.currentStock)));

    // ── Branch comparison ─────────────────────────────────────────────────
    //
    // Strategy (offline-safe):
    //  1. Load branches filtered by businessId from local SQLite — works offline.
    //  2. Merge with a SharedPreferences cache so previously-seen branch names
    //     survive even if the branches table gets cleared or hasn't synced yet.
    //  3. Any still-unknown branch ID gets a short readable fallback derived
    //     from the ID itself (e.g. "Branch …a1b2") instead of "Unknown Branch".

    final dbBranches = await _branchesDao.getByBusinessId(businessId);
    final dbIdToName = {for (final b in dbBranches) b.id: b.name};

    // Persist fresh names to cache
    if (dbIdToName.isNotEmpty) {
      _cacheBranchNames(businessId, dbIdToName);
    }

    // Load previously-cached names as a fallback layer
    final cachedIdToName = await _loadCachedBranchNames(businessId);

    // Merge: DB wins over cache (DB is always fresher)
    final branchIdToName = {...cachedIdToName, ...dbIdToName};

    String resolveBranchName(String? bId) {
      if (bId == null) return 'No Branch';
      final name = branchIdToName[bId];
      if (name != null && name.trim().isNotEmpty) return name.trim();
      // Derive a short readable ID so the user sees something meaningful
      final short = bId.length > 6 ? '…${bId.substring(bId.length - 6)}' : bId;
      return 'Branch $short';
    }

    final branchAgg = <String, _BranchAgg>{};
    for (final txn in allBranchTxns) {
      final bId = txn.branchId ?? '__none__';
      final bName = resolveBranchName(txn.branchId);
      final agg = branchAgg.putIfAbsent(bId, () => _BranchAgg(bName));
      // Keep the most resolved name in case first pass had partial data
      if (!bName.startsWith('Branch ') || agg.name.startsWith('Branch ')) {
        agg.name = bName;
      }
      agg.txnCount++;
      agg.revenue += txn.totalAmount;
    }

    final branchList = branchAgg.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final topRevenue = branchList.isNotEmpty ? branchList.first.revenue : 0.0;

    final branchStats = branchList
        .map(
          (a) => BranchStat(
            name: a.name,
            txnCount: a.txnCount,
            totalRevenue: a.revenue,
            isTop: a.revenue == topRevenue && topRevenue > 0,
          ),
        )
        .toList();

    // ── Expense summary ───────────────────────────────────────────────────
    // Reads from local SQLite — fully offline-first.
    final allExpenses = await _expensesDao.getByBusinessId(businessId);
    final branchExpenses = branchId == null
        ? allExpenses
        : allExpenses.where((e) => e.branchId == branchId).toList();

    double expToday = 0;
    double expMonth = 0;
    double expPending = 0;
    int pendingCount = 0;

    for (final e in branchExpenses) {
      final isApproved = e.status == 'approved';
      final isPending = e.status == 'pending';
      if (isPending) {
        expPending += e.amount;
        pendingCount++;
      }
      if (!isApproved) continue;
      if (!e.expenseDate.isBefore(thirtyDaysAgo)) expMonth += e.amount;
      if (!e.expenseDate.isBefore(today)) expToday += e.amount;
    }

    // Most recent 5 expenses (approved + pending), already ordered by date desc
    // from the DAO, so we just take the first 5 that match the branch filter.
    final recentExpenses = branchExpenses
        .where((e) => e.status == 'approved' || e.status == 'pending')
        .take(5)
        .map(
          (e) => RecentExpense(
            category: e.category,
            vendor: e.vendor,
            amount: e.amount,
            isPending: e.status == 'pending',
            date: e.expenseDate,
          ),
        )
        .toList();

    final expenseSummary = ExpenseSummary(
      todayTotal: expToday,
      monthTotal: expMonth,
      pendingTotal: expPending,
      pendingCount: pendingCount,
      recentExpenses: recentExpenses,
    );

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
      expenseSummary: expenseSummary,
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
        return method.isNotEmpty
            ? method[0].toUpperCase() + method.substring(1)
            : 'Other';
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
  String name;
  int txnCount = 0;
  double revenue = 0;
  _BranchAgg(this.name);
}
