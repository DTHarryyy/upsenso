import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/domain/repositories/i_reports_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsRepository implements IReportsRepository {
  final TransactionsDao _txnDao;
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;
  final CategoriesDao _categoriesDao;
  final BranchesDao _branchesDao;
  final InventoryLevelsDao _levelsDao;
  final StockLedgerDao _ledgerDao;
  final RefundsDao _refundsDao;
  final SharedPreferences _prefs;

  static const String _branchCubitOptionsKeyPrefix = 'cached_branch_options';

  ReportsRepository({
    required TransactionsDao txnDao,
    required ProductVariantsDao variantsDao,
    required ProductsDao productsDao,
    required CategoriesDao categoriesDao,
    required BranchesDao branchesDao,
    required InventoryLevelsDao levelsDao,
    required StockLedgerDao ledgerDao,
    required RefundsDao refundsDao,
    required SharedPreferences prefs,
  }) : _txnDao = txnDao,
       _variantsDao = variantsDao,
       _productsDao = productsDao,
       _categoriesDao = categoriesDao,
       _branchesDao = branchesDao,
       _levelsDao = levelsDao,
       _ledgerDao = ledgerDao,
       _refundsDao = refundsDao,
       _prefs = prefs;

  // ─── Real-time change stream ─────────────────────────────────────────────

  /// Emits whenever a transaction or product variant changes so reports
  /// stay current after every sale without manual refresh.
  ///
  /// Uses [onListen]/[onCancel] so inner Drift subscriptions are created only
  /// when the cubit actually subscribes — avoiding the broadcast-before-listener
  /// timing race. [skip(1)] discards the immediate snapshot each Drift stream
  /// emits on subscribe; only genuine table mutations propagate.
  @override
  Stream<void> watchChanges({required String businessId}) {
    StreamSubscription<List<TransactionsTableData>>? txnSub;
    StreamSubscription<List<ProductVariantsTableData>>? variantSub;

    late final StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () {
        txnSub = _txnDao.watchTransactions().skip(1).listen((_) {
          if (!controller.isClosed) controller.add(null);
        });
        variantSub = _variantsDao.watchByBusinessId(businessId).skip(1).listen((
          _,
        ) {
          if (!controller.isClosed) controller.add(null);
        });
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
    final merged = <String, String>{};
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
      debugPrint('[ReportsRepo] Error reading BranchCubit cache: $e\n$st');
    }
    return merged;
  }

  // ─── Bucket helpers ───────────────────────────────────────────────────────

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<({DateTime start, DateTime end, String label})> _buildBuckets(
    DateTimeRange range,
    ReportPeriod period,
  ) {
    final cutoff = range.start;
    final rangeEnd = range.end.add(const Duration(days: 1));
    final rangeDays = range.end.difference(range.start).inDays + 1;

    // Single-day periods.
    if (rangeDays <= 2) {
      final days = rangeDays;
      return List.generate(days, (i) {
        final day = cutoff.add(Duration(days: i));
        return (
          start: day,
          end: day.add(const Duration(days: 1)),
          label: '${_months[day.month - 1]} ${day.day}',
        );
      });
    }

    // Monthly bucketing for lastMonth or large custom ranges (> 60 days).
    if (period == ReportPeriod.lastMonth ||
        (period == ReportPeriod.custom && rangeDays > 60)) {
      // Build one bucket per month in the range. The first bucket can start
      // mid-month, so clamp its start to the real cutoff and label it with the
      // start day to signal it is a partial month, not a full one.
      final buckets = <({DateTime start, DateTime end, String label})>[];
      var monthStart = DateTime(cutoff.year, cutoff.month);
      var first = true;
      while (monthStart.isBefore(rangeEnd)) {
        final monthEnd = _addMonths(monthStart, 1);
        final isPartialFirst = first && cutoff.isAfter(monthStart);
        final bucketStart = isPartialFirst ? cutoff : monthStart;
        final monthName = _months[monthStart.month - 1];
        buckets.add((
          start: bucketStart,
          end: monthEnd,
          label: isPartialFirst ? '$monthName ${cutoff.day}+' : monthName,
        ));
        monthStart = monthEnd;
        first = false;
      }
      return buckets;
    }

    // Weekly bucketing for large ranges (> 31 days).
    if (rangeDays > 31) {
      final weeks = (rangeDays / 7).ceil();
      return List.generate(weeks, (w) {
        final start = cutoff.add(Duration(days: w * 7));
        final end = start.add(const Duration(days: 7));
        return (
          start: start,
          end: end,
          label: '${_months[start.month - 1]} ${start.day}',
        );
      });
    }

    // Daily bucketing (default: ≤ 31 days).
    return List.generate(rangeDays, (i) {
      final day = cutoff.add(Duration(days: i));
      return (
        start: day,
        end: day.add(const Duration(days: 1)),
        label: (rangeDays <= 14 || i % 5 == 0 || i == rangeDays - 1)
            ? '${_months[day.month - 1]} ${day.day}'
            : '',
      );
    });
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

  /// Refunds are dated by when the refund happened, not the original sale —
  /// so they reduce the bucket/period they actually occurred in rather than
  /// retroactively rewriting a past period's chart data.
  double _sumRefundsInRange(
    List<RefundsTableData> refunds,
    DateTime from,
    DateTime to,
  ) {
    return refunds
        .where((r) => !r.createdAt.isBefore(from) && r.createdAt.isBefore(to))
        .fold(0.0, (s, r) => s + r.totalAmount);
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

  @override
  Future<ReportsData> load({
    required String businessId,
    String? branchId,
    required ReportPeriod period,
    DateTimeRange? customRange,
  }) async {
    final effectiveRange = customRange ?? period.dateRange;
    final cutoff = effectiveRange.start;
    final rangeEnd = effectiveRange.end.add(const Duration(days: 1));
    final rangeDays =
        effectiveRange.end.difference(effectiveRange.start).inDays + 1;
    final prevCutoff = cutoff.subtract(Duration(days: rangeDays));

    // ── 1. Fetch transactions ──────────────────────────────────────────────
    // Fetch enough for both current and previous periods.
    final allFiltered = await _txnDao.getTransactionsSince(
      prevCutoff,
      businessId: businessId,
      branchId: branchId,
    );
    final allBranches = branchId != null
        ? await _txnDao.getAllTransactionsSince(
            prevCutoff,
            businessId: businessId,
          )
        : allFiltered;

    // Partially/fully refunded sales still count toward gross — the refund
    // amounts fetched below are subtracted from the sums afterward, so a
    // fully refunded sale nets to zero automatically instead of needing a
    // special case here. Only a (currently unused) 'voided' status excludes.
    bool isCompleted(TransactionsTableData t) => t.status != 'voided';

    final allRefundsFiltered = await _refundsDao.getRefundsSince(
      prevCutoff,
      businessId: businessId,
      branchId: branchId,
    );
    final allRefundsAllBranch = branchId != null
        ? await _refundsDao.getAllRefundsSince(prevCutoff, businessId: businessId)
        : allRefundsFiltered;

    final currentTxns = allFiltered
        .where(
          (t) =>
              isCompleted(t) &&
              !t.createdAt.isBefore(cutoff) &&
              t.createdAt.isBefore(rangeEnd),
        )
        .toList();
    final prevTxns = allFiltered
        .where(
          (t) =>
              isCompleted(t) &&
              !t.createdAt.isBefore(prevCutoff) &&
              t.createdAt.isBefore(cutoff),
        )
        .toList();
    final currentAllBranch = allBranches
        .where(
          (t) =>
              isCompleted(t) &&
              !t.createdAt.isBefore(cutoff) &&
              t.createdAt.isBefore(rangeEnd),
        )
        .toList();
    final prevAllBranch = allBranches
        .where(
          (t) =>
              isCompleted(t) &&
              !t.createdAt.isBefore(prevCutoff) &&
              t.createdAt.isBefore(cutoff),
        )
        .toList();

    final currentRefunds = allRefundsFiltered
        .where(
          (r) => !r.createdAt.isBefore(cutoff) && r.createdAt.isBefore(rangeEnd),
        )
        .toList();
    final prevRefunds = allRefundsFiltered
        .where(
          (r) =>
              !r.createdAt.isBefore(prevCutoff) && r.createdAt.isBefore(cutoff),
        )
        .toList();
    final currentRefundsAllBranch = allRefundsAllBranch
        .where(
          (r) => !r.createdAt.isBefore(cutoff) && r.createdAt.isBefore(rangeEnd),
        )
        .toList();
    final prevRefundsAllBranch = allRefundsAllBranch
        .where(
          (r) =>
              !r.createdAt.isBefore(prevCutoff) && r.createdAt.isBefore(cutoff),
        )
        .toList();

    // ── 2. Fetch transaction items ─────────────────────────────────────────
    final currentIds = currentTxns.map((t) => t.id).toList();
    final prevIds = prevTxns.map((t) => t.id).toList();
    final currentItems = await _txnDao.getItemsForTransactions(currentIds);
    final prevItems = await _txnDao.getItemsForTransactions(prevIds);

    // Refund lines for the current/previous windows — used to reverse COGS
    // for refunded items so net profit isn't double-penalized (revenue is
    // credited back AND the original cost is un-counted, same as the sale
    // never having shipped that unit).
    final currentRefundItems = await _refundsDao.getItemsForRefunds(
      currentRefunds.map((r) => r.id).toList(),
    );
    final prevRefundItems = await _refundsDao.getItemsForRefunds(
      prevRefunds.map((r) => r.id).toList(),
    );

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
    final currentRefundTotal = currentRefunds.fold(
      0.0,
      (s, r) => s + r.totalAmount,
    );
    final prevRefundTotal = prevRefunds.fold(0.0, (s, r) => s + r.totalAmount);

    final totalRevenue =
        currentTxns.fold(0.0, (s, t) => s + t.totalAmount) - currentRefundTotal;
    final totalTransactions = currentTxns.length;
    final avgTicket = totalTransactions > 0
        ? totalRevenue / totalTransactions
        : 0.0;
    final itemsSold = currentItems.fold<double>(0, (s, i) => s + i.qty).round();

    final prevRevenue =
        prevTxns.fold(0.0, (s, t) => s + t.totalAmount) - prevRefundTotal;
    final prevTransactions = prevTxns.length;
    final prevAvgTicket = prevTransactions > 0
        ? prevRevenue / prevTransactions
        : 0.0;
    final prevItemsSold = prevItems
        .fold<double>(0, (s, i) => s + i.qty)
        .round();

    // Sales trend — refunds are credited to the bucket the refund happened
    // in, not the original sale's bucket (see _sumRefundsInRange).
    final buckets = _buildBuckets(effectiveRange, period);
    final salesTrend = buckets
        .map(
          (b) => SalesTrendPoint(
            label: b.label,
            total:
                _sumInRange(currentTxns, b.start, b.end) -
                _sumRefundsInRange(currentRefunds, b.start, b.end),
          ),
        )
        .toList();

    // Category breakdown
    final catAgg = <String, double>{};
    for (final item in currentItems) {
      final productId = variantToProduct[item.variantId];
      if (productId == null) continue;
      final catId = productToCategory[productId];
      final name = catId != null ? (categoryName[catId] ?? 'Other') : 'Other';
      catAgg[name] = (catAgg[name] ?? 0) + item.lineTotal;
    }
    final categoryBreakdown =
        (catAgg.entries
            .map((e) => CategoryStat(name: e.key, total: e.value))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total)));

    // ── 5. Inventory Health ───────────────────────────────────────────────
    final activeVariants = variants
        .where((v) => v.isActive && v.trackStock)
        .toList();
    final totalSKUs = activeVariants.length;

    // Per-variant qty sold in current period
    final variantQty = <String, double>{};
    for (final item in currentItems) {
      variantQty[item.variantId] = (variantQty[item.variantId] ?? 0) + item.qty;
    }

    final inventoryItems = <InventoryStatusItem>[];
    int lowStockCount = 0, fastMovers = 0, deadStockCount = 0;

    for (final v in activeVariants) {
      final pName = productToName[v.productId] ?? 'Unknown';
      final displayName = v.name == 'Default' ? pName : '$pName (${v.name})';
      final totalQty = variantQty[v.id] ?? 0;
      final avgDailySale = totalQty / rangeDays;
      final currentStock = v.stock;
      final daysLeft = avgDailySale > 0 ? currentStock / avgDailySale : null;

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

      inventoryItems.add(
        InventoryStatusItem(
          productName: displayName,
          status: status,
          currentStock: currentStock,
          avgDailySale: avgDailySale,
          daysLeft: daysLeft,
          notes: notes,
        ),
      );
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

    // Refunded items reverse both the revenue AND the cost they originally
    // contributed — otherwise a refund would dent profit by the full sale
    // amount instead of just the margin the sale actually contributed.
    final refundCogsByRefundId = <String, double>{};
    var currentRefundCogs = 0.0;
    for (final item in currentRefundItems) {
      final cp = variantMap[item.variantId]?.costPrice;
      if (cp == null) continue;
      final cost = cp * item.qty;
      currentRefundCogs += cost;
      refundCogsByRefundId[item.refundId] =
          (refundCogsByRefundId[item.refundId] ?? 0) + cost;
    }
    var prevRefundCogs = 0.0;
    for (final item in prevRefundItems) {
      final cp = variantMap[item.variantId]?.costPrice;
      if (cp != null) prevRefundCogs += cp * item.qty;
    }
    costOfGoods -= currentRefundCogs;

    // Collected tax is not merchant revenue — exclude it from profit math.
    // Gross revenue displays stay tax-inclusive; profit/margin use net revenue.
    final currentRefundNet = currentRefunds.fold(
      0.0,
      (s, r) => s + (r.totalAmount - r.taxAmount),
    );
    final prevRefundNet = prevRefunds.fold(
      0.0,
      (s, r) => s + (r.totalAmount - r.taxAmount),
    );
    final netRevenue =
        currentTxns.fold(0.0, (s, t) => s + (t.totalAmount - t.taxAmount)) -
        currentRefundNet;
    final prevNetRevenue =
        prevTxns.fold(0.0, (s, t) => s + (t.totalAmount - t.taxAmount)) -
        prevRefundNet;
    final netProfit = netRevenue - costOfGoods;

    var prevCogs = 0.0;
    for (final item in prevItems) {
      final cp = variantMap[item.variantId]?.costPrice;
      if (cp != null) prevCogs += cp * item.qty;
    }
    prevCogs -= prevRefundCogs;
    final prevNetProfit = prevNetRevenue - prevCogs;

    // Profit trend (revenue + COGS per bucket). Refunds are netted into the
    // bucket the refund happened in, mirroring the sales trend above.
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
      final bRefunds = currentRefunds.where(
        (r) => !r.createdAt.isBefore(b.start) && r.createdAt.isBefore(b.end),
      );
      final rev =
          bTxns.fold(0.0, (s, t) => s + (t.totalAmount - t.taxAmount)) -
          bRefunds.fold(0.0, (s, r) => s + (r.totalAmount - r.taxAmount));
      final cogs =
          bTxns.fold(0.0, (s, t) => s + (txnCogs[t.id] ?? 0)) -
          bRefunds.fold(0.0, (s, r) => s + (refundCogsByRefundId[r.id] ?? 0));
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
      final short = bId.length > 6 ? '…${bId.substring(bId.length - 6)}' : bId;
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
    for (final refund in currentRefundsAllBranch) {
      final key = refund.branchId ?? '__none__';
      final agg = branchAgg[key];
      if (agg != null) agg.revenue -= refund.totalAmount;
    }

    final prevBranchRev = <String, double>{};
    for (final txn in prevAllBranch) {
      final key = txn.branchId ?? '__none__';
      prevBranchRev[key] = (prevBranchRev[key] ?? 0) + txn.totalAmount;
    }
    for (final refund in prevRefundsAllBranch) {
      final key = refund.branchId ?? '__none__';
      prevBranchRev[key] = (prevBranchRev[key] ?? 0) - refund.totalAmount;
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

    // ── 8. Ingredient Health ──────────────────────────────────────────────
    final ingredientProductIds = products
        .where((p) => p.type == 'ingredient')
        .map((p) => p.id)
        .toSet();
    final ingredientVariants = variants
        .where((v) => ingredientProductIds.contains(v.productId))
        .toList();

    // Recipe consumption from ledger in current period
    final allLedger = await _ledgerDao.getByBusinessId(businessId);
    final consumedMap = <String, double>{};
    for (final entry in allLedger) {
      if (entry.sourceType != 'recipe_consumption') continue;
      if (entry.changeType != 'OUT') continue;
      if (entry.createdAt.isBefore(cutoff) ||
          // ignore: curly_braces_in_flow_control_structures
          !entry.createdAt.isBefore(rangeEnd))
        // ignore: curly_braces_in_flow_control_structures
        continue;
      if (branchId != null && entry.branchId != branchId) {
        continue;
      }
      consumedMap[entry.variantId] =
          (consumedMap[entry.variantId] ?? 0) + entry.quantity;
    }

    // Per-branch stock via inventory_levels when a branch is filtered
    Map<String, double>? branchLevelMap;
    if (branchId != null) {
      final levels = await _levelsDao.getByBusinessId(businessId);
      branchLevelMap = {};
      for (final level in levels) {
        if (level.branchId != branchId) continue;
        branchLevelMap[level.variantId] = level.quantity;
      }
    }

    final ingredientItems = <IngredientReportItem>[];
    int lowIngredientCount = 0;
    double ingredientConsumptionCost = 0;

    for (final v in ingredientVariants) {
      final name = productToName[v.productId] ?? 'Unknown';
      final currentStock = branchLevelMap != null
          ? (branchLevelMap[v.id] ?? 0.0)
          : v.stock;
      final consumedQty = consumedMap[v.id] ?? 0.0;
      final avgDailyConsumption = consumedQty / rangeDays;
      final daysLeft = avgDailyConsumption > 0
          ? currentStock / avgDailyConsumption
          : null;

      InventoryStatusType status;
      final threshold = v.lowStockAlert;
      if ((threshold != null && currentStock <= threshold) ||
          (threshold == null && currentStock <= 0)) {
        status = InventoryStatusType.low;
        lowIngredientCount++;
      } else if (daysLeft != null && daysLeft <= 5) {
        status = InventoryStatusType.warning;
      } else if (avgDailyConsumption < 0.01) {
        status = InventoryStatusType.slowMoving;
      } else {
        status = InventoryStatusType.ok;
      }

      if (v.costPrice != null) {
        ingredientConsumptionCost += consumedQty * v.costPrice!;
      }

      ingredientItems.add(
        IngredientReportItem(
          name: name,
          unit: v.unit,
          currentStock: currentStock,
          consumed: consumedQty,
          avgDailyConsumption: avgDailyConsumption,
          daysLeft: daysLeft,
          costPerUnit: v.costPrice,
          status: status,
        ),
      );
    }

    ingredientItems.sort(
      (a, b) => statusOrder[a.status]!.compareTo(statusOrder[b.status]!),
    );

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
      totalIngredients: ingredientVariants.length,
      lowIngredientCount: lowIngredientCount,
      ingredientConsumptionCost: ingredientConsumptionCost,
      ingredientItems: ingredientItems,
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
