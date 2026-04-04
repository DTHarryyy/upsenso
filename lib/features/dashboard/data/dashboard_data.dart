class DashboardData {
  final double todaySales;
  final double weekSales;
  final int todayTransactionCount;
  final double avgOrderValue;
  final double yesterdaySales;
  final double lastWeekSales;
  final int yesterdayTransactionCount;
  final double yesterdayAvgOrderValue;

  // 7-day trend (oldest → newest)
  final List<double> sevenDayTotals;
  final List<String> sevenDayLabels;

  // 30-day trend (oldest → newest)
  final List<double> thirtyDayTotals;
  final List<String> thirtyDayLabels;

  final List<CategoryStat> categoryStats;
  final List<TopItem> topItems;
  final Map<String, double> paymentBreakdown;
  final List<LowStockItem> lowStockItems;
  final List<BranchStat> branchStats;

  const DashboardData({
    required this.todaySales,
    required this.weekSales,
    required this.todayTransactionCount,
    required this.avgOrderValue,
    required this.yesterdaySales,
    required this.lastWeekSales,
    required this.yesterdayTransactionCount,
    required this.yesterdayAvgOrderValue,
    required this.sevenDayTotals,
    required this.sevenDayLabels,
    required this.thirtyDayTotals,
    required this.thirtyDayLabels,
    required this.categoryStats,
    required this.topItems,
    required this.paymentBreakdown,
    required this.lowStockItems,
    required this.branchStats,
  });

  static DashboardData empty() => const DashboardData(
        todaySales: 0,
        weekSales: 0,
        todayTransactionCount: 0,
        avgOrderValue: 0,
        yesterdaySales: 0,
        lastWeekSales: 0,
        yesterdayTransactionCount: 0,
        yesterdayAvgOrderValue: 0,
        sevenDayTotals: [0, 0, 0, 0, 0, 0, 0],
        sevenDayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        thirtyDayTotals: [],
        thirtyDayLabels: [],
        categoryStats: [],
        topItems: [],
        paymentBreakdown: {},
        lowStockItems: [],
        branchStats: [],
      );
}

class CategoryStat {
  final String name;
  final double total;
  const CategoryStat({required this.name, required this.total});
}

class TopItem {
  final String name;
  final int sold;
  final double revenue;
  const TopItem({required this.name, required this.sold, required this.revenue});
}

class LowStockItem {
  final String displayName;
  final int currentStock;
  /// null means no threshold was set — item is shown only because stock == 0.
  final int? reorderAt;
  const LowStockItem({
    required this.displayName,
    required this.currentStock,
    required this.reorderAt,
  });
}

class BranchStat {
  final String name;
  final int txnCount;
  final double totalRevenue;
  final bool isTop;
  const BranchStat({
    required this.name,
    required this.txnCount,
    required this.totalRevenue,
    required this.isTop,
  });
}
