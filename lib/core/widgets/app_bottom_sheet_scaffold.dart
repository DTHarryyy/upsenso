import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Standard modal bottom-sheet shell: grab handle, title row, scrollable body
/// and an optional pinned action at the bottom.
///
/// Replaces the copy-pasted handle/title/inset boilerplate in the procurement
/// sheets so every sheet looks and behaves identically and respects the
/// keyboard inset. Present via `showModalBottomSheet(isScrollControlled: true,
/// backgroundColor: Colors.transparent, ...)`.
class AppBottomSheetScaffold extends StatelessWidget {
  final String title;

  /// Optional trailing widget in the title row (e.g. a count badge).
  final Widget? titleTrailing;

  final Widget child;

  /// Pinned action shown below the body (e.g. a confirm button). Not scrolled.
  final Widget? action;

  /// Fraction of screen height the sheet may grow to before the body scrolls.
  final double maxHeightFactor;

  const AppBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.titleTrailing,
    this.action,
    this.maxHeightFactor = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: getOutfitStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ?titleTrailing,
              ],
            ),
          ),
          Flexible(child: child),
          if (action != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: action!,
            ),
        ],
      ),
    );
  }
}
