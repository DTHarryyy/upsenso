import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';

/// A reusable [DropdownButtonFormField] styled to match the app's input theme.
///
/// Type parameter [T] is the value type of each item.
///
/// ```dart
/// AppDropdown<String>(
///   value: _selectedId,
///   hint: 'Select category',
///   items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
///   onChanged: (v) => setState(() => _selectedId = v),
/// )
/// ```
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final double radius;

  const AppDropdown({
    super.key,
    this.value,
    this.hint,
    required this.items,
    this.onChanged,
    this.validator,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      hint: hint != null
          ? Text(hint!, style: getOutfitStyle(color: AppColors.textMuted))
          : null,
      isExpanded: true,
      decoration: appInputDeco(null, radius: radius).copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: AppColors.surface,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textMuted,
      ),
      style: getOutfitStyle(color: AppColors.textPrimary),
    );
  }
}
