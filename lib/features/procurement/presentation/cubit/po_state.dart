import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';

sealed class PoState {}

class PoInitial extends PoState {}

class PoLoading extends PoState {}

class PoLoaded extends PoState {
  final List<PurchaseOrder> orders;
  final String searchQuery;
  final PoStatus? statusFilter;

  PoLoaded({
    required this.orders,
    this.searchQuery = '',
    this.statusFilter,
  });

  List<PurchaseOrder> get filtered {
    var result = orders;
    if (statusFilter != null) {
      result = result.where((o) => o.status == statusFilter).toList();
    }
    final q = searchQuery.toLowerCase().trim();
    if (q.isNotEmpty) {
      result = result.where((o) {
        return o.poNumber.toLowerCase().contains(q) ||
            (o.supplierName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  PoLoaded copyWith({
    List<PurchaseOrder>? orders,
    String? searchQuery,
    Object? statusFilter = _sentinel,
  }) => PoLoaded(
    orders: orders ?? this.orders,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter:
        statusFilter == _sentinel
            ? this.statusFilter
            : statusFilter as PoStatus?,
  );

  static const _sentinel = Object();
}

class PoError extends PoState {
  final String message;
  PoError(this.message);
}

class PoActionInProgress extends PoState {
  final List<PurchaseOrder> orders;
  PoActionInProgress(this.orders);
}
