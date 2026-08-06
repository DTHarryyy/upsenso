import 'package:equatable/equatable.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';

/// Typed navigation state for opening Inventory from dashboard alerts and
/// other deep links.
class InventoryNavigationArgs extends Equatable {
  final StockStatus? initialStatus;
  final String? focusedVariantId;

  const InventoryNavigationArgs({this.initialStatus, this.focusedVariantId});

  @override
  List<Object?> get props => [initialStatus, focusedVariantId];
}
