import 'package:pos/features/dashboard/data/dashboard_data.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  const DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}
