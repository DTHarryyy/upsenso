import 'package:equatable/equatable.dart';
import 'package:pos/features/sales/domain/entities/sale_item.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';

// Sentinel used to distinguish "not passed" from `null` in copyWith.
const _sentinel = Object();

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {
  const SalesInitial();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoaded extends SalesState {
  final List<SaleTransaction> transactions;

  /// The transaction whose detail panel is currently open, if any.
  final String? expandedTxId;

  /// Line items for the expanded transaction, `null` while not yet loaded.
  final List<SaleItem>? expandedItems;

  /// `true` while the line-items are being fetched after an expand tap.
  final bool isLoadingItems;

  const SalesLoaded({
    required this.transactions,
    this.expandedTxId,
    this.expandedItems,
    this.isLoadingItems = false,
  });

  @override
  List<Object?> get props => [
    transactions,
    expandedTxId,
    expandedItems,
    isLoadingItems,
  ];

  SalesLoaded copyWith({
    List<SaleTransaction>? transactions,
    Object? expandedTxId = _sentinel,
    Object? expandedItems = _sentinel,
    bool? isLoadingItems,
  }) {
    return SalesLoaded(
      transactions: transactions ?? this.transactions,
      expandedTxId: expandedTxId == _sentinel
          ? this.expandedTxId
          : expandedTxId as String?,
      expandedItems: expandedItems == _sentinel
          ? this.expandedItems
          : expandedItems as List<SaleItem>?,
      isLoadingItems: isLoadingItems ?? this.isLoadingItems,
    );
  }
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object?> get props => [message];
}
