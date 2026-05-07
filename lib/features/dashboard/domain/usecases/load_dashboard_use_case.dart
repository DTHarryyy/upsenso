import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/domain/repositories/i_dashboard_repository.dart';

class LoadDashboardUseCase {
  final IDashboardRepository _repository;
  const LoadDashboardUseCase(this._repository);

  Future<DashboardData> call({required String businessId, String? branchId}) =>
      _repository.load(businessId: businessId, branchId: branchId);
}
