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
        String userRole = 'User';
        String businessName = 'Business';
        String userEmail = 'N/A';

        if (state is AuthAuthenticated) {
          userName = state.user.fullName ?? state.user.email ?? 'User';
          userRole = state.user.roleId ?? 'User';
          businessName = state.user.businessName ?? 'Business';
          userEmail = state.user.email ?? 'N/A';
        }

        return Scaffold(
          appBar: CustomAppBar(
            branches: [businessName],
            selectedBranch: businessName,
            userName: userName,
            userRole: userRole,
            userEmail: userEmail,
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

                // TEMP: Debug offline data display
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
                        _buildDebugRow('User Name:', userName),
                        _buildDebugRow('User Email:', userEmail),
                        _buildDebugRow('Role ID:', userRole),
                        _buildDebugRow('Business Name:', businessName),
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
