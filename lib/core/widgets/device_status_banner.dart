import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/routes/app_routes.dart';

/// Says out loud when this device is over the plan's device cap.
///
/// The cap has always been enforced — `register_device` returns `cap_reached`
/// and SyncService quietly refuses to arm — but nothing ever told the merchant,
/// so an extra device looked like sync was simply broken. Reinstalling burns a
/// slot (a new `device_uid` is minted), which made that the most common and
/// most confusing case.
///
/// Never blocks selling. Only this device's cloud backup is affected.
class DeviceStatusBanner extends StatelessWidget {
  const DeviceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final registration = sl<DeviceRegistrationService>();
    return ValueListenableBuilder<int>(
      valueListenable: registration.registrationRevision,
      builder: (context, _, _) {
        if (!registration.isCapReached) return const SizedBox.shrink();
        final cap = registration.deviceCap;
        final plan = planLabelOf(sl<EntitlementService>().planCode);

        final detail = registration.isSecondDeviceMoment
            ? 'Your $plan plan covers one device. Upgrade to sell on your '
                  'phone and your tablet together.'
            : cap == null
            ? 'This device isn\'t authorised on your $plan plan yet.'
            : 'Your $plan plan covers $cap ${cap == 1 ? 'device' : 'devices'} '
                  'and all $cap are in use.';

        return Material(
          color: AppColors.warningSoft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.phonelink_lock_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This device isn\'t backed up',
                        style: getOutfitStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '$detail Selling still works — everything stays saved here.',
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push(AppRoutes.billing),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Manage devices',
                          style: getOutfitStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
