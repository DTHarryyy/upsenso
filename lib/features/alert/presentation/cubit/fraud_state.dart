import 'package:equatable/equatable.dart';
import 'package:pos/features/alert/data/alert_model.dart';

abstract class FraudState extends Equatable {
  const FraudState();

  @override
  List<Object?> get props => [];
}

class FraudLoading extends FraudState {
  const FraudLoading();
}

class FraudLoaded extends FraudState {
  /// Every alert in scope, unfiltered — the status chip counts read from this
  /// so they keep showing the real totals while a filter narrows the list.
  final List<FraudAlert> alerts;

  /// null = "All".
  final AlertStatus? statusFilter;
  final AlertSeverity? severityFilter;
  final String query;

  FraudLoaded({
    required this.alerts,
    this.statusFilter,
    this.severityFilter,
    this.query = '',
  });

  /// Computed once per state, not per rebuild — the page reads it twice
  /// (empty check, then the list builder).
  late final List<FraudAlert> visibleAlerts = alerts
      .where(_matches)
      .toList(growable: false);

  bool get isFiltered =>
      statusFilter != null || severityFilter != null || query.isNotEmpty;

  /// Per-status totals for the filter chip badges.
  Map<AlertStatus, int> get statusCounts {
    final counts = <AlertStatus, int>{};
    for (final alert in alerts) {
      counts[alert.status] = (counts[alert.status] ?? 0) + 1;
    }
    return counts;
  }

  bool _matches(FraudAlert alert) =>
      _matchesStatus(alert) && _matchesSeverity(alert) && _matchesQuery(alert);

  // "Dismissed" deliberately folds in false positives: to an operator both
  // mean "reviewed, no action", and splitting them would strand alerts in a
  // bucket the filter bar never offers.
  bool _matchesStatus(FraudAlert alert) {
    if (statusFilter == null) return true;
    if (statusFilter == AlertStatus.dismissed) {
      return alert.status == AlertStatus.dismissed ||
          alert.status == AlertStatus.falsePositive;
    }
    return alert.status == statusFilter;
  }

  bool _matchesSeverity(FraudAlert alert) =>
      severityFilter == null || alert.severity == severityFilter;

  bool _matchesQuery(FraudAlert alert) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return alert.title.toLowerCase().contains(q) ||
        alert.description.toLowerCase().contains(q) ||
        alert.author.toLowerCase().contains(q) ||
        alert.store.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [alerts, statusFilter, severityFilter, query];
}

class FraudError extends FraudState {
  final String message;

  const FraudError(this.message);

  @override
  List<Object?> get props => [message];
}
