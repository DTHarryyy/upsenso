import 'package:pos/features/settings/domain/receipt_settings.dart';

enum SettingsSaveStatus { idle, saving, saved, error }

class SettingsState {
  final ReceiptSettings? settings;
  final bool isLoading;
  final SettingsSaveStatus saveStatus;
  final String? errorMessage;
  final bool isUploadingLogo;

  const SettingsState({
    this.settings,
    this.isLoading = true,
    this.saveStatus = SettingsSaveStatus.idle,
    this.errorMessage,
    this.isUploadingLogo = false,
  });

  SettingsState copyWith({
    ReceiptSettings? settings,
    bool? isLoading,
    SettingsSaveStatus? saveStatus,
    String? errorMessage,
    bool? isUploadingLogo,
  }) =>
      SettingsState(
        settings: settings ?? this.settings,
        isLoading: isLoading ?? this.isLoading,
        saveStatus: saveStatus ?? this.saveStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
      );

  SettingsState clearError() => SettingsState(
        settings: settings,
        isLoading: isLoading,
        saveStatus: saveStatus,
        isUploadingLogo: isUploadingLogo,
      );
}
