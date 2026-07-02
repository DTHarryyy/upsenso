import 'package:pos/features/crm/domain/entities/customer.dart';

/// Triage filters for the customer directory.
enum CustomerFilter { all, active, inactive }

enum CustomerSort { nameAsc, recentlyAdded }

sealed class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final String? searchQuery;
  final CustomerFilter filter;
  final CustomerSort sort;

  CustomerLoaded({
    required this.customers,
    this.searchQuery,
    this.filter = CustomerFilter.all,
    this.sort = CustomerSort.nameAsc,
  });

  // ── Derived data ───────────────────────────────────────────────────────────

  List<Customer> get _searched {
    final q = searchQuery?.toLowerCase().trim() ?? '';
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  bool _passes(CustomerFilter f, Customer c) {
    switch (f) {
      case CustomerFilter.all:
        return true;
      case CustomerFilter.active:
        return c.isActive;
      case CustomerFilter.inactive:
        return !c.isActive;
    }
  }

  int _sortCompare(Customer a, Customer b) {
    switch (sort) {
      case CustomerSort.nameAsc:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case CustomerSort.recentlyAdded:
        return b.createdAt.compareTo(a.createdAt);
    }
  }

  /// Cards to render: search → active filter → sort.
  List<Customer> get items {
    final list = _searched.where((c) => _passes(filter, c)).toList()
      ..sort(_sortCompare);
    return list;
  }

  /// Count per filter chip (search applied, active filter ignored).
  Map<CustomerFilter, int> get filterCounts {
    final base = _searched;
    return {
      for (final f in CustomerFilter.values)
        f: base.where((c) => _passes(f, c)).length,
    };
  }

  /// Portfolio summary for the KPI strip.
  ({int total, int active}) get kpis {
    final active = customers.where((c) => c.isActive).length;
    return (total: customers.length, active: active);
  }
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class CustomerActionInProgress extends CustomerState {
  final List<Customer> customers;
  CustomerActionInProgress(this.customers);
}
