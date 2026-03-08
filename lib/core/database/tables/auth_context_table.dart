import 'package:drift/drift.dart';

/// Local table for caching authenticated user context (id, email, credentials, business context)
/// This enables offline access to user and business details without depending on Supabase session.
class AuthContextTable extends Table {
  @override
  String get tableName => 'auth_context';

  /// User's Supabase Auth UID (primary key for single current user)
  TextColumn get userId => text()();

  /// User's email address
  TextColumn get email => text().nullable()();

  /// User's full name
  TextColumn get fullName => text().nullable()();

  /// Associated business ID (from database trigger context)
  TextColumn get businessId => text().nullable()();

  /// User's role ID in the business
  TextColumn get roleId => text().nullable()();

  /// User's role name (e.g., "Super Admin", "Manager")
  TextColumn get roleName => text().nullable()();

  /// Associated business name
  TextColumn get businessName => text().nullable()();

  /// User's default/primary branch ID
  TextColumn get branchId => text().nullable()();

  /// User's default/primary branch name
  TextColumn get branchName => text().nullable()();

  /// Last time this context was updated locally
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
