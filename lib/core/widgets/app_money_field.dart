import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';

/// A currency amount field with the app's standard money formatting.
///
/// Consolidates the `TextFormField` + `appInputDeco` + 2-decimal input
/// formatter that was copy-pasted across the product form. Use [emphasized]
/// for the primary selling price (larger, bolder).
class AppMoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String prefixText;
  final bool emphasized;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const AppMoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '0.00',
    this.prefixText = '₱ ',
    this.emphasized = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textInputAction: textInputAction,
      decoration: appInputDeco(hint, label: label, prefixText: prefixText),
      style: getOutfitStyle(
        color: AppColors.textPrimary,
        fontSize: emphasized ? 18 : 16,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
      ),
      validator: validator,
    );
  }
}
