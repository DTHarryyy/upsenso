import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_tab_bar.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/tabs/billing_devices_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_history_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_plans_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_usage_tab.dart';

/// Billing & subscription — four tabs (Plans / Usage / Devices / History).
///
/// Nothing is pinned above the tab bar: trial, past-due and lapsed alerts all
/// live in Notifications (see BillingNoticeService), which is where merchants
/// actually look for them.
///
/// This shell owns only what every tab needs: the resume-refresh, the
/// purchase-event listener (stuck-purchase dialog / snackbars), and the tab
/// bar itself. Each tab reads [BillingCubit] directly.
class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillingCubit>(
      create: (_) => BillingCubit(
        entitlement: sl<EntitlementService>(),
        remoteDs: sl<BillingRemoteDs>(),
        connectivity: sl<ConnectivityService>(),
        deviceRegistration: sl(),
        iap: sl<IapService>(),
        purchaseSync: sl<PlayPurchaseSyncService>(),
        activeBusiness: sl<ActiveBusinessContext>(),
      )..load(),
      child: const _BillingView(),
    );
  }
}

class _BillingView extends StatefulWidget {
  const _BillingView();

  @override
  State<_BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<_BillingView>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, pull the fresh plan so a just-completed purchase (or a change
    // made elsewhere) reflects immediately.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BillingCubit>().refresh();
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// The user's money is already gone but the plan isn't on — that must not be
  /// a snackbar they can scroll past.
  Future<void> _showPurchaseAlert(BuildContext context, String message) async {
    final cubit = context.read<BillingCubit>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Purchase needs attention'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.dismissPurchaseAlert();
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.retryStuckPurchase();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Billing & Subscription'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
      ),
      body: BlocConsumer<BillingCubit, BillingState>(
        listenWhen: (prev, curr) =>
            (curr.purchaseError != null &&
                curr.purchaseError != prev.purchaseError) ||
            (curr.purchaseAlert != null &&
                curr.purchaseAlert != prev.purchaseAlert) ||
            curr.purchaseNotice != null,
        listener: (context, state) {
          // Each channel gets its own treatment and none of them swallows
          // another: an alert used to suppress a co-present error entirely, so
          // whichever arrived second was simply never shown.
          if (state.purchaseNotice != null) _snack(state.purchaseNotice!);
          if (state.purchaseError != null) _snack(state.purchaseError!);
          // A charged-but-ungranted purchase gets a dialog it must dismiss; a
          // plain failure stays a snackbar.
          if (state.purchaseAlert != null) {
            _showPurchaseAlert(context, state.purchaseAlert!);
          }
        },
        builder: (context, state) {
          if (state.status == BillingStatus.loading) {
            return const AppSkeletonList(itemCount: 4);
          }
          return Center(
            child: ConstrainedBox(
              // Keeps the picker readable on web/desktop instead of
              // stretching cards across an ultra-wide window.
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                children: [
                  ColoredBox(
                    color: AppColors.surface,
                    child: AppTabBar(
                      tabs: const ['Plans', 'Usage', 'Devices', 'History'],
                      selectedIndex: _tab,
                      onTabSelected: (i) => setState(() => _tab = i),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        const BillingPlansTab(),
                        const BillingUsageTab(),
                        const BillingDevicesTab(),
                        BillingHistoryTab(
                          onSeePlans: () => setState(() => _tab = 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
