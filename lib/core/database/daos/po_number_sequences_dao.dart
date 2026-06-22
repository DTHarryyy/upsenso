import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/po_number_sequences_table.dart';

part 'po_number_sequences_dao.g.dart';

@DriftAccessor(tables: [PoNumberSequencesTable])
class PoNumberSequencesDao extends DatabaseAccessor<AppDatabase>
    with _$PoNumberSequencesDaoMixin {
  PoNumberSequencesDao(super.db);

  /// Atomically increments the local counter and returns the next PO number in
  /// `PO-YYYYMM-NNNN` format. Runs in a transaction so concurrent creates on the
  /// same device never produce the same number.
  Future<String> nextLocalPoNumber(String businessId, String monthKey) async {
    return db.transaction(() async {
      final existing =
          await (select(poNumberSequencesTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.monthKey.equals(monthKey),
              ))
              .getSingleOrNull();

      final next = (existing?.lastValue ?? 0) + 1;
      final companion = PoNumberSequencesTableCompanion(
        businessId: Value(businessId),
        monthKey: Value(monthKey),
        lastValue: Value(next),
        updatedAt: Value(DateTime.now()),
      );

      if (existing == null) {
        await into(poNumberSequencesTable).insert(companion);
      } else {
        await (update(poNumberSequencesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.monthKey.equals(monthKey),
            ))
            .write(companion);
      }

      return 'PO-$monthKey-${next.toString().padLeft(4, '0')}';
    });
  }

  /// Advance the local counter to [serverValue] if the server is ahead, so the
  /// local counter never re-issues a number already claimed online.
  Future<void> syncFromServer({
    required String businessId,
    required String monthKey,
    required int serverValue,
  }) async {
    final existing =
        await (select(poNumberSequencesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.monthKey.equals(monthKey),
            ))
            .getSingleOrNull();

    if (existing == null || existing.lastValue < serverValue) {
      await into(poNumberSequencesTable).insertOnConflictUpdate(
        PoNumberSequencesTableCompanion.insert(
          businessId: businessId,
          monthKey: monthKey,
          lastValue: Value(serverValue),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
