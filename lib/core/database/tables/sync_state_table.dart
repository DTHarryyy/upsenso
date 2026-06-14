import 'package:drift/drift.dart';

/// Per-entity, per-business watermark for incremental (delta) sync.
///
/// Stores the server `updated_at` of the last row successfully pulled for an
/// entity, so the next pull can request only rows changed since. Null / missing
/// means "never delta-pulled" → do a full (paged) pull. See
/// docs/delta_sync_design.md. Unused until the delta-pull path lands (Phase 2).
class SyncStateTable extends Table {
  @override
  String get tableName => 'sync_state';

  /// Logical entity name, e.g. 'products', 'transactions', 'stock_ledger'.
  TextColumn get entity => text()();
  TextColumn get businessId => text()();

  /// Server `updated_at`/`created_at` of the last row applied. Null until first
  /// pull.
  DateTimeColumn get lastPulledAt => dateTime().nullable()();

  /// Id of the last row applied — the tiebreak half of a (timestamp, id) keyset
  /// cursor, so rows sharing a timestamp (e.g. a migration backfill or a batch
  /// insert) aren't skipped at a page boundary.
  TextColumn get lastPulledId => text().nullable()();

  @override
  Set<Column> get primaryKey => {entity, businessId};
}
