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
and files
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
}
