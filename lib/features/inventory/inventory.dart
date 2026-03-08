import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/core/ui/widgets/app_sidebar.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _allBranchesLabel = 'All Branches';

  List<String> _branchOptions = const [];
  String? _selectedBranch;
  String? _lastBranchContextKey;
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    // Refresh auth user context when entering home for immediate UX updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthStarted());
    });
  }

  bool _isMobileLayout(BuildContext context) => !Breakpoints.isTablet(context);

  void _goToProfile() {
    if (!mounted) return;
    context.go(AppRoutes.profile);
  }

  Future<bool> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out from this account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    return shouldLogout == true;
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await _showLogoutConfirmation();
    if (!mounted || !confirmed) return;
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  bool _isSuperAdmin(String? roleName) {
    final normalized = roleName?.trim().toLowerCase() ?? '';
    return normalized == 'super admin' || normalized == 'superadmin';
  }

  void _scheduleBranchLoad(AppUser user) {
    final branchContextKey =
        '${user.id}|${user.businessId ?? ''}|${user.roleName ?? ''}|${user.branchId ?? ''}|${user.branchName ?? ''}';

    if (_lastBranchContextKey == branchContextKey) return;
    _lastBranchContextKey = branchContextKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBranchesForUser(user);
    });
  }

  Future<void> _loadBranchesForUser(AppUser user) async {
    if (_isLoadingBranches) return;

    final businessId = user.businessId?.trim();
    final fallbackBranch = user.branchName?.trim();

    if (businessId == null || businessId.isEmpty) {
      final fallback = (fallbackBranch != null && fallbackBranch.isNotEmpty)
          ? fallbackBranch
          : 'Branch';
      if (!mounted) return;
      setState(() {
        _branchOptions = [fallback];
        _selectedBranch = fallback;
      });
      return;
    }

    _isLoadingBranches = true;

    try {
      final remote = sl<BusinessRemoteDs>();
      final branchesDao = sl<BranchesDao>();
      final names = <String>[];

      if (_isSuperAdmin(user.roleName)) {
        try {
          final rows = await remote.getActiveBranchesByBusiness(businessId);
          for (final row in rows) {
            final name = row['name']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              names.add(name);
            }
          }
        } catch (_) {
          final localRows = await branchesDao.getByBusinessId(businessId);
          for (final row in localRows) {
            if (row.isActive && row.name.trim().isNotEmpty) {
              names.add(row.name.trim());
            }
          }
        }
      } else {
        final assignedBranchId = user.branchId?.trim();
        if (assignedBranchId != null && assignedBranchId.isNotEmpty) {
          try {
            final row = await remote.getActiveBranchById(assignedBranchId);
            final name = row?['name']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              names.add(name);
            }
          } catch (_) {
            final local = await branchesDao.getById(assignedBranchId);
            if (local != null &&
                local.isActive &&
                local.name.trim().isNotEmpty) {
              names.add(local.name.trim());
            }
          }
        }
      }

      if (fallbackBranch != null && fallbackBranch.isNotEmpty) {
        names.add(fallbackBranch);
      }

      if (names.isEmpty) {
        names.add('Branch');
      }

      final uniqueNames = names.toSet().toList();
      uniqueNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final isSuperAdmin = _isSuperAdmin(user.roleName);
      if (isSuperAdmin && !uniqueNames.contains(_allBranchesLabel)) {
        uniqueNames.insert(0, _allBranchesLabel);
      }

      final selected = _resolveSelectedBranch(
        options: uniqueNames,
        current: _selectedBranch,
        fallback: isSuperAdmin ? _allBranchesLabel : fallbackBranch,
      );

      if (!mounted) return;
      setState(() {
        _branchOptions = uniqueNames;
        _selectedBranch = selected;
      });
    } finally {
      _isLoadingBranches = false;
    }
  }

  String _resolveSelectedBranch({
    required List<String> options,
    required String? current,
    required String? fallback,
  }) {
    if (current != null && options.contains(current)) {
      return current;
    }

    if (fallback != null && options.contains(fallback)) {
      return fallback;
    }

    return options.first;
  }

  Future<void> _openSettingsSheet() async {
    final themeController = sl<ThemeController>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: AnimatedBuilder(
              animation: themeController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark mode'),
                      subtitle: const Text(
                        'Use a darker appearance across the app.',
                      ),
                      value: themeController.isDarkMode,
                      onChanged: (enabled) {
                        themeController.setThemeMode(
                          enabled ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthUnauthenticated || current is AuthError,
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.signIn);
          return;
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        String userName = 'User';
        String userRole = 'Role not set';
        String userRoleId = 'Pending sync';
        String userRoleName = 'Pending sync';
        String businessName = 'Business';
        String branchName = 'Branch';
        String userEmail = 'N/A';
        String? userId;

        if (state is AuthAuthenticated) {
          _scheduleBranchLoad(state.user);

          userId = state.user.id;
          userName = state.user.fullName ?? state.user.email ?? 'User';

          final roleName = state.user.roleName?.trim();
          final roleId = state.user.roleId?.trim();

          userRoleName = (roleName != null && roleName.isNotEmpty)
              ? roleName
              : 'Pending sync';
          userRoleId = (roleId != null && roleId.isNotEmpty)
              ? roleId
              : 'Pending sync';

          // Display role name first; fallback to role id if name is unavailable.
          userRole = (roleName != null && roleName.isNotEmpty)
              ? roleName
              : (roleId != null && roleId.isNotEmpty)
              ? roleId
              : 'Syncing role...';

          businessName = state.user.businessName ?? 'Business';
          branchName =
              state.user.branchName ?? state.user.businessName ?? 'Branch';
          userEmail = state.user.email ?? 'N/A';
        }

        final isMobile = _isMobileLayout(context);
        final themeController = sl<ThemeController>();
        final userIsSuperAdmin = _isSuperAdmin(userRoleName);

        final visibleBranches = _branchOptions.isNotEmpty
            ? _branchOptions
            : (userIsSuperAdmin
                  ? <String>[_allBranchesLabel, branchName]
                  : <String>[branchName]);
        final selectedBranch = _resolveSelectedBranch(
          options: visibleBranches,
          current: _selectedBranch,
          fallback: userIsSuperAdmin ? _allBranchesLabel : branchName,
        );

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile
              ? Drawer(
                  child: AppSidebar(
                    userName: userName,
                    userRole: userRole,
                    activeItem: AppSidebarItem.inventory,
                    onInventoryTap: () => Navigator.of(context).pop(),
                    onProfileTap: () {
                      Navigator.of(context).pop();
                      _goToProfile();
                    },
                    onSettingsTap: () {
                      Navigator.of(context).pop();
                      _openSettingsSheet();
                    },
                    onLogoutTap: () {
                      Navigator.of(context).pop();
                      _confirmAndLogout();
                    },
                  ),
                )
              : null,
          appBar: CustomAppBar(
            branches: visibleBranches,
            selectedBranch: selectedBranch,
            onBranchChanged: (branch) {
              setState(() {
                _selectedBranch = branch;
              });
            },
            userName: userName,
            userRole: userRole,
            userEmail: userEmail,
            userId: userId,
            businessName: businessName,
            onMenuTapped: isMobile
                ? () => _scaffoldKey.currentState?.openDrawer()
                : null,
            onProfileTapped: _goToProfile,
            onThemeToggleTapped: () => themeController.toggleDarkMode(),
            showThemeToggle: !isMobile,
            isDarkMode: themeController.isDarkMode,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // TODO: Debug offline data display tanggalin ko after ngani
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Offline Test - Cached Auth Context',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDebugRow('User ID:', userId ?? 'N/A'),
                        _buildDebugRow('User Name:', userName),
                        _buildDebugRow('User Email:', userEmail),
                        _buildDebugRow('Role Name:', userRoleName),
                        _buildDebugRow('Role ID:', userRoleId),
                        _buildDebugRow('Business Name:', businessName),
                        _buildDebugRow('Branch Name:', branchName),
                        _buildDebugRow('Branch Filter:', selectedBranch),
                        if (state is AuthAuthenticated) ...[
                          _buildDebugRow(
                            'Business ID:',
                            state.user.businessId ?? 'NULL',
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'TEST: Turn off internet and restart app. This data should persist.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Center(
                  child: Text('Inventory items will be displayed here'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
