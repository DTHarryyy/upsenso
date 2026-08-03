import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/core/utils/temp_password_generator.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/entities/employee_creation_result.dart';
import 'package:pos/features/employees/domain/errors/employee_errors.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeesRepositoryImpl implements IEmployeesRepository {
  final EmployeesDao _dao;
  final EmployeesRemoteDs _remoteDs;
  final EmployeePermissionsDao _permissionsDao;
  final PermissionRemoteDs _permissionRemoteDs;

  static const _uuid = Uuid();

  EmployeesRepositoryImpl({
    required EmployeesDao dao,
    required EmployeesRemoteDs remoteDs,
    required EmployeePermissionsDao permissionsDao,
    required PermissionRemoteDs permissionRemoteDs,
  })  : _dao = dao,
        _remoteDs = remoteDs,
        _permissionsDao = permissionsDao,
        _permissionRemoteDs = permissionRemoteDs;

  // ── Read ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<Employee>> watchEmployees(String businessId) {
    return _dao
        .watchByBusinessId(businessId)
        .map((rows) => rows.map<Employee>(_toEntity).toList());
  }

  @override
  Future<List<Employee>> loadEmployees(String businessId) async {
    final rows = await _dao.getByBusinessId(businessId);
    return rows.map<Employee>(_toEntity).toList();
  }

  @override
  Future<Employee?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  // Resolves a display role name to its real role UUID for this business.
  // Returns null when no matching role row exists so callers fall back safely.
  Future<String?> _resolveRoleId(String businessId, String? roleName) async {
    if (roleName == null || roleName.trim().isEmpty) return null;
    try {
      final roles = await _remoteDs
          .getRolesByBusiness(businessId)
          .timeout(const Duration(seconds: 10));
      return roles[roleName.toLowerCase().trim()];
    } catch (e, st) {
      debugPrint('[EmployeesRepo] Error in _resolveRoleId: $e\n$st');
      return null;
    }
  }

  @override
  Future<EmployeeCreationResult> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    String? roleId,
    String? roleName,
    bool isActive = true,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    // The creator never sees or picks this — it exists only long enough to
    // mint the auth account and email it below.
    final tempPassword = generateTemporaryPassword();

    // Seat-cap pre-check before the auth account is minted — counted live from
    // local Drift. The server RPC enforces the same cap for cloud tiers (M7.1
    // §6.2); on local-only Free this client check is the gate.
    if (!await sl<EntitlementService>()
        .canAddAnother(EntitlementResource.seats)) {
      throw const EmployeeSeatLimitException();
    }

    // The form only carries a display role name; resolve the real UUID so RBAC
    // is keyed on a stable role id rather than free-text.
    roleId ??= await _resolveRoleId(businessId, roleName);

    // Step 1: Create the Supabase Auth user. This MUST succeed — the password
    // is only available now and cannot be stored for a later retry.
    // If the email is already linked to a complete employee in this business,
    // the RPC raises DUPLICATE_EMAIL which we translate to a field-level error
    // so the form can show it inline rather than as a generic snackbar.
    final String authUserId;
    try {
      authUserId = await _remoteDs
          .createAuthAccount(
            email: email,
            password: tempPassword,
            businessId: businessId,
            branchId: branchId.isEmpty ? null : branchId,
            fullName: fullName,
            roleId: roleId,
          )
          .timeout(const Duration(seconds: 15));
    } on PostgrestException catch (e) {
      // The RPC's own RAISE EXCEPTION is the normal path; the raw Postgres
      // unique-violation code (23505) is a backstop for the rare race where
      // two creates for the same email hit auth.users' unique index at once.
      if (e.code == '23505' ||
          e.message.contains('DUPLICATE_EMAIL') ||
          e.message.toLowerCase().contains('email already') ||
          e.message.toLowerCase().contains('already registered')) {
        throw EmployeeDuplicateException({
          'email': 'This email is already registered to an employee.',
        });
      }
      // The RPC's seat cap (M7.1 §6.2) is authoritative server-side — the
      // client-side pre-check above is only a courtesy for the common case.
      if (e.message.contains('SEAT_LIMIT_REACHED')) {
        throw const EmployeeSeatLimitException();
      }
      rethrow;
    }

    // Step 2: Upsert the employee row and branch assignment to Supabase.
    // This is also required: without the employee row in Supabase the new
    // user's my_business_id() call returns null and they cannot log in.
    await _remoteDs
        .upsertEmployee(
          id: id,
          businessId: businessId,
          authUserId: authUserId,
          fullName: fullName,
          email: email,
          roleId: roleId,
          roleName: roleName,
          isActive: isActive,
        )
        .timeout(const Duration(seconds: 15));
    if (branchId.isNotEmpty) {
      await _remoteDs
          .assignBranch(employeeId: id, branchId: branchId)
          .timeout(const Duration(seconds: 15));
    }

    // Step 3: Derive role-default permissions for local cache seeding.
    final permissions = DefaultPermissionMatrix.forRole(roleName);
    // A non-standard role has no offline default set — make that visible rather
    // than silently caching nothing. The employee still resolves real grants
    // from the server snapshot below / get_my_permissions() on first login.
    if (permissions.isEmpty) {
      debugPrint(
        '[EmployeesRepo] No offline default permissions for role "$roleName" — '
        'employee $id will resolve permissions from the server on first login.',
      );
    }

    // Step 4: Trigger server-side permission snapshot for the new employee
    // (best-effort — the snapshot will be rebuilt on next login if this fails).
    if (branchId.isNotEmpty) {
      try {
        await _permissionRemoteDs
            .computePermissions(id, branchId)
            .timeout(const Duration(seconds: 10));
      } catch (e, st) {
        debugPrint('[EmployeesRepo] Permission snapshot seeding failed: $e\n$st');
      }
    } else {
      // No branch yet → the snapshot RPC (branch-scoped) can't run now. First
      // login bootstraps it via get_my_permissions(); flag it so it's not silent.
      debugPrint(
        '[EmployeesRepo] Employee $id created without a branch — server '
        'permission snapshot deferred to first login.',
      );
    }

    // Step 5: Persist the employee locally as already-synced.
    await _dao.insertEmployee(
      EmployeesTableCompanion.insert(
        id: id,
        businessId: businessId,
        authUserId: Value(authUserId),
        email: Value(email),
        fullName: Value(fullName),
        branchId: Value(branchId.isEmpty ? null : branchId),
        roleId: Value(roleId),
        roleName: Value(roleName),
        isActive: Value(isActive),
        createdAt: Value(now),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );

    // Keep the seat meter + cap pre-check in step with the new local row.
    await sl<EntitlementService>().recomputeLocalUsage();

    // Step 6: Cache permissions locally so the employee's very first login
    // resolves permissions without a Supabase round-trip.
    if (permissions.isNotEmpty) {
      await _permissionsDao.savePermissions(
        authUserId,
        permissions,
        employeeId: id,
      );
    }

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeCreated,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName created',
      metadata: {'role': roleName, 'branch_id': branchId},
    );

    // Step 7: Email the employee their login credentials. Best-effort — the
    // account already exists, so a delivery failure must not fail creation.
    // The generated password is only kept around long enough to report it
    // back to the caller if this fails — never persisted.
    var credentialsEmailed = true;
    try {
      // Short timeout — this is the last thing gating dialog dismissal, so it
      // must never let a Deno cold start or a slow Resend call dominate the
      // wait the way it used to when this had no timeout at all.
      await _remoteDs
          .sendCredentialsEmail(
            email: email,
            password: tempPassword,
            fullName: fullName,
          )
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      credentialsEmailed = false;
      debugPrint('[EmployeesRepo] Credential email failed: $e\n$st');
    }

    return EmployeeCreationResult(
      employeeId: id,
      email: email,
      credentialsEmailed: credentialsEmailed,
      temporaryPassword: credentialsEmailed ? null : tempPassword,
    );
  }

  @override
  Future<void> updateEmployee({
    required String id,
    required String fullName,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
  }) async {
    final existing = await _dao.getById(id);

    // Resolve the role UUID from the chosen display name so an edited role
    // actually persists (and syncs) instead of being silently dropped.
    if (roleId == null && roleName != null && existing != null) {
      roleId = await _resolveRoleId(existing.businessId, roleName);
    }

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        fullName: Value(fullName),
        roleId: roleId != null ? Value(roleId) : const Value.absent(),
        roleName: roleName != null ? Value(roleName) : const Value.absent(),
        branchId: branchId != null ? Value(branchId) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeUpdated,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName updated',
    );
  }

  @override
  Future<void> archiveEmployee(String id) =>
      _setActive(id, false, AuditLogActionType.employeeArchived, 'archived');

  @override
  Future<void> suspendEmployee(String id) =>
      _setActive(id, false, AuditLogActionType.employeeStatusChanged, 'suspended');

  @override
  Future<void> reactivateEmployee(String id) =>
      _setActive(id, true, AuditLogActionType.employeeStatusChanged, 'active');

  // Owner-tier accounts are protected from deactivation by anyone — except
  // the real Business Owner removing one they created (an owner-tier
  // *employee* trying to remove another owner-tier employee is still
  // blocked, same as before).
  static bool _isOwnerRole(String? roleName) =>
      RolePermissionMatrix.isOwnerRoleName(roleName);

  // The real Business Owner has no row in `employees` at all — they're
  // created directly in `users` at onboarding and never get an employee
  // record. A Business-Owner-tier *employee*, by contrast, always has one.
  // So "no employee row matches my session" is what tells the two apart.
  Future<bool> _actingAsLiteralOwner(String businessId) async {
    final activeUserId = sl<ActiveBusinessContext>().userId;
    if (activeUserId == null) return false;
    final rows = await _dao.getByBusinessId(businessId);
    return !rows.any((e) => e.authUserId == activeUserId);
  }

  Future<void> _setActive(
    String id,
    bool active,
    AuditLogActionType actionType,
    String statusLabel,
  ) async {
    final existing = await _dao.getById(id);

    if (!active && _isOwnerRole(existing?.roleName)) {
      final businessId = existing?.businessId;
      final isLiteralOwner =
          businessId != null && await _actingAsLiteralOwner(businessId);
      if (!isLiteralOwner) {
        throw const EmployeeProtectedException();
      }
    }

    // Reactivating consumes a seat exactly like hiring does. Without this a
    // downgraded tenant could suspend nobody and simply re-enable everyone the
    // enforcement pass had just parked — and the server's
    // enforce_seat_cap_on_reactivate trigger would reject the sync much later,
    // leaving the local row lying about who can sign in.
    if (active &&
        !await sl<EntitlementService>()
            .canAddAnother(EntitlementResource.seats)) {
      throw const EmployeeSeatLimitException();
    }

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        isActive: Value(active),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );
    sl<AuditLogService>().log(
      actionType: actionType,
      entityType: 'employee',
      entityId: id,
      entityName: existing?.fullName,
      description: 'Employee ${existing?.fullName ?? id} $statusLabel',
      metadata: {'is_active': active},
    );
    // Seat count moved either way — keep the meter and the lock set honest.
    await sl<EntitlementService>().recomputeLocalUsage();
    await sl<EntitlementEnforcementService>().reconcile();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Employee _toEntity(EmployeeRow row) {
    return Employee(
      id: row.id,
      businessId: row.businessId,
      userId: row.userId,
      authUserId: row.authUserId,
      email: row.email,
      fullName: row.fullName ?? '',
      roleId: row.roleId,
      roleName: row.roleName,
      branchId: row.branchId,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }
}
