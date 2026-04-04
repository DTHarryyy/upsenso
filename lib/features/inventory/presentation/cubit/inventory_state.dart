import 'package:equatable/equatable.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';

enum InventoryViewMode { cards, table }

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final InventoryData data;

  /// Filtered + searched subset of data.items shown in the UI.
  final List<InventoryItem> displayItems;
  final String searchQuery;
  final String? selectedBranchId;
  final StockStatus? statusFilter; // null = All
  final InventoryViewMode viewMode;

  const InventoryLoaded({
    required this.data,
    required this.displayItems,
    required this.searchQuery,
    this.selectedBranchId,
    this.statusFilter,
    this.viewMode = InventoryViewMode.table,
  });

  InventoryLoaded copyWith({
    InventoryData? data,
    List<InventoryItem>? displayItems,
    String? searchQuery,
    Object? selectedBranchId = _sentinel,
    Object? statusFilter = _sentinel,
    InventoryViewMode? viewMode,
  }) {
    return InventoryLoaded(
      data: data ?? this.data,
      displayItems: displayItems ?? this.displayItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBranchId: selectedBranchId == _sentinel
          ? this.selectedBranchId
          : selectedBranchId as String?,
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as StockStatus?,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props =>
      [data, displayItems, searchQuery, selectedBranchId, statusFilter, viewMode];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

const _sentinel = Object();
