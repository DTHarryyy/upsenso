import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivityService = sl<ConnectivityService>();
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((
      isConnected,
    ) {
      if (mounted && _isOnline != isConnected) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
    _loadInitialConnectivity();
  }

  Future<void> _loadInitialConnectivity() async {
    final isConnected = await _connectivityService.isConnected;
    if (mounted && _isOnline != isConnected) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eto muna okay na to!!!!'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: Text('Not authenticated'));
          }

          final user = authState.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: AppTextStyles.body(context).copyWith(
                      color: _isOnline ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'User Information',
                  items: [
                    _InfoItem('User ID', user.id),
                    _InfoItem('Email', user.email ?? 'N/A'),
                    _InfoItem('Full Name', user.fullName ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Business Information',
                  items: [
                    _InfoItem('Business ID', user.businessId ?? 'N/A'),
                    _InfoItem('Business Name', user.businessName ?? 'N/A'),
                    _InfoItem('Category', user.businessTemplateName ?? 'N/A'),
                    _InfoItem('Role ID', user.roleId ?? 'N/A'),
                    _InfoItem('Role Name', user.roleName ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<BranchCubit, BranchState>(
                  builder: (context, branchState) {
                    return _buildInfoCard(
                      title: 'Branch Information',
                      items: [
                        _InfoItem('Branch ID', user.branchId ?? 'N/A'),
                        _InfoItem('Branch Name', user.branchName ?? 'N/A'),
                        _InfoItem(
                          'Selected Branch (Cubit)',
                          branchState.selectedBranch?.isEmpty ?? true
                              ? 'Not set'
                              : branchState.selectedBranch!,
                        ),
                        _InfoItem(
                          'Selected Branch ID (Cubit)',
                          branchState.selectedBranchId?.isEmpty ?? true
                              ? 'Not set'
                              : branchState.selectedBranchId!,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isOnline ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline
                            ? 'All systems operational'
                            : 'Working offline with cached data',
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOnline
                            ? 'Connected to server. All features available.'
                            : 'Offline mode active. Using cached business and user data.',
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Has Business: ${user.businessId != null ? "YES" : "NO"}',
                        style: AppTextStyles.body(context).copyWith(
                          color: user.businessId != null
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.subtitle(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item.label,
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
