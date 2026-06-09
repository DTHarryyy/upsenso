class Employee {
  final String id;
  final String businessId;
  final String? userId;
  final String? authUserId;
  final String? email;
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
    this.email,
    required this.fullName,
    this.roleId,
    this.roleName,
    this.branchId,
    this.isActive = true,
    this.createdAt,
  });

  Employee copyWith({
    String? fullName,
    String? email,
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
      email: email ?? this.email,
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
enum EmployeeRole { owner, branchManager, cashier, inventoryStaff }

extension EmployeeRoleX on EmployeeRole {
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

  static EmployeeRole fromRoleName(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'business owner':
      case 'owner':
      case 'super admin':
      case 'superadmin':
        return EmployeeRole.owner;
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
