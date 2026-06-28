import 'package:drift/drift.dart';

/// Local read cache of refund_settings — pull-only, no local-edit/push path.
/// The admin write screen (RefundApprovalSettingsPage) writes straight to
/// Supabase since it's an online-only config surface; this table just lets
/// the refund sheet read the threshold instantly and offline at refund time
/// instead of blocking on a network call. A row only ever exists because a
/// pull wrote it, so syncStatus here is always "synced" — kept anyway per
/// the project's every-synced-entity-has-a-sync_status rule.
@DataClassName('RefundSettingsRow')
class RefundSettingsTable extends Table {
  @override
  String get tableName => 'refund_settings';

  TextColumn get id => text()(); // UUID = businessId (1:1)
  TextColumn get businessId => text()();
  BoolColumn get requireApproval =>
      boolean().withDefault(const Constant(false))();
  RealColumn get approvalThreshold =>
      real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Always 3=synced for this table — see class doc.
  IntColumn get syncStatus => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}
