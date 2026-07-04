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
  final List<FraudAlert> alerts;

  const FraudLoaded({required this.alerts});

  @override
  List<Object?> get props => [alerts];
}

class FraudError extends FraudState {
  final String message;

  const FraudError(this.message);

  @override
  List<Object?> get props => [message];
}
