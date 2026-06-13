import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';

/// Triage filters for the supplier directory. PO-derived filters
/// ([recentlyUsed], [openOrders]) read the aggregated metrics, not the row.
enum SupplierFilter { all, active, inactive, recentlyUsed, openOrders }

enum SupplierSort { nameAsc, recentOrder, spend, openValue }

/// Procurement metrics derived from the supplier's purchase orders. Mirrors the
/// math on the supplier detail page so the list and detail always agree.
class SupplierMetrics {
  final int orderCount; // non-cancelled
  final double openValue; // ₱ of open (un-received, non-cancelled) POs
  final DateTime? lastOrderAt;
  final double totalSpend; // ₱ of received POs

  const SupplierMetrics({
    this.orderCount = 0,
    this.openValue = 0,
    this.lastOrderAt,
    this.totalSpend = 0,
  });
}

/// A supplier paired with its derived metrics, ready to render on a card.
class SupplierListItem {
  final Supplier supplier;
  final SupplierMetrics metrics;

  const SupplierListItem({required this.supplier, required this.metrics});
}

sealed class SupplierState {}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  final List<PurchaseOrder> orders;
  final String? searchQuery;
  final SupplierFilter filter;
  final SupplierSort sort;

  SupplierLoaded({
    required this.suppliers,
    this.orders = const [],
    this.searchQuery,
    this.filter = SupplierFilter.all,
    this.sort = SupplierSort.nameAsc,
  });

  SupplierLoaded copyWith({
    List<Supplier>? suppliers,
    List<PurchaseOrder>? orders,
    String? searchQuery,
    bool clearSearch = false,
    SupplierFilter? filter,
    SupplierSort? sort,
  }) => SupplierLoaded(
    suppliers: suppliers ?? this.suppliers,
    orders: orders ?? this.orders,
    searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
  );

  // ── Derived data ───────────────────────────────────────────────────────────

  Map<String, List<PurchaseOrder>> get _ordersBySupplier {
    final map = <String, List<PurchaseOrder>>{};
    for (final o in orders) {
      final sid = o.supplierId;
      if (sid == null) continue;
      (map[sid] ??= []).add(o);
    }
    return map;
  }

  SupplierMetrics _metricsFor(List<PurchaseOrder> pos) {
    var count = 0;
    var open = 0.0;
    var spend = 0.0;
    DateTime? last;
    for (final o in pos) {
      if (o.status != PoStatus.cancelled) count++;
      if (!o.status.isClosed && o.status != PoStatus.cancelled) {
        open += o.totalAmount;
      }
      if (o.status == PoStatus.received) spend += o.totalAmount;
      if (last == null || o.createdAt.isAfter(last)) last = o.createdAt;
    }
    return SupplierMetrics(
      orderCount: count,
      openValue: open,
      lastOrderAt: last,
      totalSpend: spend,
    );
  }

  // Suppliers + metrics with the search query applied, but before the active
  // filter — the base for both [items] and the per-chip counts.
  List<SupplierListItem> get _searched {
    final grouped = _ordersBySupplier;
    final q = searchQuery?.toLowerCase().trim() ?? '';
    final base = suppliers.map(
      (s) => SupplierListItem(
        supplier: s,
        metrics: _metricsFor(grouped[s.id] ?? const []),
      ),
    );
    if (q.isEmpty) return base.toList();
    return base.where((i) {
      final s = i.supplier;
      return s.name.toLowerCase().contains(q) ||
          (s.contactName?.toLowerCase().contains(q) ?? false) ||
          (s.phone?.contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  bool _passes(SupplierFilter f, SupplierListItem i) {
    switch (f) {
      case SupplierFilter.all:
        return true;
      case SupplierFilter.active:
        return i.supplier.isActive;
      case SupplierFilter.inactive:
        return !i.supplier.isActive;
      case SupplierFilter.recentlyUsed:
        final last = i.metrics.lastOrderAt;
        return last != null && DateTime.now().difference(last).inDays <= 30;
      case SupplierFilter.openOrders:
        return i.metrics.openValue > 0;
    }
  }

  int _sortCompare(SupplierListItem a, SupplierListItem b) {
    switch (sort) {
      case SupplierSort.nameAsc:
        return a.supplier.name.toLowerCase().compareTo(
          b.supplier.name.toLowerCase(),
        );
      case SupplierSort.recentOrder:
        final al = a.metrics.lastOrderAt;
        final bl = b.metrics.lastOrderAt;
        if (al == null && bl == null) return 0;
        if (al == null) return 1; // nulls last
        if (bl == null) return -1;
        return bl.compareTo(al);
      case SupplierSort.spend:
        return b.metrics.totalSpend.compareTo(a.metrics.totalSpend);
      case SupplierSort.openValue:
        return b.metrics.openValue.compareTo(a.metrics.openValue);
    }
  }

  /// Cards to render: search → active filter → sort.
  List<SupplierListItem> get items {
    final list = _searched.where((i) => _passes(filter, i)).toList()
      ..sort(_sortCompare);
    return list;
  }

  /// Count per filter chip (search applied, active filter ignored).
  Map<SupplierFilter, int> get filterCounts {
    final base = _searched;
    return {
      for (final f in SupplierFilter.values)
        f: base.where((i) => _passes(f, i)).length,
    };
  }

  /// Portfolio summary for the KPI strip.
  ({int total, int active, double openValue, int reorder}) get kpis {
    final grouped = _ordersBySupplier;
    var open = 0.0;
    var reorder = 0;
    var active = 0;
    for (final s in suppliers) {
      if (s.isActive) active++;
      final m = _metricsFor(grouped[s.id] ?? const []);
      open += m.openValue;
      if (s.isActive) {
        final last = m.lastOrderAt;
        if (last == null || DateTime.now().difference(last).inDays > 30) {
          reorder++;
        }
      }
    }
    return (
      total: suppliers.length,
      active: active,
      openValue: open,
      reorder: reorder,
    );
  }
}

class SupplierError extends SupplierState {
  final String message;
  SupplierError(this.message);
}

class SupplierActionInProgress extends SupplierState {
  final List<Supplier> suppliers;
  SupplierActionInProgress(this.suppliers);
}
