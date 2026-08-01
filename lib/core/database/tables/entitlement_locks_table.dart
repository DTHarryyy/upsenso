import 'package:drift/drift.dart';

/// Resources the plan caps and this table can lock. String-valued rather than a
/// Drift enum so an older build reading a newer row degrades to "unknown lock"
/// instead of throwing on an unmapped index.
class EntitlementLockKinds {
  static const branch = 'branch';
  static const seat = 'seat';
}

/// Which branches / seats are held above the plan's cap.
///
/// When a tenant downgrades or lapses below their current usage, nothing is
/// deleted — the excess is *locked*, and this records exactly which rows and
/// why so an upgrade can release precisely the right ones (design §10).
///
/// Deliberately local-only: it has no Supabase counterpart, and a lapsed tenant
/// has cloud sync off anyway, so there is nothing to reconcile. The trade-off is
/// that two devices on a *paid* downgrade can pick different active sets until
/// the owner confirms one; the chooser is per-device by design and the server
/// caps still bound the total.
@DataClassName('EntitlementLockRow')
class EntitlementLocksTable extends Table {
  @override
  String get tableName => 'entitlement_locks';

  TextColumn get businessId => text()();

  /// One of [EntitlementLockKinds].
  TextColumn get resourceKind => text()();

  /// Branch id or employee id, depending on [resourceKind].
  TextColumn get resourceId => text()();

  DateTimeColumn get lockedAt => dateTime().withDefault(currentDateAndTime)();

  /// Plan code in force when the lock was applied — lets the UI say "locked
  /// when you moved to Free" rather than a bare "locked".
  TextColumn get lockedUnderPlan => text().withDefault(const Constant('free'))();

  @override
  Set<Column> get primaryKey => {businessId, resourceKind, resourceId};
}
