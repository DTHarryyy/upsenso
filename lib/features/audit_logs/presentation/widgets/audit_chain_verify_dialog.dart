import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/audit/audit_chain_verifier.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';

/// Runs the tamper-evidence verification and presents a per-device report.
///
/// Each device writes its own independent hash chain (offline-first —
/// there is no global ordering across devices). "Verified" means every
/// locally retained entry of a chain recomputes and links correctly; the
/// server head comparison additionally proves this device didn't delete
/// already-synced history.
Future<void> showAuditChainVerifyDialog(BuildContext context) {
  // UI hiding is not access control — re-check at the action.
  if (!sl<PermissionService>().can(PermissionKeys.auditLogsVerify)) {
    return Future.value();
  }
  // ActiveBusinessContext is the only sanctioned businessId source.
  final businessId = sl<ActiveBusinessContext>().businessId;
  return showDialog<void>(
    context: context,
    builder: (_) => _VerifyDialog(businessId: businessId),
  );
}

class _VerifyDialog extends StatelessWidget {
  final String? businessId;
  const _VerifyDialog({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Audit chain integrity',
        style: AppTextStyles.title(context),
      ),
      content: SizedBox(
        width: 440,
        child: businessId == null || businessId!.isEmpty
            ? const AppInlineBanner(
                message: 'No active business.',
                variant: AppInlineBannerVariant.warning,
              )
            : FutureBuilder<AuditChainVerifyResult>(
                future: sl<AuditChainVerifier>().verify(
                  businessId: businessId!,
                ),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      ),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return AppInlineBanner(
                      message: 'Verification failed to run: ${snap.error}',
                      variant: AppInlineBannerVariant.error,
                    );
                  }
                  return _ResultView(result: snap.data!);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
            'Close',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final AuditChainVerifyResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.devices.isEmpty) {
      return const AppInlineBanner(
        message: 'No chained audit entries yet — the chain starts with the '
            'first action recorded after this update.',
        variant: AppInlineBannerVariant.info,
      );
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInlineBanner(
            message: result.isClean
                ? 'All device chains verified — no tampering detected.'
                : '${result.totalBreaks} integrity issue(s) found. Review below.',
            variant: result.isClean
                ? AppInlineBannerVariant.success
                : AppInlineBannerVariant.error,
          ),
          if (!result.serverCheckRan)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: AppInlineBanner(
                message: 'Offline — could not compare against the server. '
                    'Deletion of already-synced history is unchecked.',
                variant: AppInlineBannerVariant.warning,
              ),
            ),
          const SizedBox(height: 12),
          for (final device in result.devices) _DeviceTile(device: device),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final AuditChainDeviceReport device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final hasLocalRows = device.checkedCount > 0;
    final subtitle = hasLocalRows
        ? 'Checked entries ${device.firstCheckedSeq}–${device.localHeadSeq}'
          ' (${device.checkedCount})'
          '${device.firstCheckedSeq != 1 ? ' · older history is on the server' : ''}'
        : 'No local entries — recorded on the server up to '
          'entry ${device.serverHeadSeq}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                device.isClean
                    ? IconlyBold.shield_done
                    : IconlyBold.shield_fail,
                size: 18,
                color: device.isClean ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.isThisDevice
                      ? '${device.deviceLabel} (this device)'
                      : device.deviceLabel,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              subtitle,
              style: AppTextStyles.caption(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          for (final b in device.breaks)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                '• Entry ${b.seq}: ${_reasonLabel(b.reason)}',
                style: AppTextStyles.caption(context)
                    .copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  String _reasonLabel(AuditChainBreakReason reason) {
    switch (reason) {
      case AuditChainBreakReason.hashMismatch:
        return 'entry content was altered after it was recorded';
      case AuditChainBreakReason.linkMismatch:
        return 'chain link is broken (entry does not match its predecessor)';
      case AuditChainBreakReason.seqGap:
        return 'entries were removed (sequence gap)';
      case AuditChainBreakReason.truncatedTail:
        return 'already-synced history is missing from this device';
      case AuditChainBreakReason.storageLoss:
        return 'recent history was lost to browser storage eviction, not tampering';
    }
  }
}
