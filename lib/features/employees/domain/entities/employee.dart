/// Business role of an employee (display-layer roles).
enum EmployeeRole { owner, branchManager, cashier, inventoryStaff }

/// Lifecycle status of an employee record.
enum EmployeeStatus { active, suspended, archived }

class Employee {
  final String id;
  final String businessId;
  final String branchId;

  /// Nullable – employee identity is decoupled from auth accounts.
  final String? authUserId;

  final String employeeCode;
  final String fullName;
  final String email;
  final String? phone;
  final EmployeeRole role;
  final EmployeeStatus status;
  final String? profileImageUrl;
  final DateTime hiredAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Employee({
    required this.id,
    required this.businessId,
    required this.branchId,
    this.authUserId,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.profileImageUrl,
    required this.hiredAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Employee copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? branchId,
    EmployeeRole? role,
    EmployeeStatus? status,
    String? profileImageUrl,
    DateTime? archivedAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      businessId: businessId,
      branchId: branchId ?? this.branchId,
      authUserId: authUserId,
      employeeCode: employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hiredAt: hiredAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension EmployeeRoleX on EmployeeRole {
  String get dbValue {
    switch (this) {
      case EmployeeRole.owner:
        return 'owner';
      case EmployeeRole.branchManager:
        return 'branch_manager';
      case EmployeeRole.cashier:
        return 'cashier';
      case EmployeeRole.inventoryStaff:
        return 'inventory_staff';
    }
  }

  String get displayName {
    switch (this) {
      case EmployeeRole.owner:
        return 'Owner';
      case EmployeeRole.branchManager:
        return 'Branch Manager';
      case EmployeeRole.cashier:
        return 'Cashier';
      case EmployeeRole.inventoryStaff:
        return 'Inventory Staff';
    }
  }

  static EmployeeRole fromDb(String value) {
    switch (value) {
      case 'owner':
        return EmployeeRole.owner;
      case 'branch_manager':
        return EmployeeRole.branchManager;
      case 'cashier':
        return EmployeeRole.cashier;
      case 'inventory_staff':
        return EmployeeRole.inventoryStaff;
      default:
        return EmployeeRole.cashier;
    }
  }
}

extension EmployeeStatusX on EmployeeStatus {
  String get dbValue {
    switch (this) {
      case EmployeeStatus.active:
        return 'active';
      case EmployeeStatus.suspended:
        return 'suspended';
      case EmployeeStatus.archived:
        return 'archived';
    }
  }

  String get displayName {
    switch (this) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.archived:
        return 'Archived';
    }
  }

  static EmployeeStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return EmployeeStatus.active;
      case 'suspended':
        return EmployeeStatus.suspended;
      case 'archived':
        return EmployeeStatus.archived;
      default:
        return EmployeeStatus.active;
    }
  }
}
