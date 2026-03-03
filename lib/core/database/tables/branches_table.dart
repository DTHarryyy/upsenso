import 'package:drift/drift.dart';

/// Local table for branches with sync status tracking
class BranchesTable extends Table {
  @override
  String get tableName => 'branches';

  /// UUID - generated locally, should match Supabase after sync
  TextColumn get id => text()();

  /// Foreign key to businesses table
  TextColumn get businessId => text()();

  /// Branch name (required)
  TextColumn get name => text()();

  /// Branch address (optional, completed later in settings)
  TextColumn get address => text().nullable()();

  /// Branch phone number (optional, completed later in settings)
  TextColumn get phone => text().nullable()();

  /// Whether branch is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Sync tracking fields
  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
