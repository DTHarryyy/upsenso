sealed class EmployeeActivityState {}

class EmployeeActivityLoading extends EmployeeActivityState {}

class EmployeeActivityLoaded extends EmployeeActivityState {
  final DateTime? lastLogin;
  final String? device;
  final String? recentActivityLabel;
  final DateTime? recentActivityTime;

  EmployeeActivityLoaded({
    this.lastLogin,
    this.device,
    this.recentActivityLabel,
    this.recentActivityTime,
  });
}
