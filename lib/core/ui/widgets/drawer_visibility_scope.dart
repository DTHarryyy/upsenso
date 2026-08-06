import 'package:flutter/widgets.dart';

/// Makes the mobile shell drawer's visibility available to descendants.
///
/// Some page controls render in the root overlay so they can sit above the
/// shell's floating action button. They need this signal to yield to the
/// drawer, which is otherwise painted beneath that overlay.
class DrawerVisibilityScope extends InheritedNotifier<ValueNotifier<bool>> {
  const DrawerVisibilityScope({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns whether the nearest shell drawer is currently open.
  ///
  /// A scope is intentionally optional because tablet and desktop navigation
  /// use the sidebar rather than a drawer.
  static bool isOpenOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DrawerVisibilityScope>()
          ?.notifier
          ?.value ??
      false;
}
