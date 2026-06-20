import 'package:drift/drift.dart';

/// One refunded line within a [RefundsTable] event. Append-only, like its
/// parent. `qty` is the amount of that line being returned in THIS refund
/// event — total refunded-to-date for a line is the sum across all
/// refund_items rows referencing it, never a stored running total.
/// Syncs to the Supabase `refund_items` table.
class RefundItemsTable extends Table {
  @override
  String get tableName => 'refund_items';

  TextColumn get id => text()();
  TextColumn get refundId => text()(); // → refund_id (FK)
  TextColumn get transactionItemId => text()(); // → transaction_item_id (FK)
  TextColumn get variantId => text()(); // → variant_id
  RealColumn get qty => real()(); // → qty (must be > 0)
  RealColumn get amount => real()(); // → amount (must be >= 0)
  // Whether this line's qty was added back to sellable stock. Lets the
  // refunder mark damaged/expired/opened returns as NOT restocked, instead of
  // every refund unconditionally inflating inventory.
  BoolColumn get restocked => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
