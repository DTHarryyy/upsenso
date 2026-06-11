import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/profile_field.dart';

/// Central, immutable mapping from a normalised role name to the set of
/// [AppPermission]s that role is allowed to exercise.
///
/// Role names are always in **snake_case** (e.g. `'branch_manager'`).
/// The normalisation is:
///   `roleName.trim().toLowerCase().replaceAll(' ', '_')`
///
/// This is the SINGLE SOURCE OF TRUTH for what each role can do.
/// Never duplicate this logic in BLoCs, repositories, or UI widgets.
///
/// Future roles can be added by simply inserting a new entry in [_matrix].
/// The [PermissionService] will automatically pick them up.
class RolePermissionMatrix {
  RolePermissionMatrix._();

  // ── Role name constants ──────────────────────────────────────────────────
  static const String superAdmin = 'super_admin';
  static const String owner = 'owner';
  static const String businessOwner = 'business_owner';
  static const String branchManager = 'branch_manager';
  static const String cashier = 'cashier';
  static const String inventoryStaff = 'inventory_staff';

  /// Full permission matrix. Immutable at runtime.
  static final Map<String, Set<AppPermission>> _matrix = {
    // ── Business Owner / Super Admin — unrestricted ──────────────────────────
    businessOwner: AppPermission.values.toSet(),
    superAdmin: AppPermission.values.toSet(),
    owner: AppPermission.values.toSet(),

    // ── Branch Manager — operational control over ONE branch ────────────────
    branchManager: {
      // POS oversight
      AppPermission.viewAllSalesInBranch,
      AppPermission.holdSale,
      AppPermission.approveRefund,
      AppPermission.approveVoidTransaction, // maps to pos.approve_void
      AppPermission.voidSale,

      // Shift management
      AppPermission.openShift,
      AppPermission.closeShift,
      AppPermission.viewOwnShiftSummary,
      AppPermission.viewAllShifts,
      AppPermission.overrideShiftClosure,
      AppPermission.resolveCashDiscrepancy,

      // Products (full management within branch)
      AppPermission.viewProducts,
      AppPermission.viewPriceList,
      AppPermission.editProduct,
      AppPermission.changeProductPricing,

      // Inventory (full management within branch)
      AppPermission.viewAvailableStock,
      AppPermission.updateStockQuantity,
      AppPermission.receiveStock,
      AppPermission.recordStockAdjustment,
      AppPermission.approveStockAdjustment,
      AppPermission.transferStockBetweenBranches,
      AppPermission.approveStockTransfer,
      AppPermission.viewStockHistory,

      // Expenses
      AppPermission.createExpense,
      AppPermission.viewExpenses,
      AppPermission.approveExpense,
      AppPermission.rejectExpense,

      // Reports
      AppPermission.viewBranchReports,
      AppPermission.viewSalesAnalytics,
      AppPermission.viewInventoryAnalytics,
      AppPermission.viewInventoryReports,

      // Employees (within branch only)
      AppPermission.createEmployee,
      AppPermission.editEmployee,
      AppPermission.assignRole,
      AppPermission.suspendEmployee,

      // Suppliers
      AppPermission.viewSupplierList,

      // Settings (branch-level)
      AppPermission.accessSettings,
    },

    // ── Cashier — sales operations only ─────────────────────────────────────
    cashier: {
      // POS
      AppPermission.createSale,
      AppPermission.processPayment,
      AppPermission.applyDiscount,
      AppPermission.holdSale,
      AppPermission.printReceipt,
      AppPermission.viewOwnShiftSales,

      // Shift
      AppPermission.openShift,
      AppPermission.closeShift,
      AppPermission.viewOwnShiftSummary,

      // Read-only product & stock access
      AppPermission.viewProducts,
      AppPermission.viewPriceList,
      AppPermission.viewAvailableStock,
    },

    // ── Inventory Staff — stock operations only ──────────────────────────────
    inventoryStaff: {
      // Inventory
      AppPermission.viewAvailableStock,
      AppPermission.updateStockQuantity,
      AppPermission.receiveStock,
      AppPermission.recordStockAdjustment,
      AppPermission.transferStockBetweenBranches,
      AppPermission.viewStockHistory,

      // Read-only product access
      AppPermission.viewProducts,

      // Suppliers (read-only)
      AppPermission.viewSupplierList,

      // Limited reports
      AppPermission.viewInventoryReports,
    },
  };

  /// Returns the [Set<AppPermission>] for [roleKey] (snake_case).
  /// Returns an empty set for any unknown or null role — fail-safe / deny-by-default.
  static Set<AppPermission> permissionsFor(String? roleKey) {
    if (roleKey == null || roleKey.isEmpty) return const {};
    return _matrix[roleKey] ?? const {};
  }

  /// Returns `true` if [roleKey] is granted [permission].
  static bool allows(String? roleKey, AppPermission permission) =>
      permissionsFor(roleKey).contains(permission);

  /// Returns every role that has been granted [permission].
  static List<String> rolesWithPermission(AppPermission permission) {
    return _matrix.entries
        .where((e) => e.value.contains(permission))
        .map((e) => e.key)
        .toList();
  }

  /// Normalises a display-name role string to the snake_case key used in the matrix.
  ///
  /// Examples:
  ///   `'Branch Manager'` → `'branch_manager'`
  ///   `'CASHIER'`        → `'cashier'`
  static String normalise(String? rawRoleName) =>
      (rawRoleName ?? '').trim().toLowerCase().replaceAll(' ', '_');

  // ── Feature access matrix ─────────────────────────────────────────────────
  // Controls which modules / screens a role is allowed to enter.

  static final Map<String, Set<AppFeature>> _featureMatrix = {
    businessOwner: AppFeature.values.toSet(),
    superAdmin: AppFeature.values.toSet(),
    owner: AppFeature.values.toSet(),

    branchManager: {
      AppFeature.posTerminal,
      AppFeature.inventoryManagement,
      AppFeature.expensesModule,
      AppFeature.employeeManagement,
      AppFeature.reportsAnalytics,
      AppFeature.branchConfiguration,
      AppFeature.productsCatalogue,
      AppFeature.supplierDirectory,
      AppFeature.salesHistory,
      // auditLogs intentionally excluded: raw audit log access is
      // restricted to owner / super_admin only.
      AppFeature.profileSettings,
      AppFeature.dashboardManager,
    },

    cashier: {
      AppFeature.posTerminal,
      AppFeature.productsCatalogue, // read-only
      AppFeature.profileSettings,
      AppFeature.dashboardCashier,
    },

    inventoryStaff: {
      AppFeature.inventoryManagement,
      AppFeature.productsCatalogue,
      AppFeature.supplierDirectory,
      AppFeature.profileSettings,
      AppFeature.dashboardInventory,
    },
  };

  /// Returns the [Set<AppFeature>] accessible to [roleKey].
  static Set<AppFeature> featuresFor(String? roleKey) {
    if (roleKey == null || roleKey.isEmpty) return const {};
    return _featureMatrix[roleKey] ?? const {};
  }

  /// Returns `true` if [roleKey] may open [feature].
  static bool canAccessFeature(String? roleKey, AppFeature feature) =>
      featuresFor(roleKey).contains(feature);

  // ── Profile field edit matrix ─────────────────────────────────────────────
  // Controls which profile fields each role may edit ON THEIR OWN PROFILE.
  // Editing another user's profile always requires AppPermission.editEmployee.

  static final Map<String, Set<ProfileField>> _profileFieldMatrix = {
    businessOwner: ProfileField.values.toSet(),
    superAdmin: ProfileField.values.toSet(),
    owner: ProfileField.values.toSet(),

    branchManager: {
      ProfileField.fullName,
      ProfileField.phone,
      ProfileField.profilePicture,
      ProfileField.password,
      // Branch managers may change roles for employees they manage,
      // but NOT their own role or branch assignment.
    },

    cashier: {
      ProfileField.fullName,
      ProfileField.phone,
      ProfileField.profilePicture,
      ProfileField.password,
    },

    inventoryStaff: {
      ProfileField.fullName,
      ProfileField.phone,
      ProfileField.profilePicture,
      ProfileField.password,
    },
  };

  /// Returns the set of profile fields [roleKey] may edit on their own profile.
  static Set<ProfileField> editableProfileFieldsFor(String? roleKey) {
    if (roleKey == null || roleKey.isEmpty) return const {};
    return _profileFieldMatrix[roleKey] ?? const {};
  }

  /// Returns `true` if [roleKey] may edit [field] on their own profile.
  static bool canEditProfileField(String? roleKey, ProfileField field) =>
      editableProfileFieldsFor(roleKey).contains(field);

  // ── Dashboard scope matrix ────────────────────────────────────────────────

  static const Map<String, DashboardScope> _dashboardMatrix = {
    businessOwner: DashboardScope.owner,
    superAdmin: DashboardScope.owner,
    owner: DashboardScope.owner,
    branchManager: DashboardScope.branchManager,
    cashier: DashboardScope.cashier,
    inventoryStaff: DashboardScope.inventoryStaff,
  };

  /// Returns the [DashboardScope] for [roleKey].
  /// Defaults to [DashboardScope.cashier] (most restrictive) for unknown roles.
  static DashboardScope dashboardScopeFor(String? roleKey) {
    if (roleKey == null || roleKey.isEmpty) return DashboardScope.cashier;
    return _dashboardMatrix[roleKey] ?? DashboardScope.cashier;
  }

  // ── Data scope matrix ─────────────────────────────────────────────────────
  // Returns the DataScopeType for each role.
  // The actual DataScope (with branchId / userId filled in) is constructed
  // at runtime by PermissionService using the live auth context.

  static DataScopeType dataScopeTypeFor(String? roleKey) {
    switch (roleKey) {
      case businessOwner:
      case superAdmin:
      case owner:
        return DataScopeType.allBranches;
      case branchManager:
      case inventoryStaff:
        return DataScopeType.branchOnly;
      case cashier:
        return DataScopeType.ownOnly;
      default:
        return DataScopeType.ownOnly; // deny-by-default for unknown roles
    }
  }
}
