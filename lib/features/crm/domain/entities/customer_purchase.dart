import 'package:pos/core/database/app_database.dart';

/// One completed sale in a customer's purchase history. A thin, UI-facing view
/// over a [TransactionsTableData] row so the detail page never touches Drift
/// types directly.
class CustomerPurchase {
  final String id;
  final String? invoiceNumber;
  final double totalAmount;
  final int itemCount;
  final String paymentMethod;
  final DateTime createdAt;

  const CustomerPurchase({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.itemCount,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory CustomerPurchase.fromRow(TransactionsTableData row) =>
      CustomerPurchase(
        id: row.id,
        invoiceNumber: row.invoiceNumber,
        totalAmount: row.totalAmount,
        itemCount: row.itemCount,
        paymentMethod: row.paymentMethod,
        createdAt: row.createdAt,
      );
}

/// Aggregated purchase stats for one customer, derived from their completed
/// sales. Pure value object — [CustomerRepository] computes it from the
/// purchase list so the list and detail always agree.
class CustomerStats {
  final int orderCount;
  final double totalSpent;
  final DateTime? lastVisitAt;

  const CustomerStats({
    this.orderCount = 0,
    this.totalSpent = 0,
    this.lastVisitAt,
  });

  double get averageOrderValue =>
      orderCount == 0 ? 0 : totalSpent / orderCount;

  /// Builds the stats from a customer's completed purchases.
  factory CustomerStats.fromPurchases(List<CustomerPurchase> purchases) {
    if (purchases.isEmpty) return const CustomerStats();
    var total = 0.0;
    DateTime? last;
    for (final p in purchases) {
      total += p.totalAmount;
      if (last == null || p.createdAt.isAfter(last)) last = p.createdAt;
    }
    return CustomerStats(
      orderCount: purchases.length,
      totalSpent: total,
      lastVisitAt: last,
    );
  }
}
