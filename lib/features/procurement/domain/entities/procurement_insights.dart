import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';

/// Pure procurement aggregates derived from the PO list (offline-first, no
/// queries). Kept out of the widget so it can be unit-tested directly.
class ProcurementInsights {
  final int outstandingCount;
  final double outstandingValue;
  final double receivedSpend;
  final int supplierCount;
  // Outstanding-PO aging buckets: [0–7d], [8–30d], [>30d].
  final int aging0Count, aging1Count, aging2Count;
  final double aging0Value, aging1Value, aging2Value;
  // Supplier name → received spend, highest first.
  final List<MapEntry<String, double>> topSuppliers;

  const ProcurementInsights({
    required this.outstandingCount,
    required this.outstandingValue,
    required this.receivedSpend,
    required this.supplierCount,
    required this.aging0Count,
    required this.aging1Count,
    required this.aging2Count,
    required this.aging0Value,
    required this.aging1Value,
    required this.aging2Value,
    required this.topSuppliers,
  });

  static bool _isOutstanding(PoStatus s) =>
      s == PoStatus.submitted ||
      s == PoStatus.approved ||
      s == PoStatus.partiallyReceived;

  factory ProcurementInsights.from(
    List<PurchaseOrder> orders, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final outstanding = orders.where((o) => _isOutstanding(o.status)).toList();
    final received = orders.where(
      (o) => o.status == PoStatus.received || o.status == PoStatus.closed,
    );

    var a0 = 0, a1 = 0, a2 = 0;
    var v0 = 0.0, v1 = 0.0, v2 = 0.0;
    for (final o in outstanding) {
      final days = ref.difference(o.createdAt).inDays;
      if (days <= 7) {
        a0++;
        v0 += o.totalAmount;
      } else if (days <= 30) {
        a1++;
        v1 += o.totalAmount;
      } else {
        a2++;
        v2 += o.totalAmount;
      }
    }

    final bySupplier = <String, double>{};
    for (final o in received) {
      final name = o.supplierName ?? 'No supplier';
      bySupplier[name] = (bySupplier[name] ?? 0) + o.totalAmount;
    }
    final top = bySupplier.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ProcurementInsights(
      outstandingCount: outstanding.length,
      outstandingValue: outstanding.fold(0, (s, o) => s + o.totalAmount),
      receivedSpend: received.fold(0, (s, o) => s + o.totalAmount),
      supplierCount:
          orders.map((o) => o.supplierId).whereType<String>().toSet().length,
      aging0Count: a0,
      aging1Count: a1,
      aging2Count: a2,
      aging0Value: v0,
      aging1Value: v1,
      aging2Value: v2,
      topSuppliers: top,
    );
  }
}
