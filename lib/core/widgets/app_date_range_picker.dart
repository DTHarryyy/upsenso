import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class AppDateRangePicker extends StatelessWidget {
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateRangePicker({
    super.key,
    required this.onChanged,
    this.value,
    this.placeholder = 'Date Range',
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      initialDateRange: value,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: AppColors.textInverse,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            secondaryContainer: AppColors.brandSoft,
            onSecondaryContainer: AppColors.brand,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  String get _label {
    if (value == null) return placeholder;
    final s = value!.start;
    final e = value!.end;
    String fmt(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(s)} – ${fmt(e)}';
  }

  bool get _hasValue => value != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: _hasValue ? AppColors.brandSoft : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasValue ? AppColors.brand : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Icon(
              IconlyLight.calendar,
              size: 16,
              color: _hasValue ? AppColors.brand : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _label,
                style: getOutfitStyle(
                  fontSize: 13,
                  color: _hasValue ? AppColors.brand : AppColors.textMuted,
                  fontWeight:
                      _hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hasValue)
              GestureDetector(
                onTap: () => onChanged(null),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(IconlyLight.close_square,
                      size: 14, color: AppColors.brand),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
