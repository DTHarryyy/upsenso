import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_labeled_switch.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/pos/data/datasources/refunds_remote_ds.dart';

/// Owner/admin control for refund approval: a toggle + the money threshold above
/// which a refund needs a manager PIN. Writes refund_settings (RLS:
/// settings.edit_business). The server is the actual gate.
class RefundApprovalSettingsPage extends StatefulWidget {
  const RefundApprovalSettingsPage({super.key});

  @override
  State<RefundApprovalSettingsPage> createState() =>
      _RefundApprovalSettingsPageState();
}

class _RefundApprovalSettingsPageState
    extends State<RefundApprovalSettingsPage> {
  final _threshold = TextEditingController();
  bool _require = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  String? get _businessId => sl<ActiveBusinessContext>().businessId;

  Future<void> _load() async {
    final bid = _businessId;
    if (bid == null) {
      setState(() {
        _loading = false;
        _error = 'No active business.';
      });
      return;
    }
    try {
      final s = await sl<RefundsRemoteDs>().fetchRefundSettings(bid);
      if (!mounted) return;
      setState(() {
        _require = s?.requireApproval ?? false;
        _threshold.text =
            (s?.threshold ?? 0) == 0 ? '' : (s!.threshold).toStringAsFixed(2);
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[RefundApprovalSettings] Error in _load: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load settings. Check your connection.';
        });
      }
    }
  }

  Future<void> _save() async {
    final bid = _businessId;
    if (bid == null) return;
    final threshold = double.tryParse(_threshold.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await sl<RefundsRemoteDs>().upsertRefundSettings(
        businessId: bid,
        requireApproval: _require,
        threshold: threshold,
      );
      if (!mounted) return;
      AppToast.show(context, 'Refund approval settings saved.',
          variant: AppToastVariant.success);
      Navigator.of(context).maybePop();
    } catch (e, st) {
      debugPrint('[RefundApprovalSettings] Error in _save: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, 'Could not save. Check your connection.',
            variant: AppToastVariant.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left,
              size: 18, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Refund Approval',
            style: getOutfitStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  AppInlineBanner(
                      message: _error!,
                      variant: AppInlineBannerVariant.error),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Require a manager to authorise refunds over a set amount. '
                  'Cashiers who can already approve refunds are not prompted.',
                  style: AppTextStyles.body(context)
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: AppLabeledSwitch(
                    label: 'Require approval',
                    subtitle: 'Over-limit refunds need a manager PIN',
                    value: _require,
                    onChanged: (v) => setState(() => _require = v),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: _require ? 1 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approval threshold',
                          style: getOutfitStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _threshold,
                        enabled: _require && !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: AppTextStyles.body(context)
                            .copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          helperText:
                              'Refunds above this amount need approval. 0 = all.',
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borderSoft),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppFilledButton(
                  label: 'Save',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}
