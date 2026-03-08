import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/auth_context_table.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

part 'auth_context_dao.g.dart';

@DriftAccessor(tables: [AuthContextTable])
class AuthContextDao extends DatabaseAccessor<AppDatabase>
    with _$AuthContextDaoMixin {
  AuthContextDao(super.db);

  /// Get cached auth context for current user (single row, keyed by userId)
  Future<AuthContextTableData?> getContext(String userId) async {
    return (select(
      authContextTable,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  /// Watch cached auth context (for reactive updates when offline)
  Stream<AuthContextTableData?> watchContext(String userId) {
    return (select(
      authContextTable,
    )..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  /// Save or update cached auth context for user
  Future<void> saveContext({
    required String userId,
    String? email,
    String? fullName,
    String? businessId,
    String? roleId,
    String? roleName,
    String? businessName,
    String? branchId,
    String? branchName,
  }) async {
    await into(authContextTable).insertOnConflictUpdate(
      AuthContextTableCompanion(
        userId: Value(userId),
        email: Value(email),
        fullName: Value(fullName),
        businessId: Value(businessId),
        roleId: Value(roleId),
        roleName: Value(roleName),
        businessName: Value(businessName),
        branchId: Value(branchId),
        branchName: Value(branchName),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear cached auth context for user
  Future<void> clearContext(String userId) async {
    await (delete(
      authContextTable,
    )..where((t) => t.userId.equals(userId))).go();
  }

  /// Clear all cached auth contexts (e.g., on app reset)
  Future<void> clearAll() async {
    await delete(authContextTable).go();
  }

  /// Convert Drift row to AppUser entity
  static AppUser toEntity(AuthContextTableData data) {
    return AppUser(
      id: data.userId,
      email: data.email,
      fullName: data.fullName,
      businessId: data.businessId,
      roleId: data.roleId,
      roleName: data.roleName,
      businessName: data.businessName,
      branchId: data.branchId,
      branchName: data.branchName,
    );
  }
}
