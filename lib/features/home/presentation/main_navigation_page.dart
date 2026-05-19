import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/navigation/sidebar_nav_cubit.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/ui/widgets/app_bottom_nav.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/more/presentation/more_page.dart';

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
  // Initialised in didChangeDependencies so we can read the screen width.
  // Desktop (≥1024 px) → expanded; tablet (600–1023 px) → collapsed icons.
  bool _sidebarExpanded = true;
  bool _sidebarInitialized = false;
  String? _lastUserContextKey;
  bool _syncInitialized = false;

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
    return BlocProvider<SidebarNavCubit>(
      create: (_) => SidebarNavCubit(),
      child: BlocBuilder<AuthBloc, AuthState>(
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
          final roleName = authState.user.roleName?.trim();
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

              // GoRouter's StatefulNavigationShell manages the page stack.
              final shell = widget.navigationShell;

              if (isTablet) {
                return _SyncStatusProvider(
                  builder: (isOnline, pendingSyncCount) => Scaffold(
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1980),
                        child: Row(
                          children: [
                            // ── Sidebar ──────────────────────────────────────────
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

                            // ── Right column: top bar + page content ─────────────
                            Expanded(
                              child: Column(
                                children: [
                                  // Shared top bar — same component as mobile so
                                  // branch selector, sync status, and user section
                                  // are always consistent across breakpoints.
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
                                      onNotificationTapped: () => _onNavTap(8),
                                      showThemeToggle: false,
                                    ),

                                  // Page content.  We override AppBarTheme with
                                  // toolbarHeight: 0 so any per-page AppBar that
                                  // individual pages declare occupies no space and
                                  // is visually hidden — the top bar above provides
                                  // all the chrome the user needs on desktop.
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
                  drawer: const Drawer(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    child: MorePage(),
                  ),
                  appBar: isPosTab
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
                          onNotificationTapped: () => _onNavTap(8),
                          onMenuTapped: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          showThemeToggle: false,
                        ),
                  body: shell,
                  bottomNavigationBar: isPosTab
                      ? null
                      : AppBottomNav(
                          currentIndex: _currentIndex,
                          onTap: _onNavTap,
                          userRole: roleName,
                        ),
                ),
              );
            },
          );
        },
      ),
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

class _AppSidebarState extends State<_AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _settingsExpanded = false;
  late final AnimationController _settingsAnimCtrl;
  late final Animation<double> _settingsExpandAnim;
  String? _businessLogoUrl;

  // Tracks the layout mode separately from widget.expanded.
  // On expand: waits for the animation to finish before switching content.
  // On collapse: switches content immediately so icons show during animation.
  bool _layoutExpanded = false;

  @override
  void initState() {
    super.initState();
    _layoutExpanded = widget.expanded;
    if (widget.businessId != null) _loadBusinessLogo(widget.businessId!);
    _settingsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _settingsExpandAnim = CurvedAnimation(
      parent: _settingsAnimCtrl,
      curve: Curves.easeInOut,
    );
    // Auto-expand settings accordion when on the settings branch (index 7)
    if (widget.currentIndex == 7) {
      _settingsExpanded = true;
      _settingsAnimCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == 7 && !_settingsExpanded) {
      setState(() => _settingsExpanded = true);
      _settingsAnimCtrl.forward();
    }
    if (widget.businessId != oldWidget.businessId &&
        widget.businessId != null) {
      _loadBusinessLogo(widget.businessId!);
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
    _settingsAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessLogo(String businessId) async {
    // 1. Show cached value instantly
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('biz_logo_$businessId');
    if (cached != null && mounted) setState(() => _businessLogoUrl = cached);

    // 2. Background-fetch authoritative URL from Supabase
    try {
      final row = await sl<SupabaseClient>()
          .from('businesses')
          .select('logo_url')
          .eq('id', businessId)
          .maybeSingle();
      final remote = row?['logo_url'] as String?;
      if (remote != null && remote.isNotEmpty && mounted) {
        final url = '$remote?t=${DateTime.now().millisecondsSinceEpoch}';
        setState(() => _businessLogoUrl = url);
        await prefs.setString('biz_logo_$businessId', url);
      }
    } catch (_) {}
  }

  void _toggleSettings() {
    setState(() => _settingsExpanded = !_settingsExpanded);
    if (_settingsExpanded) {
      _settingsAnimCtrl.forward();
    } else {
      _settingsAnimCtrl.reverse();
    }
  }

  void _tapSettingsSubItem(SettingsSubPage subPage) {
    if (!_settingsExpanded) {
      setState(() => _settingsExpanded = true);
      _settingsAnimCtrl.forward();
    }
    context.read<SidebarNavCubit>().setSubPage(subPage);
    widget.onNavTap(7);
  }

  // ── Role-based visibility helpers ──────────────────────────────────────
  String get _roleLower =>
      widget.userRole.trim().toLowerCase().replaceAll(' ', '_');
  bool get _isCashier => _roleLower == 'cashier';
  bool get _isInventoryStaff => _roleLower == 'inventory_staff';
  bool get _isRestrictedEmployee => _isCashier || _isInventoryStaff;

  // Cashier: dashboard + products + POS
  // Inventory staff: dashboard + products + inventory
  // All others: everything
  bool get _sidebarShowDashboard => true; // all roles see the dashboard
  bool get _sidebarShowPos => !_isInventoryStaff;
  bool get _sidebarShowInventory => !_isCashier;
  bool get _sidebarShowProducts =>
      true; // all roles see products (read-only for cashier)
  bool get _sidebarShowReports => !_isRestrictedEmployee;
  bool get _sidebarShowOperations =>
      !_isRestrictedEmployee; // sales history, expenses
  bool get _sidebarShowSettings => !_isRestrictedEmployee;
  bool get _sidebarShowAuditLogs =>
      _roleLower == 'owner' || _roleLower == 'super_admin';
  @override
  Widget build(BuildContext context) {
    final w = widget.expanded ? _kSidebarExpanded : _kSidebarCollapsed;
    final layoutExpanded = _layoutExpanded;
    final settingsSubPage = context.watch<SidebarNavCubit>().state;

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

                  const SizedBox(height: 6),
                  if (_sidebarShowOperations) ...[
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),
                  ],

                  // ── OPERATIONS section ──
                  if (layoutExpanded && _sidebarShowOperations)
                    const _SectionLabel(label: 'OPERATIONS'),
                  if (_sidebarShowOperations)
                    _NavItem(
                      icon: IconlyLight.time_circle,
                      activeIcon: IconlyBold.time_circle,
                      label: 'Sales History',
                      index: 5,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),
                  if (_sidebarShowOperations)
                    _NavItem(
                      icon: IconlyLight.wallet,
                      activeIcon: IconlyBold.wallet,
                      label: 'Expenses',
                      index: 6,
                      currentIndex: widget.currentIndex,
                      expanded: layoutExpanded,
                      onTap: widget.onNavTap,
                    ),

                  // ── My Profile — restricted employees only ──────────────────
                  if (_isRestrictedEmployee) ...[
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
                    _SettingsAccordion(
                      expanded: layoutExpanded,
                      isActive: widget.currentIndex == 7,
                      isAccordionOpen: _settingsExpanded,
                      expandAnim: _settingsExpandAnim,
                      activeSubPage: settingsSubPage,
                      onHeaderTap: () {
                        if (!layoutExpanded) {
                          // Collapsed sidebar: just navigate to settings
                          context.read<SidebarNavCubit>().setSubPage(
                            SettingsSubPage.receipt,
                          );
                          widget.onNavTap(7);
                        } else {
                          _toggleSettings();
                          if (!_settingsExpanded) {
                            // Opening accordion also navigates to settings
                            context.read<SidebarNavCubit>().setSubPage(
                              SettingsSubPage.receipt,
                            );
                            widget.onNavTap(7);
                          }
                        }
                      },
                      onSubItemTap: _tapSettingsSubItem,
                    ),

                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 6),

                    // ── ADMIN section ──
                    if (_sidebarShowAuditLogs) ...[
                      if (layoutExpanded) const _SectionLabel(label: 'ADMIN'),
                      _NavItem(
                        icon: IconlyLight.shield_done,
                        activeIcon: IconlyBold.shield_done,
                        label: 'Audit Logs',
                        index: 9,
                        currentIndex: widget.currentIndex,
                        expanded: layoutExpanded,
                        onTap: widget.onNavTap,
                      ),
                    ],
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

// ── Business logo widget ───────────────────────────────────────────────────
// Shows the uploaded business logo, falling back to a branded initial block.

class _BusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final String businessName;
  final double size;

  const _BusinessLogo({
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
        child: logoUrl != null
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) =>
                    _Initial(initial: _initial(), size: size),
              )
            : _Initial(initial: _initial(), size: size),
      ),
    );
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

// ── Settings accordion ─────────────────────────────────────────────────────

class _SettingsAccordion extends StatelessWidget {
  final bool expanded;
  final bool isActive;
  final bool isAccordionOpen;
  final Animation<double> expandAnim;
  final SettingsSubPage activeSubPage;
  final VoidCallback onHeaderTap;
  final ValueChanged<SettingsSubPage> onSubItemTap;

  const _SettingsAccordion({
    required this.expanded,
    required this.isActive,
    required this.isAccordionOpen,
    required this.expandAnim,
    required this.activeSubPage,
    required this.onHeaderTap,
    required this.onSubItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = isActive ? AppColors.brand : AppColors.textSecondary;
    final headerBg = isActive ? AppColors.brandSoft : Colors.transparent;

    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onHeaderTap,
          borderRadius: BorderRadius.circular(10),
          mouseCursor: SystemMouseCursors.click,
          splashColor: AppColors.brand.withAlpha(20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
            alignment: expanded ? Alignment.centerLeft : Alignment.center,
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  isActive ? IconlyBold.setting : IconlyLight.setting,
                  size: 20,
                  color: headerColor,
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: getOutfitStyle(
                        fontSize: 13.5,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isAccordionOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      IconlyLight.arrow_down_2,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!expanded) {
      return Tooltip(message: 'Settings', preferBelow: false, child: header);
    }

    final subItems = [
      (
        icon: IconlyLight.paper,
        label: 'Receipt Settings',
        subPage: SettingsSubPage.receipt,
      ),
      (
        icon: IconlyLight.work,
        label: 'Business Profile',
        subPage: SettingsSubPage.businessProfile,
      ),
      (
        icon: IconlyLight.profile,
        label: 'My Profile',
        subPage: SettingsSubPage.profile,
      ),
    ];

    return Column(
      children: [
        header,
        SizeTransition(
          sizeFactor: expandAnim,
          axisAlignment: -1,
          child: Column(
            children: subItems.map((item) {
              final isSubActive = isActive && activeSubPage == item.subPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSubItemTap(item.subPage),
                    borderRadius: BorderRadius.circular(8),
                    mouseCursor: SystemMouseCursors.click,
                    splashColor: AppColors.brand.withAlpha(15),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSubActive
                            ? AppColors.brandSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          // Indent indicator line
                          Container(
                            width: 1.5,
                            height: 20,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSubActive
                                  ? AppColors.brand
                                  : AppColors.borderSoft,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Icon(
                            item.icon,
                            size: 16,
                            color: isSubActive
                                ? AppColors.brand
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: getOutfitStyle(
                                fontSize: 12.5,
                                fontWeight: isSubActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSubActive
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
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

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.expanded,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive || accent
        ? AppColors.brand
        : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
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
              ],
            ],
          ),
        ),
      ),
    );

    final padded = Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 10, vertical: 2),
      child: item,
    );

    return expanded
        ? padded
        : Tooltip(message: label, preferBelow: false, child: padded);
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
