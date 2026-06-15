import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';

/// Marks the subtree as being presented inside a centred dialog rather than a
/// bottom sheet. [AppBottomSheetScaffold] reads this to switch its chrome
/// (all-corner radius, no grab handle) so the same content renders correctly in
/// both presentations.
class AppModalPresentation extends InheritedWidget {
  final bool isDialog;

  const AppModalPresentation({
    required this.isDialog,
    required super.child,
    super.key,
  });

  static bool isDialogOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppModalPresentation>()
          ?.isDialog ??
      false;

  @override
  bool updateShouldNotify(AppModalPresentation oldWidget) =>
      oldWidget.isDialog != isDialog;
}

/// Presents [builder] adaptively: a bottom sheet on phones, a centred dialog on
/// tablet/desktop. Keeps the premium SaaS feel on big screens where a sheet
/// sliding from the bottom edge feels wrong.
///
/// The same content widget works in both — present it through this helper and
/// build its body with [AppBottomSheetScaffold], which adapts automatically.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  if (Breakpoints.isPhone(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      useRootNavigator: useRootNavigator,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    barrierColor: AppColors.overlay,
    barrierDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => AppModalPresentation(
      isDialog: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxDialogWidth(dialogContext),
          ),
          child: builder(dialogContext),
        ),
      ),
    ),
  );
}
