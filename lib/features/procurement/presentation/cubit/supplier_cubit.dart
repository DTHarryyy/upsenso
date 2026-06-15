import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final IProcurementRepository _repository;
  final PermissionService _permissions;
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
    required PermissionService permissions,
    required this.businessId,
  }) : _repository = repository,
       _permissions = permissions,
       super(SupplierInitial());

  // Defense-in-depth: managing suppliers is gated by suppliers.manage in the
  // UI, so the cubit re-checks it here too — a hidden FAB isn't access control.
  Future<bool> _allowedManage({String? entityId}) async {
    final result = await _permissions.guard(
      AppPermission.manageSuppliers,
      entityType: 'supplier',
      entityId: entityId,
    );
    if (result.granted) return true;
    emit(SupplierError(
      result.deniedReason ?? 'You do not have permission for this.',
    ));
    _emit();
    return false;
  }

  // Case-insensitive name clash against the active directory. [excludeId] lets
  // an edit keep its own name. The form validates this too for inline feedback;
  // this is the authoritative guard against duplicates slipping through.
  bool _isDuplicateName(String name, {String? excludeId}) {
    final n = name.trim().toLowerCase();
    return _suppliers.any(
      (s) => s.id != excludeId && s.name.trim().toLowerCase() == n,
    );
  }

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

  /// Returns true when the supplier was created; false on permission denial,
  /// a duplicate name, or a write failure (the form keeps itself open then).
  Future<bool> createSupplier({
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
  }) async {
    final current = state;
    if (current is! SupplierLoaded) return false;
    if (!await _allowedManage()) return false;
    if (_isDuplicateName(name)) {
      emit(SupplierError('A supplier named "${name.trim()}" already exists.'));
      _emit();
      return false;
    }
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
      return true;
    } catch (e, st) {
      debugPrint('[SupplierCubit] Error in createSupplier: $e\n$st');
      emit(SupplierError('Failed to save supplier.'));
      _emit();
      return false;
    }
  }

  /// Returns true when the supplier was updated; false on permission denial,
  /// a duplicate name, or a write failure.
  Future<bool> updateSupplier({
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
    if (current is! SupplierLoaded) return false;
    if (!await _allowedManage(entityId: id)) return false;
    if (_isDuplicateName(name, excludeId: id)) {
      emit(SupplierError('A supplier named "${name.trim()}" already exists.'));
      _emit();
      return false;
    }
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
      return true;
    } catch (e, st) {
      debugPrint('[SupplierCubit] Error in updateSupplier: $e\n$st');
      emit(SupplierError('Failed to update supplier.'));
      _emit();
      return false;
    }
  }

  /// Soft-delete (archive) a supplier — keeps it for historical POs.
  Future<void> archiveSupplier(String id) async {
    final current = state;
    if (current is! SupplierLoaded) return;
    if (!await _allowedManage(entityId: id)) return;
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
