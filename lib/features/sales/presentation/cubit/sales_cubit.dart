import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';
import 'package:pos/features/sales/presentation/cubit/sales_state.dart';

/// Manages the state of the Sales History screen.
///
/// Lifecycle:
/// 1. Call [startWatching] once (or again when the selected branch changes).
/// 2. Call [toggleExpand] when the user taps a transaction row.
/// 3. The cubit cancels the stream on [close].
class SalesCubit extends Cubit<SalesState> {
  final ISalesRepository _repository;

  StreamSubscription<List<SaleTransaction>>? _watcher;

  SalesCubit(this._repository) : super(const SalesInitial());

  /// Subscribes to transactions for [branchId] (all branches when `null`).
  /// Safe to call multiple times — the previous subscription is always cancelled first.
  void startWatching({String? branchId}) {
    _watcher?.cancel();
    emit(const SalesLoading());

    _watcher = _repository
        .watchTransactions(branchId: branchId)
        .listen(
          (txns) {
            if (isClosed) return;
            final current = state;
            emit(
              SalesLoaded(
                transactions: txns,
                // Preserve any open expand panel across live updates.
                expandedTxId: current is SalesLoaded
                    ? current.expandedTxId
                    : null,
                expandedItems: current is SalesLoaded
                    ? current.expandedItems
                    : null,
              ),
            );
          },
          onError: (Object e) {
            if (!isClosed) emit(SalesError(AppErrorMapper.message(e)));
          },
        );
  }

  /// Collapses if [txId] is already expanded; otherwise fetches and shows
  /// the line items for [txId].
  Future<void> toggleExpand(String txId) async {
    final current = state;
    if (current is! SalesLoaded) return;

    // Collapse
    if (current.expandedTxId == txId) {
      emit(current.copyWith(expandedTxId: null, expandedItems: null));
      return;
    }

    // Show spinner while fetching
    emit(
      current.copyWith(
        expandedTxId: txId,
        expandedItems: null,
        isLoadingItems: true,
      ),
    );

    try {
      final items = await _repository.getTransactionItems(txId);
      if (isClosed) return;
      final s = state;
      if (s is SalesLoaded && s.expandedTxId == txId) {
        emit(s.copyWith(expandedItems: items, isLoadingItems: false));
      }
    } catch (_) {
      if (!isClosed) {
        final s = state;
        if (s is SalesLoaded) emit(s.copyWith(isLoadingItems: false));
      }
    }
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
