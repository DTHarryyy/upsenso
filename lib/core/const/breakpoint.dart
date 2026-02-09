import 'package:flutter/widgets.dart';

class Breakpoints {
  static bool isTablet(BuildContext c) => MediaQuery.sizeOf(c).width >= 600;
  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width >= 1024;
}
