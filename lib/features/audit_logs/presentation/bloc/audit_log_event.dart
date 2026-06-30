import 'package:equatable/equatable.dart';

abstract class AuditLogEvent extends Equatable {
  const AuditLogEvent();

  @override
  List<Object?> get props => [];
}

class LoadAuditLogs extends AuditLogEvent {
  final String businessId;

  const LoadAuditLogs({required this.businessId});

  @override
  List<Object?> get props => [businessId];
}

class RefreshAuditLogs extends AuditLogEvent {
  const RefreshAuditLogs();
}

/// Widens the local query window by one page. No-op when the current state
/// has nothing more to load.
class LoadMoreAuditLogs extends AuditLogEvent {
  const LoadMoreAuditLogs();
}

class FilterAuditLogsByBranch extends AuditLogEvent {
  final String? branchId;

  const FilterAuditLogsByBranch({this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class FilterAuditLogsByUser extends AuditLogEvent {
  final String? userId;

  const FilterAuditLogsByUser({this.userId});

  @override
  List<Object?> get props => [userId];
}

class FilterAuditLogsByActionType extends AuditLogEvent {
  final String? actionType;

  const FilterAuditLogsByActionType({this.actionType});

  @override
  List<Object?> get props => [actionType];
}

class FilterAuditLogsByDateRange extends AuditLogEvent {
  final DateTime? from;
  final DateTime? to;

  const FilterAuditLogsByDateRange({this.from, this.to});

  @override
  List<Object?> get props => [from, to];
}

class ClearAuditLogFilters extends AuditLogEvent {
  const ClearAuditLogFilters();
}

class SearchAuditLogs extends AuditLogEvent {
  final String query;
  const SearchAuditLogs({required this.query});
  @override
  List<Object?> get props => [query];
}

class FilterAuditLogsByEntityType extends AuditLogEvent {
  final String? entityType;
  const FilterAuditLogsByEntityType({this.entityType});
  @override
  List<Object?> get props => [entityType];
}
