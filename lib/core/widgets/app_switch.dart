import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// A premium iOS-style switch with smooth thumb animation and a soft shadow.
/// 44×26 track, 22 thumb. Use this in place of [Switch.adaptive] for SaaS-grade polish.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Semantics(
      toggled: value,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!value),
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 26,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? AppColors.brand : AppColors.borderSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A101828),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Color(0x0F101828),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
