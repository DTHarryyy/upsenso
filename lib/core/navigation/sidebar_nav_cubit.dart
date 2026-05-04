import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks which settings sub-module is active in the sidebar accordion.
enum SettingsSubPage {
  receipt,
  businessProfile,
  profile,
}

class SidebarNavCubit extends Cubit<SettingsSubPage> {
  SidebarNavCubit() : super(SettingsSubPage.receipt);

  void setSubPage(SettingsSubPage page) {
    if (state != page) emit(page);
  }
}
