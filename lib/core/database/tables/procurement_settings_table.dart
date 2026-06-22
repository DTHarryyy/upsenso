import 'package:drift/drift.dart';

/// Per-business procurement settings (local mirror of Supabase
/// `procurement_settings`). One row per business.
///
/// `approvalThreshold` null = unset → approvers may self-approve any amount
/// (startup-friendly default). When set, POs above it require a different
/// approver (no self-approve). See ApprovalPolicy.
class ProcurementSettingsTable extends Table {
  @override
  String get tableName => 'procurement_settings';

  TextColumn get businessId => text()();
  RealColumn get approvalThreshold => real().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  // 0=pendingUpload,1=pendingUpdate,2=pendingDelete,3=synced,4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {businessId};
}
