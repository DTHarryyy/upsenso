import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/billing_formats.dart';

/// Registered devices for this business, with a Revoke action for whoever can
/// manage billing.
///
/// The device list is online-only (no local Drift mirror), so an offline
/// visit gets its own explanation rather than reading the same as "no
/// devices registered" — the two mean very different things.
class BillingDevicesTab extends StatelessWidget {
  const BillingDevicesTab({super.key});

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.billingManage);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        final active = state.devices.where((d) => !d.isRevoked).toList();
        return RefreshIndicator(
          onRefresh: () => context.read<BillingCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (state.offline)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: AppEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Needs a connection',
                    message: 'Device list needs a connection — your saved '
                        'plan is still shown on the Plans tab.',
                  ),
                )
              else if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: AppEmptyState(
                    icon: Icons.devices_outlined,
                    title: 'No devices registered yet',
                  ),
                )
              else
                _devicesCard(context, state, active),
            ],
          ),
        );
      },
    );
  }

  Widget _devicesCard(
    BuildContext context,
    BillingState s,
    List<RegisteredDevice> active,
  ) {
    return AppSectionCard(
      title: 'Devices',
      icon: Icons.devices_outlined,
      children: [
        for (final d in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_platformIcon(d.platform),
                      size: 17, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.label,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      if (d.lastSeenAt != null)
                        Text('Last seen ${formatBillingDate(d.lastSeenAt!)}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (_canManage)
                  TextButton(
                    onPressed: s.purchaseInProgress
                        ? null
                        : () => context
                            .read<BillingCubit>()
                            .revokeDevice(d.deviceUid),
                    child: const Text('Revoke'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _platformIcon(String platform) => switch (platform) {
        'android' => Icons.android,
        'ios' || 'macos' => Icons.phone_iphone,
        'web' => Icons.language,
        'windows' => Icons.desktop_windows,
        _ => Icons.devices_other,
      };
}
