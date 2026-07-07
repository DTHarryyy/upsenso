import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_key.dart';
import 'package:pos/core/config/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/ai_assistant/pages/ai_chat_page.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/services/ai_pipeline.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/sign_in.dart';
import 'package:pos/features/auth/presentation/sign_up.dart';
import 'package:pos/features/auth/presentation/verification_page.dart';
import 'package:pos/features/auth/presentation/forgot_password_page.dart';
import 'package:pos/features/auth/presentation/reset_password_verification_page.dart';
import 'package:pos/features/auth/presentation/reset_password_page.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/features/business/presentation/business_profile_page.dart';
import 'package:pos/features/business/presentation/business_profile_setup.dart';
import 'package:pos/features/home/presentation/main_navigation_page.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:pos/features/pos/presentation/pos_terminal_page.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/pages/add_products.dart';
import 'package:pos/features/products/products_page.dart';
import 'package:pos/features/profile/presentation/profile_page.dart';
import 'package:pos/features/expenses/presentation/expenses_page.dart';
import 'package:pos/features/sales/presentation/sales_history.dart';
import 'package:pos/features/settings/presentation/receipt_settings_page.dart';
import 'package:pos/features/settings/presentation/settings_shell_page.dart';
import 'package:pos/features/dashboard/presentation/dashboard_page.dart';
import 'package:pos/features/reports/presentation/pages/reports_and_analytics.dart';
import 'package:pos/features/notifications/presentation/pages/notifications_page.dart';
import 'package:pos/features/alert/presentation/alert_page.dart';
import 'package:pos/features/audit_logs/presentation/pages/audit_log_page.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/pages/employees_page.dart';
import 'package:pos/features/employees/presentation/pages/employee_permissions_page.dart';
import 'package:pos/features/settings/presentation/module_settings_page.dart';
import 'package:pos/features/settings/presentation/refund_approval_settings_page.dart';
import 'package:pos/features/settings/presentation/manager_pin_page.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';
import 'package:pos/features/procurement/presentation/pages/po_detail_page.dart';
import 'package:pos/features/procurement/presentation/pages/po_form_page.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/presentation/pages/purchase_orders_page.dart';
import 'package:pos/features/procurement/presentation/pages/supplier_detail_page.dart';
import 'package:pos/features/procurement/presentation/pages/suppliers_page.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_detail_cubit.dart';
import 'package:pos/features/crm/presentation/pages/customers_page.dart';
import 'package:pos/features/crm/presentation/pages/customer_detail_page.dart';
import 'package:pos/features/recipes/presentation/pages/ingredients_page.dart';
import 'package:pos/features/onboarding/onboarding.dart';
import 'package:pos/features/pos/presentation/pages/receipt_preview_page.dart';
import 'package:pos/features/pos/data/models/cart_model.dart' show CartItem;

class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,

    // Re-run guards on auth changes AND module-gate changes, so disabling a
    // module (offline toggle or background sync) redirects users off a now-
    // disabled page and refreshes the shell nav without a manual navigation.
    // Entitlement changes (plan upgrade/lapse arriving via background sync)
    // re-run guards the same way.
    refreshListenable: Listenable.merge([
      _AuthRefreshNotifier(sl<AuthBloc>().stream),
      sl<PermissionService>().moduleGateRevision,
      sl<EntitlementService>().entitlementRevision,
    ]),

    onException: (_, state, router) => router.go(AppRoutes.signIn),

    redirect: (context, state) async {
      final location = state.matchedLocation;

      final goingToOnboarding = location == AppRoutes.onboarding;
      final goingToSignIn = location == AppRoutes.signIn;
      final goingToSignUp = location == AppRoutes.signUp;
      final goingToVerification = location == AppRoutes.verification;
      final goingToForgotPassword = location == AppRoutes.forgotPassword;
      final goingToResetVerification = location.startsWith(
        AppRoutes.resetPasswordVerification,
      );
      final goingToResetPassword = location.startsWith(AppRoutes.resetPassword);
      final goingToBusinessProfileSetup =
          location == AppRoutes.businessProfileSetup;
      final isPublicAuthRoute =
          goingToSignIn || goingToSignUp || goingToVerification;
      final isPasswordResetRoute =
          goingToForgotPassword ||
          goingToResetVerification ||
          goingToResetPassword;
      final isAuthRoute = isPublicAuthRoute || isPasswordResetRoute;

      final prefs = sl<SharedPreferences>();
      final seen = kIsWeb || (prefs.getBool(AppKey.seenOnboarding) ?? false);

      if (!seen) {
        if (!goingToOnboarding) return AppRoutes.onboarding;
        return null;
      }

      final authBloc = sl<AuthBloc>();
      final authState = authBloc.state;

      if (authState is AuthUnauthenticated) {
        if (goingToOnboarding || !isAuthRoute) return AppRoutes.signIn;
        return null;
      }

      if (authState is! AuthAuthenticated) return null;

      final user = authState.user;
      final hasBusiness = (user.businessId?.trim() ?? '').isNotEmpty;

      // Normalise role using the same algorithm as RolePermissionMatrix so
      // comparisons are always against typed constants (never raw strings).
      final roleKey = RolePermissionMatrix.normalise(user.roleName);
      final isEmployee = {
        RolePermissionMatrix.cashier,
        RolePermissionMatrix.inventoryStaff,
        RolePermissionMatrix.owner,
        RolePermissionMatrix.branchManager,
      }.contains(roleKey);

      if (!hasBusiness &&
          !isEmployee &&
          !goingToBusinessProfileSetup &&
          !isPasswordResetRoute) {
        return AppRoutes.businessProfileSetup;
      }

      // Determine the role-appropriate home route.
      // All roles land on the dashboard — the dashboard itself is scoped per
      // role via DashboardScope so cashiers see personal KPIs and inventory
      // staff see stock health KPIs, not financial analytics.
      String roleHome() => AppRoutes.dashboard;

      if (hasBusiness &&
          (goingToOnboarding ||
              isPublicAuthRoute ||
              goingToBusinessProfileSetup)) {
        return roleHome();
      }

      // Feature-based route guard using PermissionKeys string constants.
      // Each route maps to a navigation permission key. Unauthorised users
      // are redirected to the dashboard rather than seeing a blank screen.
      if (!isPasswordResetRoute) {
        const routePermissionGuards = <String, String>{
          AppRoutes.products: PermissionKeys.productsView,
          AppRoutes.posTerminal: PermissionKeys.navPos,
          AppRoutes.reports: PermissionKeys.navReports,
          AppRoutes.inventory: PermissionKeys.navInventory,
          AppRoutes.stockLevel: PermissionKeys.navInventory,
          AppRoutes.expenses: PermissionKeys.navExpenses,
          AppRoutes.saleshistory: PermissionKeys.navSalesHistory,
          AppRoutes.heldSales: PermissionKeys.navHeldSales,
          AppRoutes.employees: PermissionKeys.navEmployees,
          AppRoutes.auditLogs: PermissionKeys.navAuditLogs,
          AppRoutes.settings: PermissionKeys.navSettings,
          AppRoutes.receiptSettings: PermissionKeys.navSettings,
          AppRoutes.moduleSettings: PermissionKeys.settingsEditBusiness,
          AppRoutes.refundApprovalSettings: PermissionKeys.settingsEditBusiness,
          AppRoutes.managerPin: PermissionKeys.navSettings,
          AppRoutes.employeePermissions: PermissionKeys.navEmployees,
          AppRoutes.suppliers: PermissionKeys.navProcurement,
          AppRoutes.supplierDetail: PermissionKeys.navProcurement,
          AppRoutes.purchaseOrders: PermissionKeys.navProcurement,
          // Form is create/edit only — gate on create, not the view-level nav key.
          AppRoutes.poForm: PermissionKeys.procurementCreatePo,
          AppRoutes.poDetail: PermissionKeys.navProcurement,
          AppRoutes.ingredients: PermissionKeys.navRecipes,
          AppRoutes.customers: PermissionKeys.navCustomers,
          AppRoutes.customerDetail: PermissionKeys.navCustomers,
          AppRoutes.fraud: PermissionKeys.navFraud,
        };
        final requiredKey = routePermissionGuards[location];
        if (requiredKey != null && !sl<PermissionService>().can(requiredKey)) {
          return AppRoutes.dashboard;
        }

        // Module guards — redirect to dashboard when a module is disabled,
        // even if the user has the role permission for it.
        const routeModuleGuards = <String, String>{
          AppRoutes.posTerminal: 'pos',
          AppRoutes.reports: 'reports',
          AppRoutes.inventory: 'inventory',
          AppRoutes.stockLevel: 'inventory',
          AppRoutes.expenses: 'expenses',
          AppRoutes.saleshistory: 'pos',
          AppRoutes.heldSales: 'pos',
          AppRoutes.employees: 'employees',
          AppRoutes.employeePermissions: 'employees',
          AppRoutes.auditLogs: 'audit',
          AppRoutes.suppliers: 'procurement',
          AppRoutes.supplierDetail: 'procurement',
          AppRoutes.purchaseOrders: 'procurement',
          AppRoutes.poForm: 'procurement',
          AppRoutes.poDetail: 'procurement',
          AppRoutes.ingredients: 'ingredients',
          AppRoutes.customers: 'crm',
          AppRoutes.fraud: 'audit',
          AppRoutes.customerDetail: 'crm',
        };
        final requiredModule = routeModuleGuards[location];
        if (requiredModule != null &&
            !sl<PermissionService>().isModuleEnabled(requiredModule)) {
          return AppRoutes.dashboard;
        }

        // Plan-entitlement guards (M7.1 §7): a tier that doesn't include the
        // feature redirects to the dashboard, where the locked-module tile
        // offers the upgrade — never a dead end mid-sale.
        const routeEntitlementGuards = <String, AppFeature>{
          AppRoutes.customers: AppFeature.customerDirectory,
          AppRoutes.customerDetail: AppFeature.customerDirectory,
          AppRoutes.suppliers: AppFeature.supplierDirectory,
          AppRoutes.supplierDetail: AppFeature.supplierDirectory,
          AppRoutes.purchaseOrders: AppFeature.procurement,
          AppRoutes.poForm: AppFeature.procurement,
          AppRoutes.poDetail: AppFeature.procurement,
        };
        final requiredFeature = routeEntitlementGuards[location];
        if (requiredFeature != null &&
            !sl<EntitlementService>().featureAllowed(requiredFeature)) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },

    routes: [
      // ── Auth & misc routes ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const Onboarding(),
      ),
      GoRoute(path: AppRoutes.signIn, builder: (context, _) => const SignIn()),
      GoRoute(path: AppRoutes.signUp, builder: (context, _) => const SignUp()),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.businessProfile,
        builder: (context, _) => const BusinessProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.businessProfileSetup,
        builder: (context, _) => BlocProvider(
          create: (_) => sl<BusinessBloc>(),
          child: const BusinessProfileSetup(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, _) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.receiptSettings,
        builder: (context, _) => const ReceiptSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.moduleSettings,
        builder: (context, state) {
          final businessId = state.extra as String? ?? '';
          return ModuleSettingsPage(businessId: businessId);
        },
      ),
      GoRoute(
        path: AppRoutes.refundApprovalSettings,
        builder: (context, _) => const RefundApprovalSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.managerPin,
        builder: (context, state) =>
            ManagerPinPage(targetEmployee: state.extra as Employee?),
      ),
      GoRoute(
        path: AppRoutes.employeePermissions,
        builder: (context, state) {
          final employee = state.extra as Employee;
          return EmployeePermissionsPage(employee: employee);
        },
      ),
      GoRoute(
        path: AppRoutes.ingredients,
        builder: (context, _) => const IngredientsPage(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (context, state) =>
            AddProductsPage(initialBarcode: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        builder: (context, state) =>
            AddProductsPage(productToEdit: state.extra as Product?),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.receiptPreview,
        builder: (context, state) {
          final args = state.extra as ReceiptPreviewArgs;
          return ReceiptPreviewPage(
            transactionId: args.transactionId,
            invoiceNumber: args.invoiceNumber,
            items: args.items,
            subtotal: args.subtotal,
            taxAmount: args.taxAmount,
            discountAmount: args.discountAmount,
            total: args.total,
            amountReceived: args.amountReceived,
            change: args.change,
            paymentMethod: args.paymentMethod,
            cashierName: args.cashierName,
            customerName: args.customerName,
            dateTime: args.dateTime,
            businessId: args.businessId,
            branchName: args.branchName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, _) {
          final authRepo = sl<AuthRepository>();
          final currentUser = authRepo.getCurrentUser();
          final branchCubit = context.read<BranchCubit>();
          return BlocProvider(
            create: (_) => AiChatBloc(
              pipeline: sl<AiPipeline>(),
              downloadService: sl<ModelDownloadService>(),
              modelManager: sl<ModelManager>(),
              businessId: currentUser?.businessId ?? '',
              cashierId: currentUser?.id ?? '',
              selectedBranchId: () =>
                  branchCubit.getSelectedBranchIdForFiltering(),
            ),
            child: const AiChatPage(),
          );
        },
      ),

      // ── Shell: tab routes each get their own URL ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, _, navigationShell) =>
            MainNavigationPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, _) => DashboardPage(
                  onNewSale: () => context.go(AppRoutes.posTerminal),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, _) => const ProductsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.posTerminal,
                builder: (context, _) => PosTerminalPage(
                  isActive: true,
                  onClose: () => context.go(AppRoutes.dashboard),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, _) => const ReportsAndAnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inventory,
                builder: (context, _) => const Inventory(),
              ),
            ],
          ),

          // ── Branch 5: Sales History ──────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saleshistory,
                builder: (context, _) => const SalesHistory(),
              ),
            ],
          ),

          // ── Branch 6: Expenses ───────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.expenses,
                builder: (context, _) => const ExpensesPage(),
              ),
            ],
          ),

          // ── Branch 7: Settings (inline sub-module shell) ─────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, _) => const SettingsShellPage(),
              ),
            ],
          ),

          // ── Branch 8: Audit Logs ──────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.auditLogs,
                builder: (context, _) => const AuditLogPage(),
              ),
            ],
          ),
          // ── Branch 9: Employees ───────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.employees,
                builder: (context, _) => const EmployeesPage(),
              ),
            ],
          ),

          // ── Branch 10: Suppliers ─────────────────────────────────────────
          // Nested as a shell branch so the sidebar and top bar remain visible
          // on tablet/desktop when browsing the supplier directory and details.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.suppliers,
                builder: (context, _) {
                  final businessId = _activeBusinessId();
                  return BlocProvider(
                    create: (_) => SupplierCubit(
                      repository: sl<IProcurementRepository>(),
                      permissions: sl<PermissionService>(),
                      businessId: businessId,
                    )..watch(),
                    child: const SuppliersPage(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final businessId = _activeBusinessId();
                      final supplier = state.extra as Supplier;
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (_) => SupplierCubit(
                              repository: sl<IProcurementRepository>(),
                              permissions: sl<PermissionService>(),
                              businessId: businessId,
                            )..watch(),
                          ),
                          BlocProvider(
                            create: (_) => PoCubit(
                              repository: sl<IProcurementRepository>(),
                              permissions: sl<PermissionService>(),
                              businessId: businessId,
                              userId: _activeUserId(),
                              userName: _activeUserName(),
                              branchId: _activeBranchId(context),
                            )..watch(),
                          ),
                        ],
                        child: SupplierDetailPage(supplier: supplier),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 11: Purchase Orders ───────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.purchaseOrders,
                builder: (context, _) {
                  return BlocProvider(
                    create: (_) => PoCubit(
                      repository: sl<IProcurementRepository>(),
                      permissions: sl<PermissionService>(),
                      businessId: _activeBusinessId(),
                      userId: _activeUserId(),
                      userName: _activeUserName(),
                      branchId: _activeBranchId(context),
                    )..watch(),
                    child: const PurchaseOrdersPage(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (context, state) {
                      final businessId = _activeBusinessId();
                      // Extra is a PurchaseOrder when editing, or a Supplier
                      // when pre-filling a new PO for that supplier.
                      final extra = state.extra;
                      final po = extra is PurchaseOrder ? extra : null;
                      final initialSupplier =
                          extra is Supplier ? extra : null;
                      return BlocProvider(
                        create: (_) => PoCubit(
                          repository: sl<IProcurementRepository>(),
                          permissions: sl<PermissionService>(),
                          businessId: businessId,
                          userId: _activeUserId(),
                          userName: _activeUserName(),
                          branchId: _activeBranchId(context),
                        )..watch(),
                        child: PoFormPage(
                          po: po,
                          initialSupplier: initialSupplier,
                          businessId: businessId,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final poId = state.extra as String;
                      return BlocProvider(
                        create: (_) => PoCubit(
                          repository: sl<IProcurementRepository>(),
                          permissions: sl<PermissionService>(),
                          businessId: _activeBusinessId(),
                          userId: _activeUserId(),
                          userName: _activeUserName(),
                          branchId: _activeBranchId(context),
                        )..watch(),
                        child: PoDetailPage(poId: poId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 12: Customers (CRM) ───────────────────────────────────
          // Nested as a shell branch so the sidebar/top bar stay visible on
          // tablet/desktop; on mobile it's pushed from the More drawer.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customers,
                builder: (context, _) {
                  return BlocProvider(
                    create: (_) => CustomerCubit(
                      repository: sl<ICustomerRepository>(),
                      permissions: sl<PermissionService>(),
                      businessId: _activeBusinessId(),
                    )..watch(),
                    child: const CustomersPage(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final businessId = _activeBusinessId();
                      final customer = state.extra as Customer;
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (_) => CustomerCubit(
                              repository: sl<ICustomerRepository>(),
                              permissions: sl<PermissionService>(),
                              businessId: businessId,
                            )..watch(),
                          ),
                          BlocProvider(
                            create: (_) => CustomerDetailCubit(
                              repository: sl<ICustomerRepository>(),
                              businessId: businessId,
                              customerId: customer.id,
                            )..watch(),
                          ),
                        ],
                        child: CustomerDetailPage(customer: customer),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 13: Fraud & Risk alerts ───────────────────────────────
          // UI gate only (nav.fraud + audit module) — the detection engine
          // runs regardless of this route's visibility.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fraud,
                builder: (context, _) => const AlertPage(),
              ),
            ],
          ),
        ],
      ),

      // Root path redirect — visiting the bare domain (/) has no matching
      // route so GoRouter would fall through to onException (→ /login).
      // Redirect it cleanly to /dashboard and let the auth guard sort out
      // whether the user needs to sign in first.
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.dashboard),

      // Keep /home redirect for any saved links or old references
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.dashboard,
      ),
    ],
  );

  // Tenant identity for procurement routes must come from the active session
  // (ActiveBusinessContext), not a freshly-fetched user that may not be hydrated
  // yet — an empty businessId silently queries the wrong (empty) tenant.
  // getCurrentUser() is only a fallback for fields the session doesn't carry.
  static String _activeBusinessId() {
    final active = sl<ActiveBusinessContext>();
    if (active.hasBusiness) return active.businessId!;
    return sl<AuthRepository>().getCurrentUser()?.businessId ?? '';
  }

  static String _activeUserId() {
    final active = sl<ActiveBusinessContext>();
    return active.userId ?? sl<AuthRepository>().getCurrentUser()?.id ?? '';
  }

  static String _activeUserName() {
    final active = sl<ActiveBusinessContext>();
    return active.fullName ??
        sl<AuthRepository>().getCurrentUser()?.fullName ??
        '';
  }

  // Operating branch a new PO is tagged with: the user's currently-selected
  // branch, falling back to the session branch. Captured at PO creation so
  // received stock lands in the correct branch (never an empty branch id).
  static String? _activeBranchId(BuildContext context) {
    final selected = context.read<BranchCubit>().state.selectedBranchId;
    if (selected != null && selected.trim().isNotEmpty) return selected;
    return sl<ActiveBusinessContext>().branchId;
  }
}

class ReceiptPreviewArgs {
  final String transactionId;
  final String invoiceNumber;
  final List<CartItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double amountReceived;
  final double change;
  final String paymentMethod;
  final String cashierName;
  final String customerName;
  final DateTime dateTime;
  final String businessId;
  final String? branchName;

  const ReceiptPreviewArgs({
    required this.transactionId,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.amountReceived,
    required this.change,
    required this.paymentMethod,
    required this.cashierName,
    required this.customerName,
    required this.dateTime,
    required this.businessId,
    this.branchName,
  });
}
