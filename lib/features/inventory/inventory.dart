import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  @override
  void initState() {
    super.initState();
    // Refresh auth user context when entering home for immediate UX updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthStarted());
    });
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

        return Scaffold(
          appBar: CustomAppBar(
            branches: [branchName],
            selectedBranch: branchName,
            userName: userName,
            userRole: userRole,
            userEmail: userEmail,
            userId: userId,
            businessName: businessName,
            onLogoutTapped: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
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
