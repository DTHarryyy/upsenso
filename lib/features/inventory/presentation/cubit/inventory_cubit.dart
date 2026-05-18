import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/inventory/presentation/cubit/inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final IInventoryRepository _repository;

  StreamSubscription<void>? _watcher;
  String? _businessId;
  String? _branchId;
  bool _isLoading = false;
  bool _pendingReload = false;

  // Local filter / view state preserved across reloads
  String _searchQuery = '';
  StockStatus? _statusFilter;
  InventoryViewMode _viewMode = InventoryViewMode.table;

  InventoryCubit(IInventoryRepository repository)
    : _repository = repository,
      super(const InventoryInitial());

  Future<void> startWatching({
    required String businessId,
    String? branchId,
  }) async {
    _businessId = businessId;
    _branchId = branchId;

    await _watcher?.cancel();
    await _doLoad(showSpinner: true);

    _watcher = _repository.watchChanges(businessId).listen((_) {
      _doLoad(showSpinner: false);
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(StockStatus? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setBranchFilter(String? branchId) {
    _branchId = branchId;
    _doLoad(showSpinner: false);
  }

  void setViewMode(InventoryViewMode mode) {
    _viewMode = mode;
    final current = state;
    if (current is InventoryLoaded) {
      emit(current.copyWith(viewMode: mode));
    }
  }

  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final branchId = _branchId;
    if (branchId == null || branchId.trim().isEmpty) {
      if (!isClosed) {
        emit(
          const InventoryError('Select a branch first before adjusting stock.'),
        );
      }
      return;
    }

    await _repository.adjustStock(
      variantId: variantId,
      productId: productId,
      businessId: businessId,
      branchId: branchId,
      isIncoming: isIncoming,
      quantity: quantity,
      reason: reason,
      note: note,
    );

    final entityLabel = variantName.isNotEmpty
        ? '$productName · $variantName'
        : productName;
    sl<AuditLogService>().log(
      actionType: AuditLogActionType.stockAdjusted,
      entityType: 'inventory',
      entityName: entityLabel,
      description:
          '${isIncoming ? 'Stock in' : 'Stock out'}: $quantity unit(s) of $entityLabel — $reason',
      metadata: {
        'is_incoming': isIncoming,
        'quantity': quantity,
        'reason': reason,
        'note': ?note,
      },
      businessId: businessId,
      branchId: branchId,
    );

    // The watcher will trigger a reload automatically.
    // For optimistic update, trigger immediately.
    await _doLoad(showSpinner: false);
  }

  Future<void> _doLoad({required bool showSpinner}) async {
    if (isClosed) return;
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) return;

    if (_isLoading) {
      _pendingReload = true;
      return;
    }

    _isLoading = true;
    _pendingReload = false;

    if (showSpinner) emit(const InventoryLoading());

    try {
      final data = await _repository.load(
        businessId: businessId,
        branchId: _branchId,
      );
      if (!isClosed) {
        final filtered = _filter(data.items);
        emit(
          InventoryLoaded(
            data: data,
            displayItems: filtered,
            searchQuery: _searchQuery,
            selectedBranchId: _branchId,
            statusFilter: _statusFilter,
            viewMode: _viewMode,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(InventoryError(AppErrorMapper.message(e)));
    } finally {
      _isLoading = false;
      if (_pendingReload && !isClosed) {
        _pendingReload = false;
        _doLoad(showSpinner: false);
      }
    }
  }

  void _applyFilters() {
    final current = state;
    if (current is! InventoryLoaded) return;
    final filtered = _filter(current.data.items);
    emit(
      current.copyWith(
        displayItems: filtered,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
      ),
    );
  }

  List<InventoryItem> _filter(List<InventoryItem> items) {
    var result = items;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) {
        return i.productName.toLowerCase().contains(q) ||
            (i.sku?.toLowerCase().contains(q) ?? false) ||
            i.variantName.toLowerCase().contains(q);
      }).toList();
    }
    if (_statusFilter != null) {
      result = result.where((i) => i.status == _statusFilter).toList();
    }
    return result;
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
