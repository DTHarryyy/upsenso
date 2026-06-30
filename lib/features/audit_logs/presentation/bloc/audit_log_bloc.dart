import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/sync/audit_log_retention.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart';

class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  final IAuditLogRepository _repository;

  static const _pageSize = 200;

  StreamSubscription<List<AuditLog>>? _watcher;
  String? _businessId;

  String? _branchFilter;
  String? _userFilter;
  String? _actionTypeFilter;
  String? _entityTypeFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _searchQuery = '';

  // Local query window — grows by one page per LoadMoreAuditLogs. Drift reads
  // are cheap (on-device, already-synced data), so widening the limit and
  // letting the reactive watch query re-run is simpler than a separate
  // keyset cursor + manual page-merge for a live stream.
  int _limit = _pageSize;

  // True when the last LOCAL fetch came back with at least _limit rows
  // (widening further might surface more). Once false, the local window —
  // bounded to auditLogLocalWindowDays — is genuinely exhausted, and
  // "Load more" switches to fetching older pages from the server instead.
  bool _localHasMore = true;

  // Server-fetched rows older than the local window, accumulated for this
  // session only (never persisted to Drift — kept simple, re-fetched if the
  // page is reopened, rather than growing the local DB on every lookup).
  List<AuditLog> _serverLogs = [];
  bool _serverExhausted = false;
  bool _isFetchingOlder = false;
  String? _serverFetchError;

  AuditLogBloc({required IAuditLogRepository repository})
    : _repository = repository,
      super(const AuditLogInitial()) {
    on<LoadAuditLogs>(_onLoad);
    on<RefreshAuditLogs>(_onRefresh);
    on<LoadMoreAuditLogs>(_onLoadMore);
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
    _resetPaging();

    emit(const AuditLogLoading());
    await _watcher?.cancel();
    await _subscribeWithFilters(emit);
  }

  void _resetPaging() {
    _limit = _pageSize;
    _localHasMore = true;
    _serverLogs = [];
    _serverExhausted = false;
    _isFetchingOlder = false;
    _serverFetchError = null;
  }

  Future<void> _onLoadMore(
    LoadMoreAuditLogs event,
    Emitter<AuditLogState> emit,
  ) async {
    final current = state;
    if (current is! AuditLogLoaded || !current.hasMore || _isFetchingOlder) {
      return;
    }

    if (_localHasMore) {
      _limit += _pageSize;
      await _watcher?.cancel();
      await _subscribeWithFilters(emit);
      return;
    }

    // Local window is exhausted — the next page lives only on the server.
    await _fetchOlderFromServer(emit, before: _oldestVisibleCreatedAt(current));
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

    // An explicit ask for a date before the local window can't be answered
    // from Drift — go straight to the server for that specific range.
    final from = _dateFrom;
    if (from != null && from.isBefore(_windowStart())) {
      final endOfTo = _dateTo == null ? null : _endOfDay(_dateTo!);
      await _fetchOlderFromServer(
        emit,
        from: from,
        before: endOfTo?.add(const Duration(milliseconds: 1)),
        isExplicitRangeRequest: true,
      );
    }
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
    // A filter change is a fresh view — start back at page one and drop any
    // server pages fetched for the previous filter combination.
    _resetPaging();
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
        limit: _limit,
        // Don't push actionType into the DB query — filter in-memory so
        // allLogs always has the full set for building chip/dropdown options.
      ),
      onData: (rawLocalLogs) {
        // A full page back from Drift means widening _limit further might
        // surface more; fewer than asked means the local window is exhausted.
        _localHasMore = rawLocalLogs.length >= _limit;

        final merged = _mergeWithServerLogs(rawLocalLogs);
        var filtered = _applyDateFilter(merged);
        if (_actionTypeFilter != null) {
          filtered = filtered
              .where((l) => l.actionType.value == _actionTypeFilter)
              .toList();
        }
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
          allLogs: merged,
          hasMore: _localHasMore || !_serverExhausted,
          isFetchingOlder: _isFetchingOlder,
          serverFetchError: _serverFetchError,
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

  /// Combines the local raw stream with any server-fetched older pages,
  /// deduped by id (defensive — the two sources shouldn't overlap since
  /// server fetches always start strictly before the oldest known row, but
  /// the local window's edge can shift mid-session as pruning runs) and
  /// sorted newest-first to match the rest of the UI.
  List<AuditLog> _mergeWithServerLogs(List<AuditLog> rawLocalLogs) {
    if (_serverLogs.isEmpty) return rawLocalLogs;
    final byId = <String, AuditLog>{};
    for (final l in rawLocalLogs) {
      byId[l.id] = l;
    }
    for (final l in _serverLogs) {
      byId.putIfAbsent(l.id, () => l);
    }
    final combined = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  DateTime _oldestVisibleCreatedAt(AuditLogLoaded state) {
    if (state.allLogs.isEmpty) return DateTime.now();
    return state.allLogs
        .map((l) => l.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _windowStart() =>
      DateTime.now().subtract(const Duration(days: auditLogLocalWindowDays));

  /// Fetches one older page from the server and folds it into [_serverLogs],
  /// then re-subscribes locally so the merge + filters recompute.
  ///
  /// Two call shapes:
  /// - Continuation (load-more past the exhausted local window): pass
  ///   [before] only — pages strictly older than what's already visible, and
  ///   an empty result means server history is genuinely exhausted.
  /// - Explicit range (a date filter older than the window): pass [from]
  ///   ([isExplicitRangeRequest]: true) — an empty result here just means
  ///   nothing happened in that range, not that history is exhausted.
  Future<void> _fetchOlderFromServer(
    Emitter<AuditLogState> emit, {
    DateTime? from,
    DateTime? before,
    bool isExplicitRangeRequest = false,
  }) async {
    final current = state;
    if (current is! AuditLogLoaded || _businessId == null) return;

    _isFetchingOlder = true;
    _serverFetchError = null;
    emit(current.copyWith(isFetchingOlder: true, serverFetchError: null));

    try {
      final older = await _repository.getOlderFromServer(
        businessId: _businessId!,
        from: from ?? DateTime.fromMillisecondsSinceEpoch(0),
        before: before,
        limit: _pageSize,
      );
      if (isExplicitRangeRequest) {
        _serverLogs = [..._serverLogs, ...older];
      } else if (older.isEmpty) {
        _serverExhausted = true;
      } else {
        _serverLogs = [..._serverLogs, ...older];
      }
    } catch (e) {
      _serverFetchError = e is AuditLogOfflineException
          ? "You're offline — connect to load older entries."
          : 'Could not load older entries. Try again.';
    } finally {
      _isFetchingOlder = false;
    }

    await _watcher?.cancel();
    await _subscribeWithFilters(emit);
  }

  List<AuditLog> _applyDateFilter(List<AuditLog> logs) {
    if (_dateFrom == null && _dateTo == null) return logs;
    return logs.where((l) {
      if (_dateFrom != null && l.createdAt.isBefore(_dateFrom!)) return false;
      if (_dateTo != null && l.createdAt.isAfter(_endOfDay(_dateTo!))) {
        return false;
      }
      return true;
    }).toList();
  }

  // Include the full end date — compare against 23:59:59.999.
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  @override
  Future<void> close() {
    _watcher?.cancel();
    return super.close();
  }
}
