import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/fraud_candidates_table.dart';

part 'fraud_candidates_dao.g.dart';

@DriftAccessor(tables: [FraudCandidatesTable])
class FraudCandidatesDao extends DatabaseAccessor<AppDatabase>
    with _$FraudCandidatesDaoMixin {
  FraudCandidatesDao(super.db);

  Future<FraudCandidateRow?> getByKey(String businessId, String dedupeKey) {
    return (select(fraudCandidatesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.dedupeKey.equals(dedupeKey),
          ))
        .getSingleOrNull();
  }

  /// First sighting of an incident.
  Future<void> insertCandidate({
    required String businessId,
    required String dedupeKey,
    required String ruleCode,
    required String signature,
    required DateTime seenAt,
    DateTime? watermark,
  }) {
    return into(fraudCandidatesTable).insert(
      FraudCandidatesTableCompanion.insert(
        businessId: businessId,
        dedupeKey: dedupeKey,
        ruleCode: ruleCode,
        signature: signature,
        firstSeenAt: seenAt,
        lastSeenAt: seenAt,
        watermarkAtFirstSeen: Value(watermark),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Re-sighting with the SAME signature — bumps the counter. A changed
  /// signature means a different observation: the caller re-inserts instead,
  /// restarting confirmation.
  Future<void> incrementSighting({
    required String businessId,
    required String dedupeKey,
    required DateTime seenAt,
  }) {
    return customUpdate(
      'UPDATE fraud_candidates SET seen_count = seen_count + 1, '
      'last_seen_at = ? WHERE business_id = ? AND dedupe_key = ?',
      variables: [
        Variable<int>(seenAt.toUtc().millisecondsSinceEpoch ~/ 1000),
        Variable.withString(businessId),
        Variable.withString(dedupeKey),
      ],
      updates: {fraudCandidatesTable},
    );
  }

  Future<void> deleteByKey(String businessId, String dedupeKey) {
    return (delete(fraudCandidatesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.dedupeKey.equals(dedupeKey),
          ))
        .go();
  }

  /// Silent auto-resolution: candidates of [ruleCode] no longer observed by
  /// the current full sweep vanish before ever becoming user-visible.
  Future<int> deleteStale({
    required String businessId,
    required String ruleCode,
    required Set<String> keepKeys,
  }) async {
    final rows = await (select(fraudCandidatesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) & t.ruleCode.equals(ruleCode),
          ))
        .get();
    var removed = 0;
    for (final row in rows) {
      if (keepKeys.contains(row.dedupeKey)) continue;
      await deleteByKey(businessId, row.dedupeKey);
      removed++;
    }
    return removed;
  }
}
