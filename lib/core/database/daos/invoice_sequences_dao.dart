import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/invoice_sequences_table.dart';

part 'invoice_sequences_dao.g.dart';

@DriftAccessor(tables: [InvoiceSequencesTable])
class InvoiceSequencesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoiceSequencesDaoMixin {
  InvoiceSequencesDao(super.db);

  /// Atomically increments the local counter and returns the next invoice
  /// number string in INV-NNNNNN format.
  /// Runs inside a DB transaction so concurrent checkout attempts on the
  /// same device never produce the same number.
  Future<String> nextLocalInvoiceNumber(
    String businessId,
    String monthKey,
  ) async {
    return db.transaction(() async {
      final existing =
          await (select(invoiceSequencesTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.monthKey.equals(monthKey),
              ))
              .getSingleOrNull();

      final next = (existing?.lastValue ?? 0) + 1;
      final companion = InvoiceSequencesTableCompanion(
        businessId: Value(businessId),
        monthKey: Value(monthKey),
        lastValue: Value(next),
        updatedAt: Value(DateTime.now()),
      );

      if (existing == null) {
        await into(invoiceSequencesTable).insert(companion);
      } else {
        await (update(invoiceSequencesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.monthKey.equals(monthKey),
            ))
            .write(companion);
      }

      return 'INV-${next.toString().padLeft(6, '0')}';
    });
  }

  /// Advance the local counter to [serverValue] if the server's counter is
  /// ahead of ours. Called after a successful server claim so the local counter
  /// never issues a duplicate of a number already taken online.
  Future<void> syncFromServer({
    required String businessId,
    required String monthKey,
    required int serverValue,
  }) async {
    final existing =
        await (select(invoiceSequencesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.monthKey.equals(monthKey),
            ))
            .getSingleOrNull();

    if (existing == null || existing.lastValue < serverValue) {
      await into(invoiceSequencesTable).insertOnConflictUpdate(
        InvoiceSequencesTableCompanion.insert(
          businessId: businessId,
          monthKey: monthKey,
          lastValue: Value(serverValue),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
