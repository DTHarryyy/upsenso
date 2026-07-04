import 'package:drift/drift.dart';

/// Pre-flag staging for detections that must survive re-observation before
/// they become user-visible fraud_flags (ORPHANED_RECORD / AUDIT_TAMPER /
/// TIME_REVERSAL — the rules whose false positives come from a stale local
/// mirror rather than real events). A candidate that stops matching on a
/// later sweep is deleted silently: auto-resolution BEFORE any noise.
///
/// Local-only, never synced — candidates are not evidence; the promoted flag
/// remains the synced artifact. Deleting a candidate only delays a flag by
/// one sweep, so this table is not a meaningful tamper target.
@DataClassName('FraudCandidateRow')
class FraudCandidatesTable extends Table {
  @override
  String get tableName => 'fraud_candidates';

  TextColumn get businessId => text()();

  /// Same deterministic incident key the flag would carry.
  TextColumn get dedupeKey => text()();

  TextColumn get ruleCode => text()();

  /// Stable fingerprint of the observation (encoded evidence) — a changed
  /// signature means a different observation and restarts confirmation.
  TextColumn get signature => text()();

  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  IntColumn get seenCount => integer().withDefault(const Constant(1))();

  /// audit_logs pull watermark at first sighting — promotion of
  /// mirror-dependent rules requires the mirror to have advanced since.
  DateTimeColumn get watermarkAtFirstSeen => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, dedupeKey};
}
