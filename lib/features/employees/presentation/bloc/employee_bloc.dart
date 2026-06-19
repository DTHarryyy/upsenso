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

  String _searchQuery = '';
  String? _roleFilter;
  bool? _isActiveFilter;
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
    on<SetRoleFilter>(_onSetRole);
    on<SetStatusFilter>(_onSetStatus);
    on<SetBranchFilter>(_onSetBranch);
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
    final base = _currentLoaded;

    if (base != null) {
      emit(
        base.copyWith(
          allEmployees: event.employees,
          displayEmployees: filtered,
          searchQuery: _searchQuery,
          roleFilter: _roleFilter,
          isActiveFilter: _isActiveFilter,
          branchFilter: _branchFilter,
        ),
      );
    } else {
      emit(
        EmployeeLoaded(
          allEmployees: event.employees,
          displayEmployees: filtered,
          searchQuery: _searchQuery,
          roleFilter: _roleFilter,
          isActiveFilter: _isActiveFilter,
          branchFilter: _branchFilter,
        ),
      );
    }
  }

  // True when the actor is allowed to assign [roleName]. An empty/absent
  // allow-list means no restriction (e.g. Business Owner managing everyone).
  bool _roleAllowed(List<String>? allowed, String? roleName) {
    if (allowed == null || allowed.isEmpty) return true;
    final target = roleName?.toLowerCase().trim();
    return allowed.any((r) => r.toLowerCase().trim() == target);
  }

  bool _isOwnerRole(String? roleName) {
    switch (roleName?.toLowerCase().trim()) {
      case 'owner':
      case 'business owner':
      case 'super admin':
      case 'superadmin':
        return true;
      default:
        return false;
    }
  }

  Future<void> _onAdd(AddEmployee event, Emitter<EmployeeState> emit) async {
    final current = _currentLoaded;

    if (!_roleAllowed(event.allowedRoleNames, event.roleName)) {
      emit(EmployeeError(
        'You are not allowed to assign the ${event.roleName ?? 'selected'} role.',
      ));
      return;
    }

    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.addEmployee(
        businessId: _businessId ?? '',
        branchId: event.branchId,
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        roleId: event.roleId,
        roleName: event.roleName,
      );
      // Use the latest loaded state so stream updates that arrived during the
      // async add (i.e. the new employee row) are not overwritten by the
      // stale snapshot captured before the operation started.
      final latest = _currentLoaded ??
          current ??
          const EmployeeLoaded(allEmployees: [], displayEmployees: []);
      emit(EmployeeOperationSuccess(
        message: 'Employee added',
        loaded: latest,
      ));
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

    if (!_roleAllowed(event.allowedRoleNames, event.roleName)) {
      emit(EmployeeError(
        'You are not allowed to assign the ${event.roleName ?? 'selected'} role.',
      ));
      return;
    }

    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.updateEmployee(
        id: event.id,
        fullName: event.fullName,
        roleId: event.roleId,
        roleName: event.roleName,
        branchId: event.branchId,
        isActive: event.isActive,
      );
      final latest = _currentLoaded ?? current;
      if (latest != null) {
        emit(EmployeeOperationSuccess(message: 'Employee updated', loaded: latest));
      }
    } on EmployeeDuplicateException catch (e) {
      emit(EmployeeValidationFailure(fieldErrors: e.fieldErrors, loaded: current));
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  // Looks up the target in the current snapshot so we can block protected
  // (owner / super admin) accounts before any remote/DB call is attempted.
  bool _targetIsProtected(String id) {
    final loaded = _currentLoaded;
    if (loaded == null) return false;
    for (final e in loaded.allEmployees) {
      if (e.id == id) return _isOwnerRole(e.roleName);
    }
    return false;
  }

  Future<void> _onArchive(
    ArchiveEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    if (_targetIsProtected(event.id)) {
      emit(const EmployeeError(
        'Owners and Super Admins cannot be removed.',
      ));
      return;
    }

    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.archiveEmployee(event.id);
    } on EmployeeProtectedException catch (e) {
      emit(EmployeeError(e.message));
    } catch (e) {
      emit(EmployeeError(AppErrorMapper.message(e)));
    }
  }

  Future<void> _onSuspend(
    SuspendEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    if (_targetIsProtected(event.id)) {
      emit(const EmployeeError(
        'Owners and Super Admins cannot be suspended.',
      ));
      return;
    }

    final current = _currentLoaded;
    if (current != null) emit(EmployeeOperationInProgress(current));

    try {
      await _repository.suspendEmployee(event.id);
    } on EmployeeProtectedException catch (e) {
      emit(EmployeeError(e.message));
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
    _isActiveFilter = event.isActiveFilter;
    _branchFilter = event.branchFilter;
    _rebuildDisplay(emit);
  }

  void _onSetRole(SetRoleFilter event, Emitter<EmployeeState> emit) {
    _roleFilter = event.role;
    _rebuildDisplay(emit);
  }

  void _onSetStatus(SetStatusFilter event, Emitter<EmployeeState> emit) {
    _isActiveFilter = event.isActive;
    _rebuildDisplay(emit);
  }

  void _onSetBranch(SetBranchFilter event, Emitter<EmployeeState> emit) {
    _branchFilter = event.branchId;
    _rebuildDisplay(emit);
  }

  void _onClearFilters(
    ClearEmployeeFilters event,
    Emitter<EmployeeState> emit,
  ) {
    _searchQuery = '';
    _roleFilter = null;
    _isActiveFilter = null;
    _branchFilter = null;
    _rebuildDisplay(emit);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  EmployeeLoaded? get _currentLoaded {
    final s = state;
    if (s is EmployeeLoaded) return s;
    if (s is EmployeeOperationInProgress) return s.previous;
    if (s is EmployeeOperationSuccess) return s.loaded;
    if (s is EmployeeValidationFailure) return s.loaded;
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
        isActiveFilter: _isActiveFilter,
        branchFilter: _branchFilter,
      ),
    );
  }

  List<Employee> _filter(List<Employee> employees) {
    return employees.where((e) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final matchesName = e.fullName.toLowerCase().contains(q);
        final matchesEmail = e.email?.toLowerCase().contains(q) ?? false;
        if (!matchesName && !matchesEmail) return false;
      }
      if (_roleFilter != null &&
          (e.roleName?.toLowerCase() != _roleFilter!.toLowerCase())) {
        return false;
      }
      if (_isActiveFilter != null && e.isActive != _isActiveFilter) return false;
      if (_branchFilter != null && e.branchId != _branchFilter) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    return super.close();
  }
}
