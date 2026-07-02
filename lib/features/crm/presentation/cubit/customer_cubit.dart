import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';
import 'package:pos/features/crm/presentation/cubit/customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final ICustomerRepository _repository;
  final PermissionService _permissions;
  final String businessId;

  StreamSubscription? _customerSub;

  List<Customer> _customers = [];
  bool _ready = false;

  // Triage state held on the cubit so it survives action-in-progress emissions.
  String? _search;
  CustomerFilter _filter = CustomerFilter.all;
  CustomerSort _sort = CustomerSort.nameAsc;

  CustomerCubit({
    required ICustomerRepository repository,
    required PermissionService permissions,
    required this.businessId,
  })  : _repository = repository,
        _permissions = permissions,
        super(CustomerInitial());

  // Defense-in-depth: managing customers is gated by crm.manage in the UI, so
  // the cubit re-checks it here too — a hidden FAB isn't access control.
  Future<bool> _allowedManage({String? entityId}) async {
    final result = await _permissions.guard(
      AppPermission.manageCustomers,
      entityType: 'customer',
      entityId: entityId,
    );
    if (result.granted) return true;
    emit(CustomerError(
      result.deniedReason ?? 'You do not have permission for this.',
    ));
    _emit();
    return false;
  }

  // Case-insensitive name clash against the active directory. [excludeId] lets
  // an edit keep its own name.
  bool _isDuplicateName(String name, {String? excludeId}) {
    final n = name.trim().toLowerCase();
    return _customers.any(
      (c) => c.id != excludeId && c.name.trim().toLowerCase() == n,
    );
  }

  void watch() {
    emit(CustomerLoading());
    _ready = false;
    _customerSub?.cancel();
    _customerSub = _repository.watchCustomers(businessId).listen(
      (customers) {
        _customers = customers;
        _ready = true;
        _emit();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[CustomerCubit] watch error: $e\n$st');
        emit(CustomerError('Failed to load customers.'));
      },
    );
  }

  void _emit() {
    if (!_ready || isClosed) return;
    emit(
      CustomerLoaded(
        customers: _customers,
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

  void setFilter(CustomerFilter filter) {
    _filter = filter;
    _emit();
  }

  void setSort(CustomerSort sort) {
    _sort = sort;
    _emit();
  }

  /// Returns true when the customer was created; false on permission denial, a
  /// duplicate name, or a write failure (the form keeps itself open then).
  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final current = state;
    if (current is! CustomerLoaded) return false;
    if (!await _allowedManage()) return false;
    if (_isDuplicateName(name)) {
      emit(CustomerError('A customer named "${name.trim()}" already exists.'));
      _emit();
      return false;
    }
    emit(CustomerActionInProgress(current.customers));
    try {
      await _repository.createCustomer(
        businessId: businessId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      _emit();
      return true;
    } catch (e, st) {
      debugPrint('[CustomerCubit] Error in createCustomer: $e\n$st');
      emit(CustomerError('Failed to save customer.'));
      _emit();
      return false;
    }
  }

  /// Returns true when the customer was updated; false on permission denial, a
  /// duplicate name, or a write failure.
  Future<bool> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    final current = state;
    if (current is! CustomerLoaded) return false;
    if (!await _allowedManage(entityId: id)) return false;
    if (_isDuplicateName(name, excludeId: id)) {
      emit(CustomerError('A customer named "${name.trim()}" already exists.'));
      _emit();
      return false;
    }
    emit(CustomerActionInProgress(current.customers));
    try {
      await _repository.updateCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        isActive: isActive,
      );
      _emit();
      return true;
    } catch (e, st) {
      debugPrint('[CustomerCubit] Error in updateCustomer: $e\n$st');
      emit(CustomerError('Failed to update customer.'));
      _emit();
      return false;
    }
  }

  /// Soft-delete (archive) a customer — keeps it for historical transactions.
  Future<void> archiveCustomer(String id) async {
    final current = state;
    if (current is! CustomerLoaded) return;
    if (!await _allowedManage(entityId: id)) return;
    emit(CustomerActionInProgress(current.customers));
    try {
      await _repository.archiveCustomer(id);
      _emit();
    } catch (e, st) {
      debugPrint('[CustomerCubit] Error in archiveCustomer: $e\n$st');
      emit(CustomerError('Failed to archive customer.'));
      _emit();
    }
  }

  @override
  Future<void> close() {
    _customerSub?.cancel();
    return super.close();
  }
}
