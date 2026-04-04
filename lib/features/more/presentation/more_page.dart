import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.brandSoft,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email ?? 'Guest User',
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.textPrimary,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View Profile',
                                style: AppTextStyles.caption(
                                  context,
                                ).copyWith(color: AppColors.brand),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),

                  // Menu Items
                  _buildMenuSection(
                    context: context,
                    title: 'Main',
                    items: [
                      _MenuItem(
                        icon: Icons.history,
                        title: 'Sales History',
                        onTap: () => context.push(AppRoutes.saleshistory),
                      ),
                      _MenuItem(
                        icon: Icons.history,
                        title: 'Stock Level',
                        onTap: () => context.push(AppRoutes.inventory),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    context: context,
                    title: 'Business',
                    items: [
                      _MenuItem(
                        icon: Icons.business,
                        title: 'Business Profile',
                        onTap: () => context.push(AppRoutes.businessProfile),
                      ),
                      _MenuItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          // TODO: Navigate to settings
                        },
                      ),
                    ],
                  ),

                  _buildMenuSection(
                    context: context,
                    title: 'Reports',
                    items: [
                      _MenuItem(
                        icon: Icons.bar_chart,
                        title: 'Sales Report',
                        onTap: () {
                          // TODO: Navigate to sales report
                        },
                      ),
                      _MenuItem(
                        icon: Icons.assessment,
                        title: 'Analytics',
                        onTap: () {
                          // TODO: Navigate to analytics
                        },
                      ),
                    ],
                  ),

                  _buildMenuSection(
                    context: context,
                    title: 'Support',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          // TODO: Navigate to help
                        },
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () {
                          // TODO: Navigate to about
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.textSecondary),
                    title: Text(
                      item.title,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
