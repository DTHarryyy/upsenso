import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/domain/services/employee_validation_service.dart';

class EmployeesRepositoryImpl implements IEmployeesRepository {
  final EmployeesDao _dao;
  final EmployeesRemoteDs _remoteDs;
  final EmployeeValidationService _validator;
  static const _uuid = Uuid();

  EmployeesRepositoryImpl({
    required EmployeesDao dao,
    required EmployeesRemoteDs remoteDs,
    required EmployeeValidationService validator,
  }) : _dao = dao,
       _remoteDs = remoteDs,
       _validator = validator;

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<Employee>> watchEmployees(String businessId) {
    return _dao
        .watchByBusinessId(businessId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<Employee>> loadEmployees(String businessId) async {
    final rows = await _dao.getByBusinessId(businessId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<Employee?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    required String? phone,
    required EmployeeRole role,
    required DateTime hiredAt,
    required String password,
    String? authUserId,
    String? profileImageUrl,
  }) async {
    await _validator.validateNoDuplicates(
      businessId: businessId,
      email: email,
      phone: phone,
    );

    final id = _uuid.v4();
    final code = _generateCode(fullName);
    final now = DateTime.now();

    await _dao.insertEmployee(
      EmployeesTableCompanion.insert(
        id: id,
        businessId: businessId,
        branchId: branchId,
        authUserId: Value(authUserId),
        employeeCode: code,
        fullName: fullName,
        email: email,
        phone: Value(phone),
        role: role.dbValue,
        profileImageUrl: Value(profileImageUrl),
        hiredAt: hiredAt,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeCreated,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName created',
      metadata: {'role': role.dbValue, 'branch_id': branchId},
    );

    // Create the Supabase Auth account and atomically write the
    // public.employees row in the same RPC call.  This eliminates the
    // race condition where an employee could log in before the Flutter
    // sync cycle had a chance to push the employee record to Supabase.
    // If the device is offline the local record still exists and both
    // the auth account + server employee row are created on the next
    // online sync via _syncEmployees().
    final createdAuthId = await _remoteDs.createAuthAccount(
      email: email,
      password: password,
      employeeId: id,
      businessId: businessId,
      branchId: branchId,
      fullName: fullName,
      role: role.dbValue,
      employeeCode: code,
      phone: phone,
      hiredAt: hiredAt,
    );
    if (createdAuthId != null) {
      await _dao.updateEmployee(
        id,
        EmployeesTableCompanion(authUserId: Value(createdAuthId)),
      );
    }
  }

  @override
  Future<void> updateEmployee({
    required String id,
    required String fullName,
    required String email,
    required String? phone,
    required String branchId,
    required EmployeeRole role,
    String? profileImageUrl,
  }) async {
    final existing = await _dao.getById(id);
    if (existing != null) {
      await _validator.validateNoDuplicates(
        businessId: existing.businessId,
        email: email,
        phone: phone,
        excludeId: id,
      );
    }

    final now = DateTime.now();

    final prevRole = existing?.role;

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        fullName: Value(fullName),
        email: Value(email),
        phone: Value(phone),
        branchId: Value(branchId),
        role: Value(role.dbValue),
        profileImageUrl: Value(profileImageUrl),
        updatedAt: Value(now),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );

    final actionType = (prevRole != null && prevRole != role.dbValue)
        ? AuditLogActionType.employeeRoleChanged
        : AuditLogActionType.employeeUpdated;

    sl<AuditLogService>().log(
      actionType: actionType,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName updated',
      metadata: {
        'role': role.dbValue,
        if (prevRole != null && prevRole != role.dbValue)
          'previous_role': prevRole,
      },
    );
  }

  @override
  Future<void> archiveEmployee(String id) async {
    final now = DateTime.now();
    final existing = await _dao.getById(id);

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        status: const Value('archived'),
        archivedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeArchived,
      entityType: 'employee',
      entityId: id,
      entityName: existing?.fullName,
      description: 'Employee ${existing?.fullName ?? id} archived',
    );
  }

  @override
  Future<void> suspendEmployee(String id) async {
    final now = DateTime.now();
    final existing = await _dao.getById(id);

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        status: const Value('suspended'),
        updatedAt: Value(now),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeStatusChanged,
      entityType: 'employee',
      entityId: id,
      entityName: existing?.fullName,
      description: 'Employee ${existing?.fullName ?? id} suspended',
      metadata: {'status': 'suspended'},
    );
  }

  @override
  Future<void> reactivateEmployee(String id) async {
    final now = DateTime.now();
    final existing = await _dao.getById(id);

    await _dao.updateEmployee(
      id,
      EmployeesTableCompanion(
        status: const Value('active'),
        archivedAt: const Value(null),
        updatedAt: Value(now),
        syncStatus: Value(
          existing?.syncStatus == SyncStatus.pendingUpload.toInt()
              ? SyncStatus.pendingUpload.toInt()
              : SyncStatus.pendingUpdate.toInt(),
        ),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeStatusChanged,
      entityType: 'employee',
      entityId: id,
      entityName: existing?.fullName,
      description: 'Employee ${existing?.fullName ?? id} reactivated',
      metadata: {'status': 'active'},
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Employee _toEntity(EmployeeRow row) {
    return Employee(
      id: row.id,
      businessId: row.businessId,
      branchId: row.branchId,
      authUserId: row.authUserId,
      employeeCode: row.employeeCode,
      fullName: row.fullName,
      email: row.email,
      phone: row.phone,
      role: EmployeeRoleX.fromDb(row.role),
      status: EmployeeStatusX.fromDb(row.status),
      profileImageUrl: row.profileImageUrl,
      hiredAt: row.hiredAt,
      archivedAt: row.archivedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  String _generateCode(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(3)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    // 6-digit suffix from microseconds — repeats only every ~1 second,
    // making same-initials collisions effectively impossible in normal use.
    final suffix = DateTime.now().microsecondsSinceEpoch % 1000000;
    return '$initials${suffix.toString().padLeft(6, '0')}';
  }
}
