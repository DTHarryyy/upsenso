import 'package:drift/drift.dart';

/// Local, read-only snapshot of the tenant's subscription entitlement,
/// written only by the entitlement sync path (never by feature code).
///
/// Mirrors `get_my_entitlement()` — the server is the authority; this cache
/// only makes the answer available offline. Tampering with it unlocks nothing
/// with cloud value: every remote write dies at RLS regardless.
///
/// This table is schema version 58.
@DataClassName('EntitlementCacheRow')
class EntitlementCacheTable extends Table {
  @override
  String get tableName => 'entitlement_cache';

  TextColumn get businessId => text()();

  TextColumn get planCode => text().withDefault(const Constant('free'))();
  IntColumn get planVersion => integer().withDefault(const Constant(1))();

  /// Server-computed effective status at last sync:
  /// trialing | active | past_due | free | lapsed.
  /// The service re-derives transitions locally from the timestamps below.
  TextColumn get status => text().withDefault(const Constant('free'))();

  BoolColumn get cloudEnabled => boolean().withDefault(const Constant(false))();

  /// JSON-encoded feature flags, e.g. `{"crm":"basic","procurement":false}`.
  TextColumn get featureFlagsJson => text().withDefault(const Constant('{}'))();

  /// Effective caps (snapshot + add-ons already folded in server-side).
  /// Null = unlimited.
  IntColumn get maxBranches => integer().nullable()();
  IntColumn get maxSeats => integer().nullable()();
  IntColumn get maxDevices => integer().nullable()();

  IntColumn get deviceAddons => integer().withDefault(const Constant(0))();
  IntColumn get branchAddons => integer().withDefault(const Constant(0))();
  IntColumn get seatAddons => integer().withDefault(const Constant(0))();

  DateTimeColumn get trialEnd => dateTime().nullable()();
  DateTimeColumn get currentPeriodEnd => dateTime().nullable()();
  DateTimeColumn get graceUntil => dateTime().nullable()();

  RealColumn get grandfatheredPrice => real().nullable()();

  /// Server clock at the last successful entitlement fetch — the anchor for
  /// the clock-tamper clamp (grace is measured against this, never the
  /// device clock alone).
  DateTimeColumn get lastServerSyncAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId};
}
