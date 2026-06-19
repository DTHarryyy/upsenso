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
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
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
      final roles = await _remoteDs.getRolesByBusiness(businessId);
      return roles[roleName.toLowerCase().trim()];
    } catch (e, st) {
      debugPrint('[EmployeesRepo] Error in _resolveRoleId: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    required String password,
    String? roleId,
    String? roleName,
    bool isActive = true,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

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
      authUserId = await _remoteDs.createAuthAccount(
        email: email,
        password: password,
        businessId: businessId,
        branchId: branchId.isEmpty ? null : branchId,
        fullName: fullName,
        roleId: roleId,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('DUPLICATE_EMAIL') ||
          e.message.toLowerCase().contains('email already') ||
          e.message.toLowerCase().contains('already registered')) {
        throw EmployeeDuplicateException({
          'email': 'This email is already registered to an employee.',
        });
      }
      rethrow;
    }

    // Step 2: Upsert the employee row and branch assignment to Supabase.
    // This is also required: without the employee row in Supabase the new
    // user's my_business_id() call returns null and they cannot log in.
    await _remoteDs.upsertEmployee(
      id: id,
      businessId: businessId,
      authUserId: authUserId,
      fullName: fullName,
      roleId: roleId,
      roleName: roleName,
      isActive: isActive,
    );
    if (branchId.isNotEmpty) {
      await _remoteDs.assignBranch(employeeId: id, branchId: branchId);
    }

    // Step 3: Derive role-default permissions for local cache seeding.
    final permissions = DefaultPermissionMatrix.forRole(roleName);

    // Step 4: Trigger server-side permission snapshot for the new employee
    // (best-effort — the snapshot will be rebuilt on next login if this fails).
    if (branchId.isNotEmpty) {
      try {
        await _permissionRemoteDs.computePermissions(id, branchId);
      } catch (e) {
        debugPrint('[EmployeesRepo] Permission snapshot seeding failed: $e');
      }
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

  // Owner / Super Admin accounts are protected: the DB rejects deactivating
  // them, so we block it here too rather than letting it fail during sync.
  static bool _isOwnerRole(String? roleName) {
    switch (roleName?.toLowerCase().trim()) {
      case 'owner':
      case 'business owner':
      case 'super admin':
      case 'superadmin':
        return true;
      default:
        return false;
    }
  }

  Future<void> _setActive(
    String id,
    bool active,
    AuditLogActionType actionType,
    String statusLabel,
  ) async {
    final existing = await _dao.getById(id);

    if (!active && _isOwnerRole(existing?.roleName)) {
      throw const EmployeeProtectedException();
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
