import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final IProcurementRepository _repository;
  final String businessId;

  StreamSubscription? _supplierSub;
  StreamSubscription? _orderSub;

  // Raw streams merged into each emitted SupplierLoaded (ProductsCubit pattern):
  // suppliers gate the first paint; PO data powers the derived metrics/filters.
  List<Supplier> _suppliers = [];
  List<PurchaseOrder> _orders = [];
  bool _suppliersReady = false;

  // Triage state held on the cubit so it survives action-in-progress emissions.
  String? _search;
  SupplierFilter _filter = SupplierFilter.all;
  SupplierSort _sort = SupplierSort.nameAsc;

  SupplierCubit({
    required IProcurementRepository repository,
    required this.businessId,
  }) : _repository = repository,
       super(SupplierInitial());

  void watch() {
    emit(SupplierLoading());
    _suppliersReady = false;
    _supplierSub?.cancel();
    _orderSub?.cancel();

    _supplierSub = _repository.watchSuppliers(businessId).listen(
      (suppliers) {
        _suppliers = suppliers;
        _suppliersReady = true;
        _emit();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[SupplierCubit] supplier watch error: $e\n$st');
        emit(SupplierError('Failed to load suppliers.'));
      },
    );

    _orderSub = _repository.watchPurchaseOrders(businessId).listen(
      (orders) {
        _orders = orders;
        _emit();
      },
      onError: (Object e, StackTrace st) {
        // Metrics degrade gracefully to zero — the list still works.
        debugPrint('[SupplierCubit] order watch error: $e\n$st');
      },
    );
  }

  void _emit() {
    if (!_suppliersReady || isClosed) return;
    emit(
      SupplierLoaded(
        suppliers: _suppliers,
        orders: _orders,
        searchQuery: _search,
        filter: _filter,
        sort: _sort,
      ),
    );
  }

  void search(String query) {
    _search = query.trim().isEmpty ? null : query;
    _emit();
  }

  void setFilter(SupplierFilter filter) {
    _filter = filter;
    _emit();
  }

  void setSort(SupplierSort sort) {
    _sort = sort;
    _emit();
  }

  Future<void> createSupplier({
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
  }) async {
    final current = state;
    if (current is! SupplierLoaded) return;
    emit(SupplierActionInProgress(current.suppliers));
    try {
      await _repository.createSupplier(
        businessId: businessId,
        name: name,
        contactName: contactName,
        phone: phone,
        email: email,
        address: address,
        taxId: taxId,
        notes: notes,
      );
      // Stream will emit the updated list automatically.
      _emit();
    } catch (e, st) {
      debugPrint('[SupplierCubit] Error in createSupplier: $e\n$st');
      emit(SupplierError('Failed to save supplier.'));
      _emit();
    }
  }

  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
    bool? isActive,
  }) async {
    final current = state;
    if (current is! SupplierLoaded) return;
    emit(SupplierActionInProgress(current.suppliers));
    try {
      await _repository.updateSupplier(
        id: id,
        name: name,
        contactName: contactName,
        phone: phone,
        email: email,
        address: address,
        taxId: taxId,
        notes: notes,
        isActive: isActive,
      );
      _emit();
    } catch (e, st) {
      debugPrint('[SupplierCubit] Error in updateSupplier: $e\n$st');
      emit(SupplierError('Failed to update supplier.'));
      _emit();
    }
  }

  /// Soft-delete (archive) a supplier — keeps it for historical POs.
  Future<void> archiveSupplier(String id) async {
    final current = state;
    if (current is! SupplierLoaded) return;
    emit(SupplierActionInProgress(current.suppliers));
    try {
      await _repository.deleteSupplier(id);
      _emit();
    } catch (e, st) {
      debugPrint('[SupplierCubit] Error in archiveSupplier: $e\n$st');
      emit(SupplierError('Failed to archive supplier.'));
      _emit();
    }
  }

  @override
  Future<void> close() {
    _supplierSub?.cancel();
    _orderSub?.cancel();
    return super.close();
  }
}
