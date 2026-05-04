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
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/ui/widgets/app_bottom_nav.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/dashboard/presentation/dashboard_page.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:pos/features/more/presentation/more_page.dart';
import 'package:pos/features/pos/presentation/pos_terminal_page.dart';
import 'package:pos/features/products/products_page.dart';
import 'package:pos/features/reports/presentation/pages/reports_and_analytics.dart';

// Sidebar widths
const double _kSidebarExpanded = 220;
const double _kSidebarCollapsed = 64;

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _sidebarExpanded = true;
  String? _lastUserContextKey;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  late final ConnectivityService _connectivityService;
  StreamSubscription<int>? _syncCountSub;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivityService = sl<ConnectivityService>();
    _setupConnectivityListener();
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

  void _setupConnectivityListener() {
    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (mounted && _isOnline != isConnected) {
        setState(() => _isOnline = isConnected);
      }
    });
    _connectivityService.isConnected.then((isConnected) {
      if (mounted && _isOnline != isConnected) {
        setState(() => _isOnline = isConnected);
      }
    });
  }

  void _onNavTap(int index) {
    setState(() {
      if (_currentIndex != index) _previousIndex = _currentIndex;
      _currentIndex = index;
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
            final selectedBranch =
                branchState.selectedBranch ?? branchName;

            final isTablet = Breakpoints.isTablet(context);
            final isPosTab = _currentIndex == 2;

            final pages = IndexedStack(
              index: _currentIndex,
              children: [
                DashboardPage(onNewSale: () => _onNavTap(2)),
                const ProductsPage(),
                PosTerminalPage(
                  isActive: _currentIndex == 2,
                  onClose: () => _onNavTap(_previousIndex),
                ),
                const ReportsAndAnalyticsPage(),
                const Inventory(),
              ],
            );

            // ── Tablet/Desktop: sidebar layout ──────────────────────────
            if (isTablet) {
              return Scaffold(
                body: Row(
                  children: [
                    if (!isPosTab)
                      _AppSidebar(
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
                        isOnline: _isOnline,
                        pendingSyncCount: _pendingSyncCount,
                        branches: visibleBranches,
                        selectedBranch: selectedBranch,
                        canSwitchBranches: branchState.canSwitchBranches,
                      ),
                    Expanded(child: pages),
                  ],
                ),
              );
            }

            // ── Mobile: original AppBar + BottomNav + Drawer ────────────
            return Scaffold(
              key: _scaffoldKey,
              drawer: const Drawer(child: MorePage()),
              appBar: isPosTab
                  ? null
                  : CustomAppBar(
                      branches: visibleBranches,
                      selectedBranch: selectedBranch,
                      onBranchChanged: branchState.canSwitchBranches
                          ? (branch) =>
                              context.read<BranchCubit>().selectBranch(branch)
                          : null,
                      userName: userName,
                      userRole: userRole,
                      userEmail: userEmail,
                      userId: userId,
                      userAvatar: userAvatar,
                      businessName: businessName,
                      isOnline: _isOnline,
                      pendingSyncCount: _pendingSyncCount,
                      onNotificationTapped: () => _onNavTap(3),
                      onMenuTapped: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      showThemeToggle: false,
                    ),
              body: pages,
              bottomNavigationBar: isPosTab
                  ? null
                  : AppBottomNav(
                      currentIndex: _currentIndex,
                      onTap: _onNavTap,
                    ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _AppSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final w = expanded ? _kSidebarExpanded : _kSidebarCollapsed;

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
          // ── Brand + toggle ─────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 12),
                // App icon / logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    size: 18,
                    color: AppColors.textInverse,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      businessName,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                // Toggle button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        expanded
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 8),

          // ── Main nav items ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expanded)
                    _SectionLabel(label: 'MAIN'),
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    index: 0,
                    currentIndex: currentIndex,
                    expanded: expanded,
                    onTap: onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    index: 1,
                    currentIndex: currentIndex,
                    expanded: expanded,
                    onTap: onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'POS Terminal',
                    index: 2,
                    currentIndex: currentIndex,
                    expanded: expanded,
                    onTap: onNavTap,
                    accent: true,
                  ),
                  _NavItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    index: 3,
                    currentIndex: currentIndex,
                    expanded: expanded,
                    onTap: onNavTap,
                  ),
                  _NavItem(
                    icon: Icons.inventory_rounded,
                    label: 'Inventory',
                    index: 4,
                    currentIndex: currentIndex,
                    expanded: expanded,
                    onTap: onNavTap,
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  const SizedBox(height: 8),

                  // ── More / secondary items ─────────────────────────
                  if (expanded)
                    _SectionLabel(label: 'MORE'),
                  _LinkItem(
                    icon: Icons.history_rounded,
                    label: 'Sales History',
                    expanded: expanded,
                    onTap: (ctx) => ctx.push(AppRoutes.saleshistory),
                  ),
                  _LinkItem(
                    icon: Icons.request_page_outlined,
                    label: 'Expenses',
                    expanded: expanded,
                    onTap: (ctx) => ctx.push(AppRoutes.expenses),
                  ),
                  _LinkItem(
                    icon: Icons.stacked_bar_chart_outlined,
                    label: 'Stock Level',
                    expanded: expanded,
                    onTap: (ctx) => ctx.push(AppRoutes.inventory),
                  ),
                  _LinkItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    expanded: expanded,
                    onTap: (ctx) => ctx.push(AppRoutes.settings),
                  ),
                ],
              ),
            ),
          ),

          // ── Status + user footer ───────────────────────────────────
          const Divider(height: 1, color: AppColors.borderSoft),
          _SidebarFooter(
            expanded: expanded,
            isOnline: isOnline,
            pendingSyncCount: pendingSyncCount,
            userName: userName,
            userRole: userRole,
            userAvatar: userAvatar,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item — switches IndexedStack tab
// ─────────────────────────────────────────────────────────────────────────────

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
    final color = isActive
        ? AppColors.brand
        : accent
            ? AppColors.brand
            : AppColors.textSecondary;
    final bg = isActive ? AppColors.brandSoft : Colors.transparent;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
          ),
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
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
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
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 8 : 10,
        vertical: 2,
      ),
      child: item,
    );

    if (expanded) return padded;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: padded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link item — pushes a GoRouter route (doesn't switch IndexedStack)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final void Function(BuildContext ctx) onTap;

  const _LinkItem({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.brand.withAlpha(20),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
          ),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
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
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 8 : 10,
        vertical: 2,
      ),
      child: item,
    );

    if (expanded) return padded;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: padded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Footer: online status + user avatar/name + logout
// ─────────────────────────────────────────────────────────────────────────────

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
          // Online / sync status
          _StatusRow(
            expanded: expanded,
            isOnline: isOnline,
            pendingSyncCount: pendingSyncCount,
          ),
          const SizedBox(height: 6),

          // User + logout
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(10),
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
                      Icon(
                        Icons.logout_rounded,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          style: getOutfitStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
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
                  borderRadius: BorderRadius.circular(10)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Status row inside footer
// ─────────────────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final bool expanded;
  final bool isOnline;
  final int pendingSyncCount;

  const _StatusRow({
    required this.expanded,
    required this.isOnline,
    required this.pendingSyncCount,
  });

  @override
  Widget build(BuildContext context) {
    final onlineColor =
        isOnline ? AppColors.synced : AppColors.offline;
    final syncColor = pendingSyncCount > 0 ? AppColors.syncing : AppColors.synced;

    if (!expanded) {
      // Collapsed: single dot indicator
      return Tooltip(
        message: isOnline
            ? (pendingSyncCount > 0 ? 'Syncing...' : 'Online · Synced')
            : 'Offline',
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: onlineColor.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: onlineColor.withAlpha(45)),
          ),
          child: Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 15,
            color: onlineColor,
          ),
        ),
      );
    }

    return Row(
      children: [
        _StatusChip(
          color: onlineColor,
          icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          label: isOnline ? 'Online' : 'Offline',
        ),
        if (isOnline) ...[
          const SizedBox(width: 6),
          _StatusChip(
            color: syncColor,
            icon: pendingSyncCount > 0
                ? Icons.sync_rounded
                : Icons.cloud_done_rounded,
            label: pendingSyncCount > 0 ? 'Syncing' : 'Synced',
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusChip({
    required this.color,
    required this.icon,
    required this.label,
  });

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
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
