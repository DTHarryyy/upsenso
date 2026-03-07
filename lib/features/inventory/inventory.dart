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
                _buildTemporaryDebugPanel(state),
                const SizedBox(height: 16),
                const Text(
                  'Inventory',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildTemporaryDebugPanel(AuthState state) {
    return Card(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temporary Debug: Auth/User Data',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildDebugRow('Auth State', state.runtimeType.toString()),
            if (state is AuthAuthenticated) ...[
              const Divider(height: 20),
              _buildDebugRow('user.id', state.user.id),
              _buildDebugRow('user.email', state.user.email ?? 'NULL'),
              _buildDebugRow('user.fullName', state.user.fullName ?? 'NULL'),
              _buildDebugRow(
                'user.businessId',
                state.user.businessId ?? 'NULL',
              ),
              _buildDebugRow(
                'user.businessName',
                state.user.businessName ?? 'NULL',
              ),
              _buildDebugRow('user.roleId', state.user.roleId ?? 'NULL'),
            ],
            if (state is AuthError) ...[
              const Divider(height: 20),
              _buildDebugRow('error.message', state.message),
            ],
            if (state is AuthCodeSent) ...[
              const Divider(height: 20),
              _buildDebugRow('codeSent.email', state.email),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
