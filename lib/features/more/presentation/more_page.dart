import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Container(
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
                                UserAvatar(
                                  avatarUrl: user?.avatarUrl,
                                  name: user?.fullName,
                                  email: user?.email,
                                  radius: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.fullName ?? 'Guest User',
                                        style: AppTextStyles.title(
                                          context,
                                        ).copyWith(
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
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),

                        _buildMenuSection(
                          context: context,
                          title: 'Main',
                          items: [
                            _MenuItem(
                              icon: Icons.history,
                              title: 'Sales History',
                              onTap: () => context.push(AppRoutes.saleshistory),
                            ),
                          ],
                        ),
                        _buildMenuSection(
                          context: context,
                          title: 'Inventory',
                          items: [
                            _MenuItem(
                              icon: Icons.stacked_bar_chart_outlined,
                              title: 'Stock Level',
                              onTap: () => context.push(AppRoutes.inventory),
                            ),
                          ],
                        ),
                        _buildMenuSection(
                          context: context,
                          title: 'Finance',
                          items: [
                            _MenuItem(
                              icon: Icons.request_page_outlined,
                              title: 'Expenses',
                              onTap: () => context.push(AppRoutes.expenses),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Pinned logout button at bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              'Log out?',
                              style: AppTextStyles.title(ctx).copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to log out?',
                              style: AppTextStyles.body(ctx).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'Cancel',
                                  style: AppTextStyles.body(ctx).copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: Text(
                                  'Log out',
                                  style: AppTextStyles.body(ctx).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
