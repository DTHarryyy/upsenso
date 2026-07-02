import 'package:equatable/equatable.dart';
import 'package:pos/features/insights/domain/insight.dart';

abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  final List<Insight> insights;

  const InsightsLoaded(this.insights);

  /// True when there is genuinely nothing to show (no data, or the user lacks
  /// `insights.view`) — the card hides itself in this case.
  bool get isEmpty => insights.isEmpty;

  @override
  List<Object?> get props => [insights];
}

class InsightsError extends InsightsState {
  const InsightsError();
}
