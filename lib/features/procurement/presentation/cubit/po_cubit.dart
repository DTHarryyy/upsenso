import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';

class PoCubit extends Cubit<PoState> {
  final IProcurementRepository _repository;
  final PermissionService _permissions;
  final String businessId;
  final String userId;
  final String userName;

  /// The operating branch a new PO is tagged with so received stock lands in the
  /// right branch. Sourced from the active session/selected branch at construction.
  final String? branchId;

  StreamSubscription? _subscription;

  PoCubit({
    required IProcurementRepository repository,
    required PermissionService permissions,
    required this.businessId,
    required this.userId,
    required this.userName,
    this.branchId,
  }) : _repository = repository,
       _permissions = permissions,
       super(PoInitial());

  // Defense-in-depth: hidden buttons aren't access control, so every mutation
  // re-checks permission here. guard() also writes the denial to the audit log.
  Future<bool> _allowed(AppPermission permission, {String? entityId}) async {
    final result = await _permissions.guard(
      permission,
      entityType: 'purchase_order',
      entityId: entityId,
    );
    if (result.granted) return true;
    emit(PoError(result.deniedReason ?? 'You do not have permission for this.'));
    emit(PoLoaded(orders: _currentOrders()));
    return false;
  }

  void watch() {
    emit(PoLoading());
    _subscription?.cancel();
    _subscription = _repository.watchPurchaseOrders(businessId).listen(
      (orders) {
        final current = state;
        final query = current is PoLoaded ? current.searchQuery : '';
        final filter = current is PoLoaded ? current.statusFilter : null;
        emit(PoLoaded(orders: orders, searchQuery: query, statusFilter: filter));
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[PoCubit] watch error: $e\n$st');
        emit(PoError('Failed to load purchase orders.'));
      },
    );
  }

  void search(String query) {
    final current = state;
    if (current is PoLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  void filterByStatus(PoStatus? status) {
    final current = state;
    if (current is PoLoaded) {
      emit(current.copyWith(statusFilter: status));
    }
  }

  Future<String?> createPurchaseOrder({
    String? supplierId,
    String? supplierName,
    String? branchId,
    String? notes,
    DateTime? expectedDelivery,
    double discount = 0,
    double shipping = 0,
    required List<PoLineInput> lines,
  }) async {
    if (!await _allowed(AppPermission.createPurchaseOrder)) return null;
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      final id = await _repository.createPurchaseOrder(
        businessId: businessId,
        // Tag the PO with the explicit branch if given, else the cubit's
        // operating branch — so receiving lands stock in the right branch.
        branchId: branchId ?? this.branchId,
        supplierId: supplierId,
        supplierName: supplierName,
        notes: notes,
        expectedDelivery: expectedDelivery,
        discount: discount,
        shipping: shipping,
        createdById: userId,
        createdByName: userName,
        lines: lines,
      );
      return id;
    } catch (e, st) {
      debugPrint('[PoCubit] Error in createPurchaseOrder: $e\n$st');
      emit(PoError('Failed to create purchase order.'));
      emit(PoLoaded(orders: currentOrders));
      return null;
    }
  }

  Future<void> updatePurchaseOrder({
    required String id,
    String? supplierId,
    String? supplierName,
    String? notes,
    DateTime? expectedDelivery,
    double? discount,
    double? shipping,
    List<PoLineInput>? lines,
  }) async {
    if (!await _allowed(AppPermission.createPurchaseOrder, entityId: id)) return;
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.updatePurchaseOrder(
        id: id,
        supplierId: supplierId,
        supplierName: supplierName,
        notes: notes,
        expectedDelivery: expectedDelivery,
        discount: discount,
        shipping: shipping,
        lines: lines,
      );
    } catch (e, st) {
      debugPrint('[PoCubit] Error in updatePurchaseOrder: $e\n$st');
      emit(PoError('Failed to update purchase order.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  Future<void> submitPurchaseOrder(String id) async {
    if (!await _allowed(AppPermission.createPurchaseOrder, entityId: id)) return;
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.submitPurchaseOrder(id);
    } catch (e, st) {
      debugPrint('[PoCubit] Error in submitPurchaseOrder: $e\n$st');
      emit(PoError('Failed to submit purchase order.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  Future<void> approvePurchaseOrder(String id) async {
    if (!await _allowed(AppPermission.approvePurchaseOrder, entityId: id)) {
      return;
    }
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.approvePurchaseOrder(
        id: id,
        approvedById: userId,
        approvedByName: userName,
      );
    } catch (e, st) {
      debugPrint('[PoCubit] Error in approvePurchaseOrder: $e\n$st');
      emit(PoError('Failed to approve purchase order.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  Future<void> receiveGoods({
    required String poId,
    required String branchId,
    required List<ReceiveLineInput> lines,
  }) async {
    if (!await _allowed(AppPermission.receiveGoodsAgainstPo, entityId: poId)) {
      return;
    }
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.receiveGoods(
        poId: poId,
        branchId: branchId,
        lines: lines,
        receivedById: userId,
        receivedByName: userName,
      );
    } catch (e, st) {
      debugPrint('[PoCubit] Error in receiveGoods: $e\n$st');
      emit(PoError('Failed to receive goods.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  /// Current PO approval threshold for the business (null = unset).
  Future<double?> loadApprovalThreshold() async {
    final settings = await _repository.getSettings(businessId);
    return settings.approvalThreshold;
  }

  /// Sets (or clears, with null) the PO approval threshold. Guarded — managing
  /// procurement configuration requires the manage permission.
  Future<bool> setApprovalThreshold(double? threshold) async {
    if (!await _allowed(AppPermission.manageProcurement)) return false;
    try {
      await _repository.updateApprovalThreshold(businessId, threshold);
      return true;
    } catch (e, st) {
      debugPrint('[PoCubit] Error in setApprovalThreshold: $e\n$st');
      emit(PoError('Failed to update approval threshold.'));
      emit(PoLoaded(orders: _currentOrders()));
      return false;
    }
  }

  Future<void> cancelPurchaseOrder(String id) async {
    if (!await _allowed(AppPermission.manageProcurement, entityId: id)) return;
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.cancelPurchaseOrder(id);
    } catch (e, st) {
      debugPrint('[PoCubit] Error in cancelPurchaseOrder: $e\n$st');
      emit(PoError('Failed to cancel purchase order.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  Future<void> closePurchaseOrder(String id) async {
    if (!await _allowed(AppPermission.manageProcurement, entityId: id)) return;
    final currentOrders = _currentOrders();
    emit(PoActionInProgress(currentOrders));
    try {
      await _repository.closePurchaseOrder(id);
    } catch (e, st) {
      debugPrint('[PoCubit] Error in closePurchaseOrder: $e\n$st');
      emit(PoError('Failed to close purchase order.'));
      emit(PoLoaded(orders: currentOrders));
    }
  }

  List<PurchaseOrder> _currentOrders() =>
      state is PoLoaded ? (state as PoLoaded).orders : const <PurchaseOrder>[];

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
