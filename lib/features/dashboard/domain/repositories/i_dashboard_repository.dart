import 'package:pos/features/dashboard/data/dashboard_data.dart';

abstract class IDashboardRepository {
  Stream<void> watchChanges({required String businessId});

  Future<DashboardData> load({required String businessId, String? branchId});
}
