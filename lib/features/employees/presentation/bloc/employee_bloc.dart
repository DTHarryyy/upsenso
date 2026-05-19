import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/errors/employee_errors.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final IEmployeesRepository _repository;

  StreamSubscription<List<Employee>>? _watcher;
  String? _businessId;

  // Local filter state
  String _searchQuery = '';
  EmployeeRole? _roleFilter;
  EmployeeStatus? _statusFilter;
  String? _branchFilter;

  EmployeeBloc(this._repository) : super(const EmployeeInitial()) {
    on<LoadEmployees>(_onLoad);
    on<EmployeesUpdated>(_onUpdated);
    on<AddEmployee>(_onAdd);
    on<UpdateEmployee>(_onUpdate);
    on<ArchiveEmployee>(_onArchive);
    on<SuspendEmployee>(_onSuspend);
    on<ReactivateEmployee>(_onReactivate);
    on<SearchEmployees>(_onSearch);
    on<FilterEmployees>(_onFilter);
    on<ClearEmployeeFilters>(_onClearFilters);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(LoadEmployees event, Emitter<EmployeeState> emit) async {
    _businessId = event.businessId;
    await _watcher?.cancel();
    emit(const EmployeeLoading());

    _watcher = _repository
        .watchEmployees(event.businessId)
        .listen(
          (employees) {
            if (!isClosed) add(EmployeesUpdated(employees));
          },
          onError: (e) {
            if (!isClosed) emit(EmployeeError(AppErrorMapper.message(e)));
          },
        );
  }

  void _onUpdated(EmployeesUpdated event, Emitter<EmployeeState> emit) {
    final filtered = _filter(event.employees);
    final current = state;

    if (current is EmployeeLoaded) {
      emit(
        current.copyWith(
          allEmployees: event.employees,
          displayEmployees: filtered,
        ),
      );
    } else if (current is EmployeeOperationInProgress) {
      emit(
        current.previous.copyWith(
          allEmployees: event.employees,
          displayEmployees: filtered,
        ),
      );
    } else {
      emit(
        EmployeeLoaded(
          allEmployees: event.employees,
          displayEmployees: filtered,
          searchQuery: _searchQuery,
          roleFilter: _roleFilter,
          statusFilter: _statusFilter,
          branchFilter: _branchFilter,
        ),
      );
    }
  }

  Future<void> _onAdd(AddEmployee event, Emitter<EmployeeState> emit) async {
    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.addEmployee(
        businessId: _businessId ?? '',
        branchId: event.branchId,
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        role: event.role,
        hiredAt: event.hiredAt,
        password: event.password,
        profileImageUrl: event.profileImageUrl,
      );
      // Stream watcher will re-emit loaded state automatically.
    } on EmployeeDuplicateException catch (e) {
      emit(EmployeeValidationFailure(fieldErrors: e.fieldErrors, loaded: current));
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.updateEmployee(
        id: event.id,
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        branchId: event.branchId,
        role: event.role,
        profileImageUrl: event.profileImageUrl,
      );
    } on EmployeeDuplicateException catch (e) {
      emit(EmployeeValidationFailure(fieldErrors: e.fieldErrors, loaded: current));
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  Future<void> _onArchive(
    ArchiveEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.archiveEmployee(event.id);
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  Future<void> _onSuspend(
    SuspendEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.suspendEmployee(event.id);
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  Future<void> _onReactivate(
    ReactivateEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.reactivateEmployee(event.id);
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  void _onSearch(SearchEmployees event, Emitter<EmployeeState> emit) {
    _searchQuery = event.query;
    _rebuildDisplay(emit);
  }

  void _onFilter(FilterEmployees event, Emitter<EmployeeState> emit) {
    _roleFilter = event.roleFilter;
    _statusFilter = event.statusFilter;
    _branchFilter = event.branchFilter;
    _rebuildDisplay(emit);
  }

  void _onClearFilters(
    ClearEmployeeFilters event,
    Emitter<EmployeeState> emit,
  ) {
    _searchQuery = '';
    _roleFilter = null;
    _statusFilter = null;
    _branchFilter = null;
    _rebuildDisplay(emit);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  EmployeeLoaded? get _currentLoaded {
    final s = state;
    if (s is EmployeeLoaded) return s;
    if (s is EmployeeOperationInProgress) return s.previous;
    return null;
  }

  void _rebuildDisplay(Emitter<EmployeeState> emit) {
    final current = _currentLoaded;
    if (current == null) return;
    final filtered = _filter(current.allEmployees);
    emit(
      current.copyWith(
        displayEmployees: filtered,
        searchQuery: _searchQuery,
        roleFilter: _roleFilter,
        statusFilter: _statusFilter,
        branchFilter: _branchFilter,
      ),
    );
  }

  List<Employee> _filter(List<Employee> employees) {
    return employees.where((e) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        if (!e.fullName.toLowerCase().contains(q) &&
            !e.email.toLowerCase().contains(q) &&
            !e.employeeCode.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_roleFilter != null && e.role != _roleFilter) return false;
      if (_statusFilter != null && e.status != _statusFilter) return false;
      if (_branchFilter != null && e.branchId != _branchFilter) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    return super.close();
  }
}
