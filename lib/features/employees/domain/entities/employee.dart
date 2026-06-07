class Employee {
  final String id;
  final String businessId;
  final String? userId;
  final String? authUserId;
  final String fullName;
  final String? roleId;
  final String? roleName;
  final String? branchId;
  final bool isActive;
  final DateTime? createdAt;

  const Employee({
    required this.id,
    required this.businessId,
    this.userId,
    this.authUserId,
    required this.fullName,
    this.roleId,
    this.roleName,
    this.branchId,
    this.isActive = true,
    this.createdAt,
  });

  Employee copyWith({
    String? fullName,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
  }) {
    return Employee(
      id: id,
      businessId: businessId,
      userId: userId,
      authUserId: authUserId,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Kept for display/UI purposes only — role identity on the server is a UUID.
enum EmployeeRole { superAdmin, branchManager, cashier, inventoryStaff }

extension EmployeeRoleX on EmployeeRole {
  String get displayName {
    switch (this) {
      case EmployeeRole.superAdmin:
        return 'Super Admin';
      case EmployeeRole.branchManager:
        return 'Branch Manager';
      case EmployeeRole.cashier:
        return 'Cashier';
      case EmployeeRole.inventoryStaff:
        return 'Inventory Staff';
    }
  }

  static EmployeeRole fromRoleName(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'super admin':
      case 'superadmin':
      case 'owner':
        return EmployeeRole.superAdmin;
      case 'branch manager':
        return EmployeeRole.branchManager;
      case 'cashier':
        return EmployeeRole.cashier;
      case 'inventory staff':
        return EmployeeRole.inventoryStaff;
      default:
        return EmployeeRole.cashier;
    }
  }
}
