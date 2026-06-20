import 'package:equatable/equatable.dart';

/// Pure domain entity for an inventory level record.
class InventoryLevel extends Equatable {
  final String variantId;
  final String branchId;
  final String businessId;
  final double quantity;

  const InventoryLevel({
    required this.variantId,
    required this.branchId,
    required this.businessId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [variantId, branchId, businessId, quantity];
}
