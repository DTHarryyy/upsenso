import 'package:equatable/equatable.dart';
import 'package:pos/features/reports/data/reports_data.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final ReportsData data;
  const ReportsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);
  @override
  List<Object?> get props => [message];
}
