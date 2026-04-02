import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';

class BarcodeToggleField extends StatefulWidget {
  final TextEditingController controller;
  const BarcodeToggleField({super.key,required this.controller});

  @override
  State<BarcodeToggleField> createState() => BarcodeToggleFieldState();
}

class BarcodeToggleFieldState extends State<BarcodeToggleField> {
  bool _enabled = false; 

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code_rounded,
                size: 16,
                color: _enabled ? AppColors.brand : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              'Barcode',
              style: getOutfitStyle(
                color: _enabled
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
            Switch.adaptive(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              activeThumbColor: AppColors.brand,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: appInputDeco('Scan or type barcode').copyWith(
                      prefixIcon: const Icon(Icons.qr_code_rounded,
                          size: 17, color: AppColors.textMuted),
                    ),
                    style: getOutfitStyle(color: AppColors.textPrimary),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
