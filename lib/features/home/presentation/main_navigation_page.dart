import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/ui/widgets/app_bottom_nav.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/features/dashboard/presentation/dashboard_page.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:pos/features/pos/presentation/pos_terminal_page.dart';
import 'package:pos/features/more/presentation/more_page.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/products_page.dart';
import 'package:pos/features/reports/presentation/pages/reports_and_analytics.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _previousIndex = 0;
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
    _syncCountSub = sl<SyncService>().watchTotalPendingSyncCount().listen((count) {
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
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (mounted && _isOnline != isConnected) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });

    _connectivityService.isConnected.then((isConnected) {
      if (mounted && _isOnline != isConnected) {
        setState(() {
          _isOnline = isConnected;
        });
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
    final userContextKey =
        '${user.id}|${user.businessId ?? ''}|${user.roleName ?? ''}|${user.branchId ?? ''}|${user.branchName ?? ''}';

    if (_lastUserContextKey == userContextKey) return;
    _lastUserContextKey = userContextKey;

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

        String userName = 'User';
        String userRole = 'Role not set';
        String businessName = 'Business';
        String branchName = 'Branch';
        String userEmail = 'N/A';
        String? userId;

        _scheduleBranchLoad(authState.user);

        userId = authState.user.id;
        userName = authState.user.fullName ?? authState.user.email ?? 'User';

        final roleName = authState.user.roleName?.trim();
        final roleId = authState.user.roleId?.trim();

        userRole = (roleName != null && roleName.isNotEmpty)
            ? roleName
            : (roleId != null && roleId.isNotEmpty)
            ? roleId
            : 'Syncing role...';

        businessName = authState.user.businessName ?? 'Business';
        branchName =
            authState.user.branchName ??
            authState.user.businessName ??
            'Branch';
        userEmail = authState.user.email ?? 'N/A';

        return BlocBuilder<BranchCubit, BranchState>(
          builder: (context, branchState) {
            final visibleBranches = branchState.availableBranches.isNotEmpty
                ? branchState.availableBranches
                : [branchName];
            final selectedBranch = branchState.selectedBranch ?? branchName;

            final isPosTab = _currentIndex == 2;
            return Scaffold(
              key: _scaffoldKey,
              drawer: const Drawer(child: MorePage()),
              appBar: isPosTab
                  ? null
                  : CustomAppBar(
                      branches: visibleBranches,
                      selectedBranch: selectedBranch,
                      onBranchChanged: branchState.canSwitchBranches
                          ? (branch) {
                              context
                                  .read<BranchCubit>()
                                  .selectBranch(branch);
                            }
                          : null,
                      userName: userName,
                      userRole: userRole,
                      userEmail: userEmail,
                      userId: userId,
                      businessName: businessName,
                      isOnline: _isOnline,
                      pendingSyncCount: _pendingSyncCount,
                      onNotificationTapped: () => _onNavTap(3),
                      onMenuTapped: () => _scaffoldKey.currentState?.openDrawer(),
                      showThemeToggle: false,
                    ),
              body: IndexedStack(
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
              ),
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
