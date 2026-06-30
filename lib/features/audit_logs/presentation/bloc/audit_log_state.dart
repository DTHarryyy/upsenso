import 'package:equatable/equatable.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';

abstract class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

class AuditLogLoaded extends AuditLogState {
  final List<AuditLog> logs;
  // Full unfiltered list (local window + any server-fetched older pages) —
  // used to build entity/action type chip options so they don't vanish when
  // a filter is active.
  final List<AuditLog> allLogs;
  final String? branchFilter;
  final String? userFilter;
  final String? actionTypeFilter;
  final String? entityTypeFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String searchQuery;

  /// True when there's more to load — either the local window isn't
  /// exhausted yet, or it is but server history beyond it hasn't been
  /// confirmed exhausted.
  final bool hasMore;

  /// True while a "Load more" tap is fetching an older page from the server
  /// (local widening is synchronous, so this only applies to that path).
  final bool isFetchingOlder;

  /// Set when the last server fetch attempt failed — distinguishes "you're
  /// offline" from a generic failure so the UI can show the right state.
  /// Cleared on the next attempt or success.
  final String? serverFetchError;

  const AuditLogLoaded({
    required this.logs,
    required this.allLogs,
    this.branchFilter,
    this.userFilter,
    this.actionTypeFilter,
    this.entityTypeFilter,
    this.dateFrom,
    this.dateTo,
    this.searchQuery = '',
    this.hasMore = false,
    this.isFetchingOlder = false,
    this.serverFetchError,
  });

  bool get hasActiveFilter =>
      branchFilter != null ||
      userFilter != null ||
      actionTypeFilter != null ||
      entityTypeFilter != null ||
      dateFrom != null ||
      dateTo != null ||
      searchQuery.isNotEmpty;

  AuditLogLoaded copyWith({
    List<AuditLog>? logs,
    List<AuditLog>? allLogs,
    Object? branchFilter = _sentinel,
    Object? userFilter = _sentinel,
    Object? actionTypeFilter = _sentinel,
    Object? entityTypeFilter = _sentinel,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    String? searchQuery,
    bool? hasMore,
    bool? isFetchingOlder,
    Object? serverFetchError = _sentinel,
  }) {
    return AuditLogLoaded(
      logs: logs ?? this.logs,
      allLogs: allLogs ?? this.allLogs,
      branchFilter: branchFilter == _sentinel
          ? this.branchFilter
          : branchFilter as String?,
      userFilter: userFilter == _sentinel
          ? this.userFilter
          : userFilter as String?,
      actionTypeFilter: actionTypeFilter == _sentinel
          ? this.actionTypeFilter
          : actionTypeFilter as String?,
      entityTypeFilter: entityTypeFilter == _sentinel
          ? this.entityTypeFilter
          : entityTypeFilter as String?,
      dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      isFetchingOlder: isFetchingOlder ?? this.isFetchingOlder,
      serverFetchError: serverFetchError == _sentinel
          ? this.serverFetchError
          : serverFetchError as String?,
    );
  }

  @override
  List<Object?> get props => [
    logs,
    allLogs,
    branchFilter,
    userFilter,
    actionTypeFilter,
    entityTypeFilter,
    dateFrom,
    dateTo,
    searchQuery,
    hasMore,
    isFetchingOlder,
    serverFetchError,
  ];
}

class AuditLogError extends AuditLogState {
  final String message;

  const AuditLogError(this.message);

  @override
  List<Object?> get props => [message];
}

// Sentinel object to distinguish "not provided" from explicit null in copyWith.
const _sentinel = Object();
