import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_modal.dart';

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

  /// Fraction of available height the sheet may grow to before the body scrolls.
  final double maxHeightFactor;

  /// When true the sheet always fills [maxHeightFactor] of the available height
  /// (rather than hugging its content) and the body expands to fill the gap.
  /// Use for long forms so they open at a stable, predictable height.
  final bool fullHeight;

  const AppBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.titleTrailing,
    this.action,
    this.maxHeightFactor = 0.85,
    this.fullHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppModalPresentation.isDialogOf(context)
        ? _buildDialog(context)
        : _buildSheet(context);
  }

  // Phone: rounded-top sheet with a grab handle, anchored to the bottom edge.
  Widget _buildSheet(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Subtract the status-bar inset so a full-height sheet never slips under it.
    final maxHeight = (media.size.height - media.padding.top) * maxHeightFactor;

    return Container(
      height: fullHeight ? maxHeight : null,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: fullHeight ? MainAxisSize.max : MainAxisSize.min,
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
          _titleRow(),
          if (fullHeight) Expanded(child: child) else Flexible(child: child),
          if (action != null) _actionArea(),
        ],
      ),
    );
  }

  // Tablet / desktop: a centred, content-sized card (presented by [showAppModal]
  // inside a [Dialog] that handles centring, width and the keyboard inset).
  Widget _buildDialog(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 18),
            _titleRow(),
            Flexible(child: child),
            if (action != null) _actionArea(),
          ],
        ),
      ),
    );
  }

  Widget _titleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
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
    );
  }

  Widget _actionArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: action!,
    );
  }
}
