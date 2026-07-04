import 'package:drift/drift.dart';

/// Flags raised by the on-device fraud detection engine.
///
/// Append-mostly: a flag's forensic fields (rule, severity, evidence,
/// subject, dedupe key) never change after insert — the server enforces this
/// with a freeze trigger — so triage updates may only touch status /
/// resolution fields. Deterministic [dedupeKey] makes re-sweeps and other
/// devices converge on one row per incident instead of duplicating it.
@DataClassName('FraudFlagRow')
class FraudFlagsTable extends Table {
  @override
  String get tableName => 'fraud_flags';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text().nullable()();

  /// Rule identifier, e.g. 'EXCESSIVE_REFUNDS' (see FraudRule.code).
  TextColumn get ruleCode => text()();

  /// 'low' | 'medium' | 'high' | 'critical'
  TextColumn get severity => text()();

  /// 'new' | 'investigating' | 'resolved' | 'dismissed'
  TextColumn get status => text().withDefault(const Constant('new'))();

  TextColumn get title => text()();
  TextColumn get description => text()();

  /// auth.uid() of the implicated employee (same id space as
  /// transactions.cashier_id / refunds.refunded_by); null when no single
  /// subject. The server blocks this user from resolving the flag.
  TextColumn get subjectUserId => text().nullable()();

  /// JSON list of structured evidence factors ({fact, value, baseline, ...}).
  TextColumn get evidence => text().withDefault(const Constant('[]'))();

  /// JSON list of source record ids (transactions, refunds, ledger rows).
  TextColumn get relatedIds => text().withDefault(const Constant('[]'))();

  TextColumn get resolvedBy => text().nullable()();
  TextColumn get resolutionNote => text().nullable()();

  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get clientUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Deterministic per-incident key, e.g.
  /// `EXCESSIVE_REFUNDS|userId|2026-07-03`. Unique per business (index
  /// created in the v54 migration; Drift table files don't declare indexes).
  TextColumn get dedupeKey => text()();

  /// 0=pendingUpload, 1=pendingUpdate, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
