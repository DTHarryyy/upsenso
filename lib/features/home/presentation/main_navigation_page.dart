import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/branch/branch_cubit.dart';
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

const double _kSidebarExpanded = 220;
const double _kSidebarCollapsed = 64;

class MainNavigationPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationPage({super.key, required this.navigationShell});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExpanded = true;
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
          final branchName = authState.user.branchName ??
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
                return Scaffold(
                  body: Row(
                    children: [
                      if (!isPosTab)
                        _SyncStatusProvider(
                          builder: (isOnline, pendingSyncCount) => _AppSidebar(
                            expanded: _sidebarExpanded,
                            currentIndex: _currentIndex,
                            onNavTap: _onNavTap,
                            onToggle: () => setState(
                                () => _sidebarExpanded = !_sidebarExpanded),
                            userName: userName,
                            userRole: userRole,
                            userEmail: userEmail,
                            userAvatar: userAvatar,
                            businessName: businessName,
                            isOnline: isOnline,
                            pendingSyncCount: pendingSyncCount,
                            branches: visibleBranches,
                            selectedBranch: selectedBranch,
                            canSwitchBranches: branchState.canSwitchBranches,
                          ),
                        ),
                      Expanded(child: shell),
                    ],
                  ),
                );
              }

              return _SyncStatusProvider(
                builder: (isOnline, pendingSyncCount) => Scaffold(
                  key: _scaffoldKey,
                  drawer: const Drawer(child: MorePage()),
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
                          onNotificationTapped: () => _onNavTap(3),
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

    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((v) {
      if (mounted && _isOnline != v) setState(() => _isOnline = v);
    });

    _syncCountSub =
        sl<SyncService>().watchTotalPendingSyncCount().listen((count) {
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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _settingsAnimCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final w = widget.expanded ? _kSidebarExpanded : _kSidebarCollapsed;
    final settingsSubPage = context.watch<SidebarNavCubit>().state;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // ── Logo / business header ──
          // Collapsed (64px): the entire header becomes a single tap target so
          // the expand icon is always reachable — no Row overflow possible.
          // Expanded (220px): logo + business name + collapse chevron in a Row.
          SizedBox(
            height: 48,
            child: widget.expanded
                ? Row(
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.point_of_sale_rounded,
                            size: 18, color: AppColors.textInverse),
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
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.chevron_left_rounded,
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
                        child: const SizedBox.expand(
                          child: Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 8),

          // ── Nav items ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── MAIN section ──
                  if (widget.expanded) const _SectionLabel(label: 'MAIN'),
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    index: 0,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    index: 1,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'POS Terminal',
                    index: 2,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                    accent: true,
                  ),
                  _NavItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    index: 3,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.inventory_rounded,
                    label: 'Inventory',
                    index: 4,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  const SizedBox(height: 8),

                  // ── OPERATIONS section ──
                  if (widget.expanded) const _SectionLabel(label: 'OPERATIONS'),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'Sales History',
                    index: 5,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.request_page_outlined,
                    label: 'Expenses',
                    index: 6,
                    currentIndex: widget.currentIndex,
                    expanded: widget.expanded,
                    onTap: widget.onNavTap,
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  const SizedBox(height: 8),

                  // ── SETTINGS section ──
                  if (widget.expanded) const _SectionLabel(label: 'SETTINGS'),
                  _SettingsAccordion(
                    expanded: widget.expanded,
                    isActive: widget.currentIndex == 7,
                    isAccordionOpen: _settingsExpanded,
                    expandAnim: _settingsExpandAnim,
                    activeSubPage: settingsSubPage,
                    onHeaderTap: () {
                      if (!widget.expanded) {
                        // Collapsed sidebar: just navigate to settings
                        context.read<SidebarNavCubit>().setSubPage(SettingsSubPage.receipt);
                        widget.onNavTap(7);
                      } else {
                        _toggleSettings();
                        if (!_settingsExpanded) {
                          // Opening accordion also navigates to settings
                          context.read<SidebarNavCubit>().setSubPage(SettingsSubPage.receipt);
                          widget.onNavTap(7);
                        }
                      }
                    },
                    onSubItemTap: _tapSettingsSubItem,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSoft),
          _SidebarFooter(
            expanded: widget.expanded,
            isOnline: widget.isOnline,
            pendingSyncCount: widget.pendingSyncCount,
            userName: widget.userName,
            userRole: widget.userRole,
            userAvatar: widget.userAvatar,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
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
    final headerColor =
        isActive ? AppColors.brand : AppColors.textSecondary;
    final headerBg = isActive ? AppColors.brandSoft : Colors.transparent;

    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onHeaderTap,
          borderRadius: BorderRadius.circular(10),
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
                Icon(Icons.settings_rounded, size: 20, color: headerColor),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: getOutfitStyle(
                        fontSize: 13.5,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
                      Icons.keyboard_arrow_down_rounded,
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
      return Tooltip(
        message: 'Settings',
        preferBelow: false,
        child: header,
      );
    }

    final subItems = [
      (
        icon: Icons.receipt_long_rounded,
        label: 'Receipt Settings',
        subPage: SettingsSubPage.receipt,
      ),
      (
        icon: Icons.business_rounded,
        label: 'Business Profile',
        subPage: SettingsSubPage.businessProfile,
      ),
      (
        icon: Icons.person_rounded,
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
                    splashColor: AppColors.brand.withAlpha(15),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSubActive
                            ? AppColors.brandSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
  final String label;
  final int index;
  final int currentIndex;
  final bool expanded;
  final ValueChanged<int> onTap;
  final bool accent;

  const _NavItem({
    required this.icon,
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
    final color = isActive || accent ? AppColors.brand : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
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

    return expanded ? padded : Tooltip(message: label, preferBelow: false, child: padded);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
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
          _StatusRow(expanded: expanded, isOnline: isOnline, pendingSyncCount: pendingSyncCount),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 0, vertical: 8),
                child: Row(
                  mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    UserAvatar(avatarUrl: userAvatar, name: userName, radius: 16),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: getOutfitStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(userRole, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
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
        title: Text('Log out?', style: getOutfitStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to log out?', style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Log out', style: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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

class _StatusRow extends StatelessWidget {
  final bool expanded;
  final bool isOnline;
  final int pendingSyncCount;

  const _StatusRow({required this.expanded, required this.isOnline, required this.pendingSyncCount});

  @override
  Widget build(BuildContext context) {
    final onlineColor = isOnline ? AppColors.synced : AppColors.offline;
    final syncColor = pendingSyncCount > 0 ? AppColors.syncing : AppColors.synced;

    if (!expanded) {
      return Tooltip(
        message: isOnline ? (pendingSyncCount > 0 ? 'Syncing...' : 'Online · Synced') : 'Offline',
        child: Container(
          width: 32, height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: onlineColor.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: onlineColor.withAlpha(45)),
          ),
          child: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 15, color: onlineColor),
        ),
      );
    }

    return Row(
      children: [
        _StatusChip(color: onlineColor, icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, label: isOnline ? 'Online' : 'Offline'),
        if (isOnline) ...[
          const SizedBox(width: 6),
          _StatusChip(color: syncColor, icon: pendingSyncCount > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded, label: pendingSyncCount > 0 ? 'Syncing' : 'Synced'),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusChip({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: getOutfitStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
