import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart';

class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  final IAuditLogRepository _repository;

  StreamSubscription<List<AuditLog>>? _watcher;
  String? _businessId;

  String? _branchFilter;
  String? _userFilter;
  String? _actionTypeFilter;
  String? _entityTypeFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _searchQuery = '';

  AuditLogBloc({required IAuditLogRepository repository})
    : _repository = repository,
      super(const AuditLogInitial()) {
    on<LoadAuditLogs>(_onLoad);
    on<RefreshAuditLogs>(_onRefresh);
    on<FilterAuditLogsByBranch>(_onFilterBranch);
    on<FilterAuditLogsByUser>(_onFilterUser);
    on<FilterAuditLogsByActionType>(_onFilterActionType);
    on<FilterAuditLogsByEntityType>(_onFilterEntityType);
    on<FilterAuditLogsByDateRange>(_onFilterDateRange);
    on<ClearAuditLogFilters>(_onClearFilters);
    on<SearchAuditLogs>(_onSearch);
  }

  Future<void> _onLoad(LoadAuditLogs event, Emitter<AuditLogState> emit) async {
    _businessId = event.businessId;
    _branchFilter = null;
    _userFilter = null;
    _actionTypeFilter = null;
    _entityTypeFilter = null;
    _dateFrom = null;
    _dateTo = null;
    _searchQuery = '';

    emit(const AuditLogLoading());
    await _watcher?.cancel();
    await _subscribeWithFilters(emit);
  }

  Future<void> _onRefresh(
    RefreshAuditLogs event,
    Emitter<AuditLogState> emit,
  ) async {
    if (_businessId == null) return;
    await _watcher?.cancel();
    await _subscribeWithFilters(emit);
  }

  Future<void> _onFilterBranch(
    FilterAuditLogsByBranch event,
    Emitter<AuditLogState> emit,
  ) async {
    _branchFilter = event.branchId;
    await _resubscribe(emit);
  }

  Future<void> _onFilterUser(
    FilterAuditLogsByUser event,
    Emitter<AuditLogState> emit,
  ) async {
    _userFilter = event.userId;
    await _resubscribe(emit);
  }

  Future<void> _onFilterActionType(
    FilterAuditLogsByActionType event,
    Emitter<AuditLogState> emit,
  ) async {
    _actionTypeFilter = event.actionType;
    await _resubscribe(emit);
  }

  Future<void> _onFilterEntityType(
    FilterAuditLogsByEntityType event,
    Emitter<AuditLogState> emit,
  ) async {
    _entityTypeFilter = event.entityType;
    await _resubscribe(emit);
  }

  Future<void> _onFilterDateRange(
    FilterAuditLogsByDateRange event,
    Emitter<AuditLogState> emit,
  ) async {
    _dateFrom = event.from;
    _dateTo = event.to;
    await _resubscribe(emit);
  }

  Future<void> _onClearFilters(
    ClearAuditLogFilters event,
    Emitter<AuditLogState> emit,
  ) async {
    _branchFilter = null;
    _userFilter = null;
    _actionTypeFilter = null;
    _entityTypeFilter = null;
    _dateFrom = null;
    _dateTo = null;
    _searchQuery = '';
    await _resubscribe(emit);
  }

  void _onSearch(SearchAuditLogs event, Emitter<AuditLogState> emit) {
    _searchQuery = event.query.trim().toLowerCase();
    final current = state;
    if (current is AuditLogLoaded) {
      emit(current.copyWith(searchQuery: _searchQuery));
    }
  }

  Future<void> _resubscribe(Emitter<AuditLogState> emit) async {
    if (_businessId == null) return;
    await _watcher?.cancel();
    await _subscribeWithFilters(emit);
  }

  Future<void> _subscribeWithFilters(Emitter<AuditLogState> emit) async {
    final businessId = _businessId!;
    await emit.forEach<List<AuditLog>>(
      _repository.watchLogs(
        businessId: businessId,
        branchId: _branchFilter,
        userId: _userFilter,
        actionType: _actionTypeFilter,
      ),
      onData: (logs) {
        var filtered = _applyDateFilter(logs);
        if (_entityTypeFilter != null) {
          filtered = filtered
              .where(
                (l) =>
                    l.entityType.toLowerCase() ==
                    _entityTypeFilter!.toLowerCase(),
              )
              .toList();
        }
        return AuditLogLoaded(
          logs: filtered,
          branchFilter: _branchFilter,
          userFilter: _userFilter,
          actionTypeFilter: _actionTypeFilter,
          entityTypeFilter: _entityTypeFilter,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          searchQuery: _searchQuery,
        );
      },
      onError: (e, _) => AuditLogError(e.toString()),
    );
  }

  List<AuditLog> _applyDateFilter(List<AuditLog> logs) {
    if (_dateFrom == null && _dateTo == null) return logs;
    return logs.where((l) {
      if (_dateFrom != null && l.createdAt.isBefore(_dateFrom!)) return false;
      if (_dateTo != null) {
        // Include the full end date — compare against 23:59:59.999
        final endOfDay = DateTime(
          _dateTo!.year,
          _dateTo!.month,
          _dateTo!.day,
          23,
          59,
          59,
          999,
        );
        if (l.createdAt.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    return super.close();
  }
}
