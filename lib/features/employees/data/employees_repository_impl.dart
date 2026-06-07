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

class EmployeesRepositoryImpl implements IEmployeesRepository {
  final EmployeesDao _dao;
  final EmployeesRemoteDs _remoteDs;
  static const _uuid = Uuid();

  EmployeesRepositoryImpl({
    required EmployeesDao dao,
    required EmployeesRemoteDs remoteDs,
  }) : _dao = dao,
       _remoteDs = remoteDs;

  // ── Read ──────────────────────────────────────────────────────────────────

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

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    required String password,
    String? roleId,
    bool isActive = true,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _dao.insertEmployee(
      EmployeesTableCompanion.insert(
        id: id,
        businessId: businessId,
        fullName: Value(fullName),
        branchId: Value(branchId),
        roleId: Value(roleId),
        isActive: Value(isActive),
        createdAt: Value(now),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeCreated,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName created',
      metadata: {'role_id': roleId, 'branch_id': branchId},
    );

    final createdAuthId = await _remoteDs.createAuthAccount(
      email: email,
      password: password,
      employeeId: id,
      businessId: businessId,
      branchId: branchId,
      fullName: fullName,
      roleId: roleId,
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
    String? roleId,
    String? branchId,
    bool? isActive,
  }) async {
    final existing = await _dao.getById(id);

    final companion = EmployeesTableCompanion(
      fullName: Value(fullName),
      roleId: roleId != null ? Value(roleId) : const Value.absent(),
      branchId: branchId != null ? Value(branchId) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      syncStatus: Value(
        existing?.syncStatus == SyncStatus.pendingUpload.toInt()
            ? SyncStatus.pendingUpload.toInt()
            : SyncStatus.pendingUpdate.toInt(),
      ),
    );

    await _dao.updateEmployee(id, companion);

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.employeeUpdated,
      entityType: 'employee',
      entityId: id,
      entityName: fullName,
      description: 'Employee $fullName updated',
    );
  }

  @override
  Future<void> archiveEmployee(String id) => _setActive(id, false,
      AuditLogActionType.employeeArchived, 'archived');

  @override
  Future<void> suspendEmployee(String id) => _setActive(id, false,
      AuditLogActionType.employeeStatusChanged, 'suspended');

  @override
  Future<void> reactivateEmployee(String id) => _setActive(id, true,
      AuditLogActionType.employeeStatusChanged, 'active');

  Future<void> _setActive(
    String id,
    bool active,
    AuditLogActionType actionType,
    String statusLabel,
  ) async {
    final existing = await _dao.getById(id);
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Employee _toEntity(EmployeeRow row) {
    return Employee(
      id: row.id,
      businessId: row.businessId,
      userId: row.userId,
      authUserId: row.authUserId,
      fullName: row.fullName ?? '',
      roleId: row.roleId,
      roleName: row.roleName,
      branchId: row.branchId,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }
}
