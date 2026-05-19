import 'package:flutter/material.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';

// ─── Period enum ──────────────────────────────────────────────────────────────

enum ReportPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  custom,
}

extension ReportPeriodX on ReportPeriod {
  String get label => const {
    ReportPeriod.today: 'Today',
    ReportPeriod.yesterday: 'Yesterday',
    ReportPeriod.last7Days: 'Last 7 days',
    ReportPeriod.last30Days: 'Last 30 days',
    ReportPeriod.thisMonth: 'This month',
    ReportPeriod.lastMonth: 'Last month',
    ReportPeriod.custom: 'Custom range',
  }[this]!;

  DateTimeRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      ReportPeriod.today => DateTimeRange(start: today, end: today),
      ReportPeriod.yesterday => DateTimeRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      ReportPeriod.last7Days => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      ReportPeriod.last30Days => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      ReportPeriod.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: today,
      ),
      ReportPeriod.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
      ReportPeriod.custom => DateTimeRange(start: today, end: today),
    };
  }

  int get days => dateRange.end.difference(dateRange.start).inDays + 1;
}

// ─── Inventory status ─────────────────────────────────────────────────────────

enum InventoryStatusType { low, warning, ok, slowMoving }

extension InventoryStatusTypeX on InventoryStatusType {
  String get label => const {
    InventoryStatusType.low: 'Low',
    InventoryStatusType.warning: 'Warning',
    InventoryStatusType.ok: 'Ok',
    InventoryStatusType.slowMoving: 'Slow Moving',
  }[this]!;
}

// ─── Data models ──────────────────────────────────────────────────────────────

class InventoryStatusItem {
  final String productName;
  final InventoryStatusType status;
  final double currentStock;
  final double avgDailySale;
  final double? daysLeft; // null = effectively infinite
  final String? notes;

  const InventoryStatusItem({
    required this.productName,
    required this.status,
    required this.currentStock,
    required this.avgDailySale,
    this.daysLeft,
    this.notes,
  });
}

class SalesTrendPoint {
  final String label; // empty = don't show label on axis
  final double total;
  const SalesTrendPoint({required this.label, required this.total});
}

class ProfitTrendPoint {
  final String label;
  final double revenue;
  final double cogs;
  const ProfitTrendPoint({
    required this.label,
    required this.revenue,
    required this.cogs,
  });
}

class BranchReportStat {
  final String name;
  final double totalSales;
  final int transactions;
  final double avgTicket;
  final double vsLastPeriodPct;
  final bool isTop;

  const BranchReportStat({
    required this.name,
    required this.totalSales,
    required this.transactions,
    required this.avgTicket,
    required this.vsLastPeriodPct,
    required this.isTop,
  });
}

// ─── Main reports data class ──────────────────────────────────────────────────

class ReportsData {
  // Sales Report
  final double totalRevenue;
  final int totalTransactions;
  final double avgTicket;
  final int itemsSold;
  final double prevTotalRevenue;
  final int prevTotalTransactions;
  final double prevAvgTicket;
  final int prevItemsSold;
  final List<SalesTrendPoint> salesTrend;
  final List<CategoryStat> categoryBreakdown;

  // Inventory Health
  final int lowStockCount;
  final int fastMoversCount;
  final int deadStockCount;
  final int totalSKUs;
  final List<InventoryStatusItem> inventoryItems;

  // Profit Summary
  final double grossRevenue;
  final double costOfGoods;
  final double netProfit;
  final double prevNetProfit;
  final List<ProfitTrendPoint> profitTrend;

  // Branch Comparison
  final List<BranchReportStat> branchStats;

  const ReportsData({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.avgTicket,
    required this.itemsSold,
    required this.prevTotalRevenue,
    required this.prevTotalTransactions,
    required this.prevAvgTicket,
    required this.prevItemsSold,
    required this.salesTrend,
    required this.categoryBreakdown,
    required this.lowStockCount,
    required this.fastMoversCount,
    required this.deadStockCount,
    required this.totalSKUs,
    required this.inventoryItems,
    required this.grossRevenue,
    required this.costOfGoods,
    required this.netProfit,
    required this.prevNetProfit,
    required this.profitTrend,
    required this.branchStats,
  });

  static ReportsData empty() => const ReportsData(
    totalRevenue: 0,
    totalTransactions: 0,
    avgTicket: 0,
    itemsSold: 0,
    prevTotalRevenue: 0,
    prevTotalTransactions: 0,
    prevAvgTicket: 0,
    prevItemsSold: 0,
    salesTrend: [],
    categoryBreakdown: [],
    lowStockCount: 0,
    fastMoversCount: 0,
    deadStockCount: 0,
    totalSKUs: 0,
    inventoryItems: [],
    grossRevenue: 0,
    costOfGoods: 0,
    netProfit: 0,
    prevNetProfit: 0,
    profitTrend: [],
    branchStats: [],
  );
}
