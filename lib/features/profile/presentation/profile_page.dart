import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/core/ui/widgets/app_sidebar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isMobileLayout(BuildContext context) => !Breakpoints.isTablet(context);

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
        String userEmail = 'N/A';
        String businessName = 'N/A';
        String branchName = 'N/A';
        String userId = 'N/A';

        if (state is AuthAuthenticated) {
          userName = state.user.fullName ?? state.user.email ?? 'User';
          userRole = state.user.roleName ?? state.user.roleId ?? 'Role not set';
          userEmail = state.user.email ?? 'N/A';
          businessName = state.user.businessName ?? 'N/A';
          branchName = state.user.branchName ?? 'N/A';
          userId = state.user.id;
        }

        final isMobile = _isMobileLayout(context);
        final themeController = sl<ThemeController>();

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile
              ? Drawer(
                  child: AppSidebar(
                    userName: userName,
                    userRole: userRole,
                    activeItem: AppSidebarItem.profile,
                    onInventoryTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.home);
                    },
                    onProfileTap: () => Navigator.of(context).pop(),
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
          appBar: AppBar(
            title: const Text('Profile'),
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: _openSettingsSheet,
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: _confirmAndLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow('Full Name', userName),
                        _infoRow('Email', userEmail),
                        _infoRow('User ID', userId),
                        _infoRow('Role', userRole),
                        _infoRow('Business', businessName),
                        _infoRow('Branch', branchName),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AnimatedBuilder(
                      animation: themeController,
                      builder: (context, _) {
                        return SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark mode'),
                          subtitle: const Text(
                            'This is the same setting from the settings menu.',
                          ),
                          value: themeController.isDarkMode,
                          onChanged: (enabled) {
                            themeController.setThemeMode(
                              enabled ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
