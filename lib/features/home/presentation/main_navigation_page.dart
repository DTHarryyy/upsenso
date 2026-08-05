import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/app_router.dart' show lockedFeatureParam;
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/const/nav_feature_flags.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/feature_plan_requirement.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/ui/widgets/app_bottom_nav.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/core/widgets/plan_badge.dart';
import 'package:pos/core/widgets/plan_enforcement_banners.dart';
import 'package:pos/core/widgets/plan_lock_badge.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/more/presentation/more_page.dart';
import 'package:pos/features/notifications/domain/billing_notice_service.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

const double _kSidebarExpanded = 200;
const double _kSidebarCollapsed = 60;

class MainNavigationPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationPage({super.key, required this.navigationShell});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Keeps the shell's element (and all page-local state — view-mode toggles,
  // scroll offsets, form input) alive when the layout flips between the phone
  // and tablet trees on a resize across 600 px. Without it, crossing the
  // breakpoint reparents the shell and wipes that state.
  final _shellKey = GlobalKey();
  // Initialised in didChangeDependencies so we can read the screen width.
  // Desktop (≥1024 px) → expanded; tablet (600–1023 px) → collapsed icons.
  bool _sidebarExpanded = true;
  bool _sidebarInitialized = false;
  String? _lastUserContextKey;
  bool _syncInitialized = false;
  String? _lockedFeatureShown;

  int get _currentIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _syncInitialized) return;
      _syncInitialized = true;
      sl<SyncService>().init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sidebarInitialized) {
      _sidebarInitialized = true;
      // Desktop (≥1024 px): expanded sidebar is comfortable.
      // Tablet (600–1023 px): collapsed so content gets maximum width.
      _sidebarExpanded = Breakpoints.isDesktop(context);
    }
  }

  void _onNavTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == _currentIndex,
    );
  }

  /// The router bounced a plan-locked route here. Explain it once, then strip
  /// the marker so a rebuild or a back-navigation doesn't re-open the sheet.
  void _consumeLockedFeature(String raw) {
    if (_lockedFeatureShown == raw) return;
    _lockedFeatureShown = raw;
    final feature = AppFeature.values.where((f) => f.name == raw).firstOrNull;
    if (feature == null) return;
    final plan = requiredPlanFor(feature);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showUpgradePrompt(
        context,
        UpgradeMoment.lockedModule,
        requiredPlan: plan,
        detail:
            'Upgrade to turn on ${feature.displayLabel} — your current work is '
            'never blocked.',
      );
    });
  }

  void _scheduleBranchLoad(AppUser user) {
    final key =
        '${user.id}|${user.businessId ?? ''}|${user.roleName ?? ''}|${user.branchId ?? ''}|${user.branchName ?? ''}';
    if (_lastUserContextKey == key) return;
    _lastUserContextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BranchCubit>().loadBranchesForUser(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        // Rebuild when the user's display/role context improves so the
        // sidebar and app bar reflect fresh data without a full restart.
        if (prev is AuthAuthenticated && curr is AuthAuthenticated) {
          return prev.user.businessId != curr.user.businessId ||
              prev.user.businessName != curr.user.businessName ||
              prev.user.roleName != curr.user.roleName ||
              prev.user.branchId != curr.user.branchId ||
              prev.user.fullName != curr.user.fullName ||
              prev.user.avatarUrl != curr.user.avatarUrl;
        }
        return false;
      },
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _scheduleBranchLoad(authState.user);

        final userId = authState.user.id;
        final userAvatar = authState.user.avatarUrl;
        final userName =
            authState.user.fullName ?? authState.user.email ?? 'User';
        final roleName = displayRoleName(authState.user.roleName?.trim());
        final roleId = authState.user.roleId?.trim();
        final userRole = (roleName != null && roleName.isNotEmpty)
            ? roleName
            : (roleId != null && roleId.isNotEmpty)
            ? roleId
            : 'Syncing role...';
        final businessName = authState.user.businessName ?? 'Business';
        final branchName =
            authState.user.branchName ??
            authState.user.businessName ??
            'Branch';
        final userEmail = authState.user.email ?? 'N/A';

        return BlocBuilder<BranchCubit, BranchState>(
          builder: (context, branchState) {
            final visibleBranches = branchState.availableBranches.isNotEmpty
                ? branchState.availableBranches
                : [branchName];
            final selectedBranch = branchState.selectedBranch ?? branchName;

            final isTablet = Breakpoints.isTablet(context);
            final isPosTab = _currentIndex == 2;
            // Procurement pages own their AppSubPageBar on mobile. They're
            // reached via context.push (drawer) which stacks them on the
            // active branch's navigator without changing currentIndex — so we
            // detect them by location, not branch index, to drop shell chrome.
            final routerState = GoRouterState.of(context);
            final lockedFeature =
                routerState.uri.queryParameters[lockedFeatureParam];
            if (lockedFeature != null) _consumeLockedFeature(lockedFeature);

            final location = routerState.uri.path;
            final isStackedSubPage =
                location.startsWith(AppRoutes.suppliers) ||
                location.startsWith(AppRoutes.purchaseOrders) ||
                location.startsWith(AppRoutes.customers) ||
                location.startsWith(AppRoutes.fraud) ||
                location == AppRoutes.settings;

            // GoRouter's StatefulNavigationShell manages the page stack.
            // A GlobalKey preserves the whole page subtree's state when the
            // phone/tablet layout swap moves it to a different tree position.
            final shell = KeyedSubtree(
              key: _shellKey,
              child: widget.navigationShell,
            );

            return _NotificationsBadgeProvider(
              businessId: authState.user.businessId,
              builder: (unreadCount, onNotificationTapped) {
                if (isTablet) {
                  return _SyncStatusProvider(
                    builder: (isOnline, pendingSyncCount) => Scaffold(
                      body: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1980),
                          child: Row(
                            children: [
                              // ── Sidebar ──────────────────────────────────────
                              if (!isPosTab)
                                _AppSidebar(
                                  expanded: _sidebarExpanded,
                                  currentIndex: _currentIndex,
                                  onNavTap: _onNavTap,
                                  onToggle: () => setState(
                                    () => _sidebarExpanded = !_sidebarExpanded,
                                  ),
                                  userName: userName,
                                  userRole: userRole,
                                  userEmail: userEmail,
                                  userAvatar: userAvatar,
                                  businessName: businessName,
                                  businessId: authState.user.businessId,
                                  isOnline: isOnline,
                                  pendingSyncCount: pendingSyncCount,
                                  branches: visibleBranches,
                                  selectedBranch: selectedBranch,
                                  canSwitchBranches:
                                      branchState.canSwitchBranches,
                                ),

                              // ── Right column: top bar + page content ───────
                              Expanded(
                                child: Column(
                                  children: [
                                    // Shared top bar — same component as
                                    // mobile so branch selector, sync status,
                                    // and user section are always consistent
                                    // across breakpoints.
                                    if (!isPosTab)
                                      CustomAppBar(
                                        branches: visibleBranches,
                                        selectedBranch: selectedBranch,
                                        onBranchChanged:
                                            branchState.canSwitchBranches
                                            ? (branch) => context
                                                  .read<BranchCubit>()
                                                  .selectBranch(branch)
                                            : null,
                                        userName: userName,
                                        userRole: userRole,
                                        userEmail: userEmail,
                                        userId: userId,
                                        userAvatar: userAvatar,
                                        businessName: businessName,
                                        isOnline: isOnline,
                                        pendingSyncCount: pendingSyncCount,
                                        notificationCount: unreadCount,
                                        onNotificationTapped:
                                            onNotificationTapped,
                                        showThemeToggle: false,
                                      ),

                                    // Collapses to nothing on a healthy plan.
                                    if (!isPosTab)
                                      const PlanEnforcementBanners(),

                                    // Page content.  We override AppBarTheme
                                    // with toolbarHeight: 0 so any per-page
                                    // AppBar that individual pages declare
                                    // occupies no space and is visually
                                    // hidden — the top bar above provides all
                                    // the chrome the user needs on desktop.
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          appBarTheme: Theme.of(context)
                                              .appBarTheme
                                              .copyWith(
                                                toolbarHeight: 0,
                                                elevation: 0,
                                                scrolledUnderElevation: 0,
                                                backgroundColor:
                                                    Colors.transparent,
                                                surfaceTintColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                              ),
                                        ),
                                        child: shell,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return _SyncStatusProvider(
                  builder: (isOnline, pendingSyncCount) => Scaffold(
                    key: _scaffoldKey,
                    // The nav is an opaque strip now — content stops above it
                    // instead of scrolling underneath and getting hidden.
                    extendBody: false,
                    drawer: const Drawer(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: MorePage(),
                    ),
                    appBar: (isPosTab || isStackedSubPage)
                        ? null
                        : CustomAppBar(
                            branches: visibleBranches,
                            selectedBranch: selectedBranch,
                            onBranchChanged: branchState.canSwitchBranches
                                ? (branch) => context
                                      .read<BranchCubit>()
                                      .selectBranch(branch)
                                : null,
                            userName: userName,
                            userRole: userRole,
                            userEmail: userEmail,
                            userId: userId,
                            userAvatar: userAvatar,
                            businessName: businessName,
                            isOnline: isOnline,
                            pendingSyncCount: pendingSyncCount,
                            notificationCount: unreadCount,
                            onNotificationTapped: onNotificationTapped,
                            onMenuTapped: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            showThemeToggle: false,
                          ),
                    body: (isPosTab || isStackedSubPage)
                        ? shell
                        // Collapses to nothing on a healthy plan. Kept off the
                        // POS tab: nothing may push the till around mid-sale.
                        : Column(
                            children: [
                              const PlanEnforcementBanners(),
                              Expanded(child: shell),
                            ],
                          ),
                    // AI assistant floats over every bottom-bar page (native
                    // runs the on-device model, web falls back to the
                    // rule-based parser). Hidden on the POS terminal and
                    // full-screen stacked sub-pages, which own their chrome
                    // and have no bottom bar.
                    floatingActionButton:
                        (!kShowAiAndFraudNav || isPosTab || isStackedSubPage)
                        ? null
                        : FloatingActionButton(
                            heroTag: 'aiAssistantFab',
                            onPressed: () => context.push(AppRoutes.aiChat),
                            backgroundColor: AppColors.surface,
                            shape: const CircleBorder(),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                    bottomNavigationBar: (isPosTab || isStackedSubPage)
                        ? null
                        : AppBottomNav(
                            currentIndex: _currentIndex,
                            onTap: _onNavTap,
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SyncStatusProvider extends StatefulWidget {
  final Widget Function(bool isOnline, int pendingSyncCount) builder;

  const _SyncStatusProvider({required this.builder});

  @override
  State<_SyncStatusProvider> createState() => _SyncStatusProviderState();
}

class _SyncStatusProviderState extends State<_SyncStatusProvider> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<int>? _syncCountSub;
  StreamSubscription<bool>? _connectivitySub;
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _connectivityService = sl<ConnectivityService>();

    _connectivityService.isConnected.then((v) {
      if (mounted && _isOnline != v) setState(() => _isOnline = v);
    });

    _connectivitySub = _connectivityService.onConnectivityChanged.listen((v) {
      if (mounted && _isOnline != v) setState(() => _isOnline = v);
    });

    _syncCountSub = sl<SyncService>().watchTotalPendingSyncCount().listen((
      count,
    ) {
      if (mounted && _pendingSyncCount != count) {
        setState(() => _pendingSyncCount = count);
      }
    });
  }

  @override
  void dispose() {
    _syncCountSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_isOnline, _pendingSyncCount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification bell badge — live unread count for the shell app bar: real
// unread rows from the repository, plus the synthetic billing notice when one
// is due. BillingNoticeService owns that rule so this and NotificationsCubit
// can't drift apart on when a notice counts.
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsBadgeProvider extends StatefulWidget {
  final String? businessId;
  final Widget Function(int unreadCount, VoidCallback onNotificationTapped)
  builder;

  const _NotificationsBadgeProvider({
    required this.businessId,
    required this.builder,
  });

  @override
  State<_NotificationsBadgeProvider> createState() =>
      _NotificationsBadgeProviderState();
}

class _NotificationsBadgeProviderState
    extends State<_NotificationsBadgeProvider> {
  late final INotificationsRepository _repository;
  late final BillingNoticeService _notices;
  List<NotificationItem> _items = const [];
  VoidCallback? _unsubscribe;
  BillingNoticeKind? _notice;

  @override
  void initState() {
    super.initState();
    _repository = sl<INotificationsRepository>();
    _notices = sl<BillingNoticeService>();
    _notices.revision.addListener(_onNoticesChanged);
    _refreshNotice();
    _load();
  }

  Future<void> _openNotifications() async {
    await context.push(AppRoutes.notifications);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_NotificationsBadgeProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.businessId != oldWidget.businessId) {
      _unsubscribe?.call();
      _unsubscribe = null;
      _items = const [];
      _refreshNotice();
      _load();
    }
  }

  void _onNoticesChanged() {
    final businessId = widget.businessId;
    if (businessId != null) unawaited(_notices.reArm(businessId));
    _refreshNotice();
  }

  void _refreshNotice() {
    final businessId = widget.businessId;
    final next = businessId == null ? null : _notices.visibleKind(businessId);
    if (next == _notice) return;
    if (mounted) {
      setState(() => _notice = next);
    } else {
      _notice = next; // initState — no element to mark dirty yet
    }
  }

  Future<void> _load() async {
    final businessId = widget.businessId;
    if (businessId == null) return;
    try {
      final items = await _repository.fetchAll(businessId);
      if (!mounted) return;
      setState(() => _items = items);
      _subscribe(businessId);
    } catch (e, st) {
      debugPrint('[NotificationsBadge] Error in _load: $e\n$st');
    }
  }

  void _subscribe(String businessId) {
    _unsubscribe?.call();
    _unsubscribe = _repository.subscribe(
      businessId: businessId,
      onInsert: (item) {
        if (!mounted) return;
        setState(() => _items = [item, ..._items]);
      },
      onUpdate: (item) {
        if (!mounted) return;
        setState(
          () => _items = _items.map((n) => n.id == item.id ? item : n).toList(),
        );
      },
      onDelete: (id) {
        if (!mounted) return;
        setState(() => _items = _items.where((n) => n.id != id).toList());
      },
    );
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _notices.revision.removeListener(_onNoticesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbUnread = _items.where((n) => !n.isRead).length;
    return widget.builder(
      dbUnread + (_notice != null ? 1 : 0),
      _openNotifications,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _AppSidebar extends StatefulWidget {
  final bool expanded;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onToggle;
  final String userName;
  final String userRole;
  final String userEmail;
  final String? userAvatar;
  final String businessName;
  final String? businessId;
  final bool isOnline;
  final int pendingSyncCount;
  final List<String> branches;
  final String selectedBranch;
  final bool canSwitchBranches;

  const _AppSidebar({
    required this.expanded,
    required this.currentIndex,
    required this.onNavTap,
    required this.onToggle,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.userAvatar,
    required this.businessName,
    this.businessId,
    required this.isOnline,
    required this.pendingSyncCount,
    required this.branches,
    required this.selectedBranch,
    required this.canSwitchBranches,
  });

  @override
  State<_AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<_AppSidebar> {
  // Unified business logo — watched from the local receipt_settings row so it
  // shows offline (including a freshly-picked logo before it's uploaded).
  String? _businessLogoUrl;
  String? _businessLogoLocalPath;
  StreamSubscription<ReceiptSettings?>? _logoSub;

  // Tracks the layout mode separately from widget.expanded.
  // On expand: waits for the animation to finish before switching content.
  // On collapse: switches content immediately so icons show during animation.
  bool _layoutExpanded = false;

  @override
  void initState() {
    super.initState();
    _layoutExpanded = widget.expanded;
    if (widget.businessId != null) _watchBusinessLogo(widget.businessId!);
  }

  @override
  void didUpdateWidget(_AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.businessId != oldWidget.businessId &&
        widget.businessId != null) {
      _watchBusinessLogo(widget.businessId!);
    }
    if (widget.expanded != oldWidget.expanded) {
      if (!widget.expanded) {
        // Collapsing: switch content immediately.
        setState(() => _layoutExpanded = false);
      } else {
        // Expanding: wait for the container animation to finish.
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) setState(() => _layoutExpanded = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _logoSub?.cancel();
    super.dispose();
  }

  // Watch the unified logo from the local receipt_settings row: a local file
  // shows instantly (even offline / before upload), otherwise the public URL.
  void _watchBusinessLogo(String businessId) {
    _logoSub?.cancel();
    _logoSub = sl<ReceiptSettingsRepository>().watch(businessId).listen((s) {
      if (!mounted) return;
      setState(() {
        _businessLogoLocalPath = (s?.logoLocalPath.isNotEmpty ?? false)
            ? s!.logoLocalPath
            : null;
        _businessLogoUrl = (s?.logoUrl.isNotEmpty ?? false) ? s!.logoUrl : null;
      });
    });
  }

  // ── Feature-based visibility helpers — no hardcoded role strings ──────────
  PermissionService get _permService => sl<PermissionService>();
  bool get _sidebarShowDashboard => true;
  bool get _sidebarShowPos =>
      _permService.can(PermissionKeys.navPos) &&
      _permService.isModuleEnabled('pos');
  bool get _sidebarShowInventory =>
      _permService.can(PermissionKeys.navInventory) &&
      _permService.isModuleEnabled('inventory');
  bool get _sidebarShowProducts =>
      _permService.can(PermissionKeys.productsView);
  bool get _sidebarShowReports =>
      _permService.can(PermissionKeys.navReports) &&
      _permService.isModuleEnabled('reports');
  bool get _sidebarShowOperations =>
      _permService.can(PermissionKeys.navExpenses) &&
      _permService.isModuleEnabled('expenses');
  bool get _sidebarShowSettings => _permService.can(PermissionKeys.navSettings);
  bool get _sidebarShowAuditLogs =>
      _permService.can(PermissionKeys.navAuditLogs) &&
      _permService.isModuleEnabled('audit');
  bool get _sidebarShowSalesHistory =>
      _permService.can(PermissionKeys.navSalesHistory);
  bool get _sidebarShowProcurement =>
      _permService.can(PermissionKeys.navProcurement) &&
      _permService.isModuleEnabled('procurement');
  bool get _sidebarShowCustomers =>
      _permService.can(PermissionKeys.navCustomers) &&
      _permService.isModuleEnabled('crm');
  bool get _sidebarShowFraud =>
      _permService.can(PermissionKeys.navFraud) &&
      _permService.isModuleEnabled('audit');
  bool get _sidebarShowIngredients =>
      _permService.can(PermissionKeys.navRecipes) &&
      _permService.isModuleEnabled('ingredients');

  // Plan locks stay out of the _sidebarShow* getters on purpose: permission and
  // module mean "hide", the plan means "show it wearing the tier it needs".
  String? get _procurementLock => planLockFor(AppFeature.procurement);
  String? get _customersLock => planLockFor(AppFeature.customerDirectory);
  String? get _auditLogsLock => planLockFor(AppFeature.auditLogs);
  String? get _fraudLock => planLockFor(AppFeature.fraudAlerts);

  @override
  Widget build(BuildContext context) {
    // Repaint on every entitlement change so a plan switch updates the lock
    // badges without a restart — same wiring PlanBadge already uses.
    return ValueListenableBuilder<int>(
      valueListenable: sl<EntitlementService>().entitlementRevision,
      builder: (context, _, _) => _buildSidebar(context),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final w = widget.expanded ? _kSidebarExpanded : _kSidebarCollapsed;
    final layoutExpanded = _layoutExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Logo / business header ──
          // Height matches CustomAppBar (64 px) exactly so the horizontal
          // divider/border aligns perfectly with the app bar bottom border.
          Container(
            height: 64,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSoft, width: 1),
              ),
            ),
            child: layoutExpanded
                ? Row(
                    children: [
                      const SizedBox(width: 12),
                      _BusinessLogo(
                        logoLocalPath: _businessLogoLocalPath,
                        logoUrl: _businessLogoUrl,
                        businessName: widget.businessName,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.businessName,
                          overflow: TextOverflow.ellipsis,
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const PlanBadge(),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onToggle,
                          borderRadius: BorderRadius.circular(8),
                          mouseCursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              IconlyLight.arrow_left_2,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : Tooltip(
                    message: 'Expand sidebar',
                    preferBelow: false,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onToggle,
                        mouseCursor: SystemMouseCursors.click,
                        child: SizedBox.expand(
                          child: Center(
                            child: const Icon(
                              IconlyLight.arrow_right_2,
                              size: 24,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),

          // ── Nav items ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── MAIN section ──
                  if (layoutExpanded) const _SectionLabel(label: 'MAIN'),
                  if (_sidebarShowDashboard)
                    _NavItem(
                      icon: IconlyLight.home,
                      activeIcon: IconlyBold.home,
                      label: 'Dashboard',
                      index: 0,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  if (_sidebarShowProducts)
                    _NavItem(
                      icon: IconlyLight.bag,
                      activeIcon: IconlyBold.bag,
                      label: 'Products',
                      index: 1,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  if (_sidebarShowPos)
                    _NavItem(
                      icon: IconlyLight.scan,
                      activeIcon: IconlyBold.scan,
                      label: 'POS Terminal',
                      index: 2,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                      accent: true,
                    ),
                  if (_sidebarShowReports)
                    _NavItem(
                      icon: IconlyLight.chart,
                      activeIcon: IconlyBold.chart,
                      label: 'Reports',
                      index: 3,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  // AI assistant — replaces the old floating button; available
                  // to all roles (no permission gate), pushed over the shell.
                  if (kShowAiAndFraudNav)
                    _PushNavTile(
                      icon: IconlyLight.chat,
                      activeIcon: IconlyBold.chat,
                      label: 'AI Assistant',
                      route: AppRoutes.aiChat,
                      expanded: layoutExpanded,
                      currentLocation: GoRouterState.of(
                        context,
                      ).matchedLocation,
                    ),

                  const SizedBox(height: 6),

                  // ── INVENTORY section — Stock management + Ingredients ──
                  if (_sidebarShowInventory || _sidebarShowIngredients) ...[
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded) const _SectionLabel(label: 'INVENTORY'),
                    if (_sidebarShowInventory)
                      _NavItem(
                        icon: IconlyLight.category,
                        activeIcon: IconlyBold.category,
                        label: 'Inventory',
                        index: 4,
                        currentIndex: widget.currentIndex,
                        expanded: layoutExpanded,
                        onTap: widget.onNavTap,
                      ),
                    if (_sidebarShowIngredients)
                      _PushNavTile(
                        icon: IconlyLight.paper,
                        activeIcon: IconlyBold.paper,
                        label: 'Ingredients',
                        route: AppRoutes.ingredients,
                        expanded: layoutExpanded,
                        currentLocation: GoRouterState.of(
                          context,
                        ).matchedLocation,
                      ),
                  ],

                  // ── SALES section ──
                  if (_sidebarShowSalesHistory) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded) const _SectionLabel(label: 'SALES'),
                    _NavItem(
                      icon: IconlyLight.time_circle,
                      activeIcon: IconlyBold.time_circle,
                      label: 'Sales History',
                      index: 5,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  ],

                  // ── PROCUREMENT section ──
                  if (_sidebarShowProcurement) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded)
                      const _SectionLabel(label: 'PROCUREMENT'),
                    _NavItem(
                      icon: IconlyLight.bag_2,
                      activeIcon: IconlyBold.bag_2,
                      label: 'Purchase Orders',
                      index: 11,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                      lockedPlan: _procurementLock,
                    ),
                    _NavItem(
                      icon: IconlyLight.work,
                      activeIcon: IconlyBold.work,
                      label: 'Suppliers',
                      index: 10,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                      lockedPlan: _procurementLock,
                    ),
                  ],

                  // ── CUSTOMERS section — CRM ──
                  if (_sidebarShowCustomers) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded) const _SectionLabel(label: 'CUSTOMERS'),
                    _NavItem(
                      icon: IconlyLight.profile,
                      activeIcon: IconlyBold.profile,
                      label: 'Customers',
                      index: 12,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                      lockedPlan: _customersLock,
                    ),
                  ],

                  // ── OPERATIONS section — Expenses ──
                  if (_sidebarShowOperations) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded)
                      const _SectionLabel(label: 'OPERATIONS'),
                    _NavItem(
                      icon: IconlyLight.wallet,
                      activeIcon: IconlyBold.wallet,
                      label: 'Expenses',
                      index: 6,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  ],

                  // ── My Profile — restricted employees only ──────────────────
                  if (!_sidebarShowOperations) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded) const _SectionLabel(label: 'ACCOUNT'),
                    _ProfileNavTile(
                      expanded: layoutExpanded,
                      currentLocation: GoRouterState.of(
                        context,
                      ).matchedLocation,
                    ),
                    const SizedBox(height: 6),
                  ],

                  if (_sidebarShowSettings) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),

                    // ── SETTINGS section ──
                    if (layoutExpanded) const _SectionLabel(label: 'SETTINGS'),
                    _PushNavTile(
                      icon: IconlyLight.setting,
                      activeIcon: IconlyBold.setting,
                      label: 'Settings',
                      route: AppRoutes.settings,
                      expanded: layoutExpanded,
                      currentLocation: GoRouterState.of(
                        context,
                      ).matchedLocation,
                    ),
                    const SizedBox(height: 6),
                  ],

                  // ── ADMIN section ──
                  // Sits outside the SETTINGS block: each tile carries its own
                  // gate. Nesting it under Settings → Audit Logs used to hide
                  // Unusual Activity from anyone holding fraud.view without
                  // nav.settings or audit_logs.view, while the mobile drawer
                  // showed it — same account, two different answers.
                  if (_sidebarShowAuditLogs ||
                      (kShowAiAndFraudNav && _sidebarShowFraud)) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                    if (layoutExpanded) const _SectionLabel(label: 'ADMIN'),
                    _EmployeesNavTile(
                      expanded: layoutExpanded,
                      currentLocation: GoRouterState.of(context).matchedLocation,
                    ),
                    if (_sidebarShowAuditLogs)
                      _NavItem(
                        icon: IconlyLight.shield_done,
                        activeIcon: IconlyBold.shield_done,
                        label: 'Audit Logs',
                        index: 8,
                        currentIndex: widget.currentIndex,
                        expanded: layoutExpanded,
                        onTap: widget.onNavTap,
                        lockedPlan: _auditLogsLock,
                      ),
                    if (kShowAiAndFraudNav && _sidebarShowFraud)
                      _NavItem(
                        icon: IconlyLight.shield_fail,
                        activeIcon: IconlyBold.shield_fail,
                        label: 'Unusual Activity',
                        index: 13,
                        currentIndex: widget.currentIndex,
                        expanded: layoutExpanded,
                        onTap: widget.onNavTap,
                        lockedPlan: _fraudLock,
                      ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSoft),
          _SidebarFooter(
            expanded: layoutExpanded,
            isOnline: widget.isOnline,
            pendingSyncCount: widget.pendingSyncCount,
            userName: widget.userName,
            userRole: widget.userRole,
            userAvatar: widget.userAvatar,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// Business logo widget
// Shows the uploaded business logo, falling back to a branded initial block.

class _BusinessLogo extends StatelessWidget {
  final String? logoLocalPath;
  final String? logoUrl;
  final String businessName;
  final double size;

  const _BusinessLogo({
    required this.logoLocalPath,
    required this.logoUrl,
    required this.businessName,
    required this.size,
  });

  String _initial() {
    final clean = businessName.trim();
    if (clean.isEmpty) return 'B';
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final radius = size / 3.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _logo(),
      ),
    );
  }

  // Prefer the local file (offline-ready), then the public URL, then initials.
  Widget _logo() {
    if ((logoLocalPath?.isNotEmpty ?? false) && !kIsWeb) {
      return Image.file(
        File(logoLocalPath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _networkOrInitial(),
      );
    }
    return _networkOrInitial();
  }

  Widget _networkOrInitial() {
    if (logoUrl?.isNotEmpty ?? false) {
      return Image.network(
        logoUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _Initial(initial: _initial(), size: size),
      );
    }
    return _Initial(initial: _initial(), size: size);
  }
}

class _Initial extends StatelessWidget {
  final String initial;
  final double size;
  const _Initial({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      initial,
      style: getOutfitStyle(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final bool expanded;
  final ValueChanged<int> onTap;
  final bool accent;

  /// Plan code required to open this branch, or null when the current plan
  /// includes it. Locked items stay visible, wear a [PlanLockBadge] and open
  /// the upgrade sheet on tap — see the drawer's _DrawerTile for the rationale.
  final String? lockedPlan;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.expanded,
    required this.onTap,
    this.accent = false,
    this.lockedPlan,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lockedPlan != null;
    final isActive = !locked && currentIndex == index;
    final color = locked
        ? AppColors.textMuted
        : (isActive || accent ? AppColors.brand : AppColors.textSecondary);
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked
            ? () => showUpgradePrompt(
                context,
                UpgradeMoment.lockedModule,
                requiredPlan: lockedPlan,
                // The title names the tier; the body says what they get.
                detail:
                    'Upgrade to turn on $label — your current work is never '
                    'blocked.',
              )
            : () => onTap(index),
        borderRadius: BorderRadius.circular(10),
        mouseCursor: SystemMouseCursors.click,
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                size: 20,
                color: color,
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (locked) PlanLockBadge(planCode: lockedPlan!),
              ],
              // Collapsed rail: same crown, smaller, and no tooltip of its own —
              // the whole tile is already wrapped in one that names the tier.
              if (locked && !expanded)
                PlanLockBadge(
                  planCode: lockedPlan!,
                  size: 14,
                  showTooltip: false,
                ),
            ],
          ),
        ),
      ),
    );

    final padded = Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 10, vertical: 2),
      child: item,
    );

    final tooltip = locked
        ? '$label — ${planLabelOf(lockedPlan!)}'
        : label;
    return expanded
        ? padded
        : Tooltip(message: tooltip, preferBelow: false, child: padded);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 12, 3),
      child: Text(
        label,
        style: getOutfitStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A generic sidebar tile that pushes a named route directly.
/// Used for features that are not shell-route branches (procurement, ingredients).
class _PushNavTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool expanded;
  final String currentLocation;

  const _PushNavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.expanded,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation.startsWith(route);
    final color = isActive ? AppColors.brand : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(10),
        mouseCursor: SystemMouseCursors.click,
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(isActive ? activeIcon : icon, size: 20, color: color),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: expanded
          ? item
          : Tooltip(message: label, preferBelow: false, child: item),
    );
  }
}

/// A sidebar nav tile that navigates to the user's profile page.
/// Used only for restricted employees (cashier / inventory staff) who do not
/// have a full SETTINGS section in the sidebar.
class _ProfileNavTile extends StatelessWidget {
  final bool expanded;
  final String currentLocation;

  const _ProfileNavTile({
    required this.expanded,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation == AppRoutes.profile;
    final color = isActive ? AppColors.brand : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.profile),
        borderRadius: BorderRadius.circular(10),
        mouseCursor: SystemMouseCursors.click,
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                isActive ? IconlyBold.profile : IconlyLight.profile,
                size: 20,
                color: color,
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'My Profile',
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: expanded
          ? item
          : Tooltip(message: 'My Profile', preferBelow: false, child: item),
    );
  }
}

/// A sidebar nav tile that navigates to the Employees management page.
/// Shown only to Business Owner in the ADMIN section.
class _EmployeesNavTile extends StatelessWidget {
  final bool expanded;
  final String currentLocation;

  const _EmployeesNavTile({
    required this.expanded,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation.startsWith(AppRoutes.employees);
    final color = isActive ? AppColors.brand : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.employees),
        borderRadius: BorderRadius.circular(10),
        mouseCursor: SystemMouseCursors.click,
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                isActive ? IconlyBold.user_3 : IconlyLight.user_1,
                size: 20,
                color: color,
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Employees',
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: expanded
          ? item
          : Tooltip(message: 'Employees', preferBelow: false, child: item),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool expanded;
  final bool isOnline;
  final int pendingSyncCount;
  final String userName;
  final String userRole;
  final String? userAvatar;

  const _SidebarFooter({
    required this.expanded,
    required this.isOnline,
    required this.pendingSyncCount,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(10),
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 8 : 0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    UserAvatar(
                      avatarUrl: userAvatar,
                      name: userName,
                      radius: 16,
                    ),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getOutfitStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              userRole,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getOutfitStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        IconlyLight.logout,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out?',
          style: getOutfitStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Log out',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      }
    });
  }
}
