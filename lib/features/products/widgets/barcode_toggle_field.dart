import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';

class BarcodeToggleField extends StatefulWidget {
  final TextEditingController controller;

  /// When provided, an "Auto" button appears that generates a unique barcode
  /// and fills the field. Returns the generated code (or null on failure).
  final Future<String?> Function()? onGenerate;

  const BarcodeToggleField({
    super.key,
    required this.controller,
    this.onGenerate,
  });

  @override
  State<BarcodeToggleField> createState() => BarcodeToggleFieldState();
}

class BarcodeToggleFieldState extends State<BarcodeToggleField> {
  bool _enabled = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.text.isNotEmpty;
  }

  Future<void> _handleAuto() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final code = await widget.onGenerate!.call();
      if (!mounted) return;
      setState(() {
        if (code != null && code.isNotEmpty) {
          widget.controller.text = code;
          _enabled = true;
        }
        _generating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stay open whenever the controller already holds a value — this survives
    // the post-frame edit-prefill that populates the controller after initState.
    final open = _enabled || widget.controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconlyLight.scan,
                size: 16,
                color: open ? AppColors.brand : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              'Barcode',
              style: getOutfitStyle(
                color: open
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Text('(optional)',
                style: getOutfitStyle(
                    color: AppColors.textMuted, fontSize: 11)),
            const Spacer(),
            AppSwitch(
              value: open,
              onChanged: (v) => setState(() {
                _enabled = v;
                if (!v) widget.controller.clear();
              }),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration:
                              appInputDeco('Scan or type barcode').copyWith(
                            prefixIcon: const Icon(IconlyLight.scan,
                                size: 17, color: AppColors.textMuted),
                          ),
                          style: getOutfitStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      if (widget.onGenerate != null) ...[
                        const SizedBox(width: 8),
                        _AutoButton(loading: _generating, onTap: _handleAuto),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

/// Clickable "Auto" text (to the right of the input) that generates a barcode.
class _AutoButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _AutoButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.brand,
                ),
              )
            : Text(
                'Auto',
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
