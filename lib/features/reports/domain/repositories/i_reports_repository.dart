import 'package:pos/features/reports/data/reports_data.dart';

abstract class IReportsRepository {
  Stream<void> watchChanges({required String businessId});

  Future<ReportsData> load({
    required String businessId,
    String? branchId,
    required ReportPeriod period,
  });
}
