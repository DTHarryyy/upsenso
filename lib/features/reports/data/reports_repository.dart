import 'dart:async';
import 'dart:convert';

import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsRepository {
  final TransactionsDao _txnDao;
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;
  final CategoriesDao _categoriesDao;
  final BranchesDao _branchesDao;

  static const String _branchCubitOptionsKeyPrefix = 'cached_branch_options';

  ReportsRepository({
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

  // ─── Real-time change stream ─────────────────────────────────────────────

  /// Emits whenever a transaction or product variant changes so reports
  /// stay current after every sale without manual refresh.
  ///
  /// Uses [onListen]/[onCancel] so inner Drift subscriptions are created only
  /// when the cubit actually subscribes — avoiding the broadcast-before-listener
  /// timing race. [skip(1)] discards the immediate snapshot each Drift stream
  /// emits on subscribe; only genuine table mutations propagate.
  Stream<void> watchChanges({required String businessId}) {
    StreamSubscription<List<TransactionsTableData>>? txnSub;
    StreamSubscription<List<ProductVariantsTableData>>? variantSub;

    late final StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () {
        txnSub = _txnDao
            .watchTransactions()
            .skip(1)
            .listen((_) { if (!controller.isClosed) controller.add(null); });
        variantSub = _variantsDao
            .watchByBusinessId(businessId)
            .skip(1)
            .listen((_) { if (!controller.isClosed) controller.add(null); });
      },
      onCancel: () {
        txnSub?.cancel();
        variantSub?.cancel();
        txnSub = null;
        variantSub = null;
      },
    );
    return controller.stream;
  }

  // ─── Branch name resolution ───────────────────────────────────────────────

  Future<Map<String, String>> _loadCachedBranchNames(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final merged = <String, String>{};
    try {
      final scopedKey = '${_branchCubitOptionsKeyPrefix}_$businessId';
      final raw = prefs.getString(scopedKey);
      if (raw != null) {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final id = item['id']?.toString().trim();
            final name = item['name']?.toString().trim();
            if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
              merged[id] = name;
            }
          }
        }
      }
    } catch (_) {}
    return merged;
  }

  // ─── Bucket helpers ───────────────────────────────────────────────────────

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<({DateTime start, DateTime end, String label})> _buildBuckets(
    DateTime cutoff,
    DateTime today,
    ReportPeriod period,
  ) {
    switch (period) {
      case ReportPeriod.last7Days:
        return List.generate(7, (i) {
          final day = today.subtract(Duration(days: 6 - i));
          return (
            start: day,
            end: day.add(const Duration(days: 1)),
            label: '${_months[day.month - 1]} ${day.day}',
          );
        });

      case ReportPeriod.last30Days:
        return List.generate(30, (i) {
          final day = today.subtract(Duration(days: 29 - i));
          return (
            start: day,
            end: day.add(const Duration(days: 1)),
            label: i % 5 == 0 || i == 29
                ? '${_months[day.month - 1]} ${day.day}'
                : '',
          );
        });

      case ReportPeriod.last90Days:
        // 13 weekly buckets — oldest first
        return List.generate(13, (w) {
          final start = cutoff.add(Duration(days: w * 7));
          final end = start.add(const Duration(days: 7));
          return (
            start: start,
            end: end,
            label: '${_months[start.month - 1]} ${start.day}',
          );
        });

      case ReportPeriod.lastYear:
        // 12 monthly buckets — oldest first
        return List.generate(12, (m) {
          final monthStart =
              _subtractMonths(DateTime(today.year, today.month, 1), 11 - m);
          final monthEnd = _addMonths(monthStart, 1);
          return (
            start: monthStart,
            end: monthEnd,
            label: _months[monthStart.month - 1],
          );
        });
    }
  }

  double _sumInRange(
    List<TransactionsTableData> txns,
    DateTime from,
    DateTime to,
  ) {
    return txns
        .where((t) => !t.createdAt.isBefore(from) && t.createdAt.isBefore(to))
        .fold(0.0, (s, t) => s + t.totalAmount);
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month - months;
    while (month <= 0) {
      month += 12;
      year--;
    }
    return DateTime(year, month, 1);
  }

  static DateTime _addMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    return DateTime(year, month, 1);
  }

  // ─── Main load ────────────────────────────────────────────────────────────

  Future<ReportsData> load({
    required String businessId,
    String? branchId,
    required ReportPeriod period,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(Duration(days: period.days));
    final prevCutoff = today.subtract(Duration(days: period.days * 2));

    // ── 1. Fetch transactions ──────────────────────────────────────────────
    // Fetch enough for both current and previous periods.
    final allFiltered = await _txnDao.getTransactionsSince(
      prevCutoff,
      businessId: businessId,
      branchId: branchId,
    );
    final allBranches = branchId != null
        ? await _txnDao.getAllTransactionsSince(prevCutoff, businessId: businessId)
        : allFiltered;

    final currentTxns =
        allFiltered.where((t) => !t.createdAt.isBefore(cutoff)).toList();
    final prevTxns = allFiltered
        .where((t) =>
            t.createdAt.isBefore(cutoff) && !t.createdAt.isBefore(prevCutoff))
        .toList();
    final currentAllBranch =
        allBranches.where((t) => !t.createdAt.isBefore(cutoff)).toList();
    final prevAllBranch = allBranches
        .where((t) =>
            t.createdAt.isBefore(cutoff) && !t.createdAt.isBefore(prevCutoff))
        .toList();

    // ── 2. Fetch transaction items ─────────────────────────────────────────
    final currentIds = currentTxns.map((t) => t.id).toList();
    final prevIds = prevTxns.map((t) => t.id).toList();
    final currentItems = await _txnDao.getItemsForTransactions(currentIds);
    final prevItems = await _txnDao.getItemsForTransactions(prevIds);

    // ── 3. Fetch product/variant/category data ─────────────────────────────
    final variants = await _variantsDao.getByBusinessId(businessId);
    final products = await _productsDao.getByBusinessId(businessId);
    final categories = await _categoriesDao.getByBusinessId(businessId);

    final variantMap = {for (final v in variants) v.id: v};
    final variantToProduct = {for (final v in variants) v.id: v.productId};
    final productToCategory = {for (final p in products) p.id: p.categoryId};
    final productToName = {for (final p in products) p.id: p.name};
    final categoryName = {for (final c in categories) c.id: c.name};

    // ── 4. Sales Report ───────────────────────────────────────────────────
    final totalRevenue =
        currentTxns.fold(0.0, (s, t) => s + t.totalAmount);
    final totalTransactions = currentTxns.length;
    final avgTicket =
        totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;
    final itemsSold =
        currentItems.fold<double>(0, (s, i) => s + i.qty).round();

    final prevRevenue = prevTxns.fold(0.0, (s, t) => s + t.totalAmount);
    final prevTransactions = prevTxns.length;
    final prevAvgTicket =
        prevTransactions > 0 ? prevRevenue / prevTransactions : 0.0;
    final prevItemsSold =
        prevItems.fold<double>(0, (s, i) => s + i.qty).round();

    // Sales trend
    final buckets = _buildBuckets(cutoff, today, period);
    final salesTrend = buckets
        .map((b) => SalesTrendPoint(
              label: b.label,
              total: _sumInRange(currentTxns, b.start, b.end),
            ))
        .toList();

    // Category breakdown
    final catAgg = <String, double>{};
    for (final item in currentItems) {
      final productId = variantToProduct[item.variantId];
      if (productId == null) continue;
      final catId = productToCategory[productId];
      final name =
          catId != null ? (categoryName[catId] ?? 'Other') : 'Other';
      catAgg[name] = (catAgg[name] ?? 0) + item.lineTotal;
    }
    final categoryBreakdown = (catAgg.entries
        .map((e) => CategoryStat(name: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total)));

    // ── 5. Inventory Health ───────────────────────────────────────────────
    final activeVariants =
        variants.where((v) => v.isActive && v.trackStock).toList();
    final totalSKUs = activeVariants.length;

    // Per-variant qty sold in current period
    final variantQty = <String, double>{};
    for (final item in currentItems) {
      variantQty[item.variantId] =
          (variantQty[item.variantId] ?? 0) + item.qty;
    }

    final inventoryItems = <InventoryStatusItem>[];
    int lowStockCount = 0, fastMovers = 0, deadStockCount = 0;

    for (final v in activeVariants) {
      final pName = productToName[v.productId] ?? 'Unknown';
      final displayName =
          v.name == 'Default' ? pName : '$pName (${v.name})';
      final totalQty = variantQty[v.id] ?? 0;
      final avgDailySale = totalQty / period.days;
      final currentStock = v.stockDecimal ?? v.stock.toDouble();
      final daysLeft =
          avgDailySale > 0 ? currentStock / avgDailySale : null;

      // Determine status
      InventoryStatusType status;
      final threshold = v.lowStockAlert;
      if ((threshold != null && v.stock <= threshold) ||
          (threshold == null && v.stock <= 0)) {
        status = InventoryStatusType.low;
        lowStockCount++;
      } else if (daysLeft != null && daysLeft <= 5) {
        status = InventoryStatusType.warning;
      } else if (avgDailySale < 0.3) {
        status = InventoryStatusType.slowMoving;
      } else {
        status = InventoryStatusType.ok;
      }

      if (avgDailySale >= 1.5) fastMovers++;
      if (currentStock > 0 && totalQty == 0) deadStockCount++;

      String? notes;
      if (status == InventoryStatusType.slowMoving) notes = 'Slow moving';

      inventoryItems.add(InventoryStatusItem(
        productName: displayName,
        status: status,
        currentStock: currentStock,
        avgDailySale: avgDailySale,
        daysLeft: daysLeft,
        notes: notes,
      ));
    }

    // Sort: low → warning → ok → slow moving
    const statusOrder = {
      InventoryStatusType.low: 0,
      InventoryStatusType.warning: 1,
      InventoryStatusType.ok: 2,
      InventoryStatusType.slowMoving: 3,
    };
    inventoryItems.sort(
      (a, b) => statusOrder[a.status]!.compareTo(statusOrder[b.status]!),
    );

    // ── 6. Profit Summary ─────────────────────────────────────────────────
    var costOfGoods = 0.0;
    for (final item in currentItems) {
      final cp = variantMap[item.variantId]?.costPrice;
      if (cp != null) costOfGoods += cp * item.qty;
    }
    final netProfit = totalRevenue - costOfGoods;

    var prevCogs = 0.0;
    for (final item in prevItems) {
      final cp = variantMap[item.variantId]?.costPrice;
      if (cp != null) prevCogs += cp * item.qty;
    }
    final prevNetProfit = prevRevenue - prevCogs;

    // Profit trend (revenue + COGS per bucket)
    final txnCogs = <String, double>{};
    for (final item in currentItems) {
      final cp = variantMap[item.variantId]?.costPrice ?? 0.0;
      txnCogs[item.transactionId] =
          (txnCogs[item.transactionId] ?? 0) + cp * item.qty;
    }

    final profitTrend = buckets.map((b) {
      final bTxns = currentTxns.where(
        (t) => !t.createdAt.isBefore(b.start) && t.createdAt.isBefore(b.end),
      );
      final rev = bTxns.fold(0.0, (s, t) => s + t.totalAmount);
      final cogs = bTxns.fold(0.0, (s, t) => s + (txnCogs[t.id] ?? 0));
      return ProfitTrendPoint(label: b.label, revenue: rev, cogs: cogs);
    }).toList();

    // ── 7. Branch Comparison ──────────────────────────────────────────────
    final dbBranches = await _branchesDao.getByBusinessId(businessId);
    final dbIdToName = {for (final b in dbBranches) b.id: b.name};
    final cachedNames = await _loadCachedBranchNames(businessId);
    final branchIdToName = {...cachedNames, ...dbIdToName};

    String resolveName(String? bId) {
      if (bId == null) return 'No Branch';
      final n = branchIdToName[bId];
      if (n != null && n.trim().isNotEmpty) return n.trim();
      final short =
          bId.length > 6 ? '…${bId.substring(bId.length - 6)}' : bId;
      return 'Branch $short';
    }

    final branchAgg = <String, _BranchAgg>{};
    for (final txn in currentAllBranch) {
      final key = txn.branchId ?? '__none__';
      final name = resolveName(txn.branchId);
      final agg = branchAgg.putIfAbsent(key, () => _BranchAgg(name));
      if (!name.startsWith('Branch ') || agg.name.startsWith('Branch ')) {
        agg.name = name;
      }
      agg.txnCount++;
      agg.revenue += txn.totalAmount;
    }

    final prevBranchRev = <String, double>{};
    for (final txn in prevAllBranch) {
      final key = txn.branchId ?? '__none__';
      prevBranchRev[key] = (prevBranchRev[key] ?? 0) + txn.totalAmount;
    }

    final branchList = branchAgg.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final topRev = branchList.isNotEmpty ? branchList.first.value.revenue : 0.0;

    final branchStats = branchList.map((e) {
      final agg = e.value;
      final prev = prevBranchRev[e.key] ?? 0.0;
      final vsLast = prev > 0
          ? (agg.revenue - prev) / prev * 100
          : (agg.revenue > 0 ? 100.0 : 0.0);
      return BranchReportStat(
        name: agg.name,
        totalSales: agg.revenue,
        transactions: agg.txnCount,
        avgTicket: agg.txnCount > 0 ? agg.revenue / agg.txnCount : 0,
        vsLastPeriodPct: vsLast,
        isTop: agg.revenue == topRev && topRev > 0,
      );
    }).toList();

    return ReportsData(
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      avgTicket: avgTicket,
      itemsSold: itemsSold,
      prevTotalRevenue: prevRevenue,
      prevTotalTransactions: prevTransactions,
      prevAvgTicket: prevAvgTicket,
      prevItemsSold: prevItemsSold,
      salesTrend: salesTrend,
      categoryBreakdown: categoryBreakdown,
      lowStockCount: lowStockCount,
      fastMoversCount: fastMovers,
      deadStockCount: deadStockCount,
      totalSKUs: totalSKUs,
      inventoryItems: inventoryItems,
      grossRevenue: totalRevenue,
      costOfGoods: costOfGoods,
      netProfit: netProfit,
      prevNetProfit: prevNetProfit,
      profitTrend: profitTrend,
      branchStats: branchStats,
    );
  }
}

class _BranchAgg {
  String name;
  int txnCount = 0;
  double revenue = 0;
  _BranchAgg(this.name);
}
