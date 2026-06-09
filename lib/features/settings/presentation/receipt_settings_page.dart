import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pos/features/settings/presentation/cubit/settings_state.dart';
import 'package:pos/features/settings/presentation/widgets/receipt_settings_section.dart';

class ReceiptSettingsPage extends StatefulWidget {
  const ReceiptSettingsPage({super.key});

  @override
  State<ReceiptSettingsPage> createState() => _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends State<ReceiptSettingsPage>
    with SingleTickerProviderStateMixin {
  late final SettingsCubit _cubit;
  late final TabController _tabController;

  static const _tabs = ['Business', 'Receipt', 'Printing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _cubit = SettingsCubit(sl());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        final user = auth.user;
        final selectedBranch = context.read<BranchCubit>().state.selectedBranch;
        _cubit.startWatching(
          businessId: user.businessId ?? '',
          businessName: user.businessName,
          branchName: selectedBranch,
          ownerName: user.fullName,
          email: user.email,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (p, c) => c.errorMessage != null,
        listener: (ctx, state) {
          AppToast.show(
            ctx,
            state.errorMessage ?? 'An error occurred',
            variant: AppToastVariant.error,
          );
          _cubit.dismissError();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                IconlyLight.arrow_left,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              'Receipt Settings',
              style: getOutfitStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (p, c) => p.saveStatus != c.saveStatus,
                builder: (_, state) {
                  if (state.saveStatus == SettingsSaveStatus.saving) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    );
                  }
                  if (state.saveStatus == SettingsSaveStatus.saved) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconlyBold.tick_square,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: getOutfitStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 1, color: AppColors.borderSoft),
                  TabBar(
                    controller: _tabController,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    indicatorColor: AppColors.brand,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: AppColors.brand,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          body: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                );
              }
              final s = state.settings;
              if (s == null) return const SizedBox.shrink();

              return TabBarView(
                controller: _tabController,
                children: [
                  BusinessTab(settings: s),
                  ReceiptTab(settings: s),
                  PrintingTab(settings: s),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
