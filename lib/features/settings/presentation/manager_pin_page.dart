import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/pos/data/datasources/refunds_remote_ds.dart';

/// Lets a manager set/reset their own manager PIN. The PIN authorises
/// over-threshold refunds at the terminal; it is bcrypt-hashed on the server
/// (`set_manager_pin`) and never stored or compared on the device.
class ManagerPinPage extends StatefulWidget {
  const ManagerPinPage({super.key});

  @override
  State<ManagerPinPage> createState() => _ManagerPinPageState();
}

class _ManagerPinPageState extends State<ManagerPinPage> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      AppToast.show(context, 'PIN must be 4 to 6 digits.',
          variant: AppToastVariant.error);
      return;
    }
    if (pin != _confirm.text.trim()) {
      AppToast.show(context, 'PINs do not match.',
          variant: AppToastVariant.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await sl<RefundsRemoteDs>().setManagerPin(pin: pin);
      if (!mounted) return;
      AppToast.show(context, 'Manager PIN updated.',
          variant: AppToastVariant.success);
      Navigator.of(context).maybePop();
    } catch (e, st) {
      debugPrint('[ManagerPin] Error in _save: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, 'Could not save the PIN. Check your connection.',
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
        title: Text('Manager PIN',
            style: getOutfitStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set a 4–6 digit PIN. You enter it at the terminal to authorise '
            'refunds that are over your business\'s approval limit.',
            style: AppTextStyles.body(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _PinField(label: 'New PIN', controller: _pin, enabled: !_saving),
          const SizedBox(height: 14),
          _PinField(
              label: 'Confirm PIN', controller: _confirm, enabled: !_saving),
          const SizedBox(height: 16),
          AppInlineBanner(
            message: 'Keep your PIN private. Anyone with it can approve '
                'over-limit refunds in your name.',
            variant: AppInlineBannerVariant.info,
          ),
          const SizedBox(height: 24),
          AppFilledButton(
            label: 'Save PIN',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _PinField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.subtitle(context)
              .copyWith(letterSpacing: 6, color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSoft),
            ),
          ),
        ),
      ],
    );
  }
}
