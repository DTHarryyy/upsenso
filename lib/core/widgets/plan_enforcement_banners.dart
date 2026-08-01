import 'package:flutter/material.dart';

import 'package:pos/core/widgets/device_status_banner.dart';
import 'package:pos/core/widgets/over_cap_banner.dart';

/// Every "your plan is blocking something right now" strip, in one widget the
/// app shell mounts once under the top bar.
///
/// Each child renders nothing when it has nothing to say, so on a healthy
/// account (inside every cap, device registered) this whole column collapses to
/// zero height.
///
/// Subscription *status* — trialing, past due, unverified, cloud paused —
/// deliberately does NOT live here. `BillingNoticeService` already pushes those
/// to the notification bell, where they can be acknowledged; a second permanent
/// strip saying the same thing is nag, not information.
///
/// What's left are the two conditions the bell can't express, because they are
/// standing states rather than events and there is nothing to acknowledge:
/// something is locked, or this device isn't backed up.
class PlanEnforcementBanners extends StatelessWidget {
  const PlanEnforcementBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [OverCapBanner(), DeviceStatusBanner()],
    );
  }
}
