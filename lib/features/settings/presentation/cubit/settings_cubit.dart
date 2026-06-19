import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';
import 'package:pos/features/settings/presentation/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final ReceiptSettingsRepository _repo;
  StreamSubscription<ReceiptSettings?>? _sub;

  SettingsCubit(this._repo) : super(const SettingsState());

  /// Start watching local DB for this business.
  /// All named parameters are used to pre-fill defaults on first run
  /// (when no receipt_settings row exists yet in the local DB).
  /// When online, also pulls the latest data from Supabase in the background
  /// so the local DB (and thus the stream) reflects the server state.
  void startWatching({
    required String businessId,
    String? businessName,
    String? branchName,
    String? ownerName,
    String? email,
    String? contactNumber,
    String? address,
  }) {
    _sub?.cancel();
    emit(const SettingsState(isLoading: true));

    _sub = _repo
        .watch(businessId)
        .listen(
          (settings) {
            // Always stamp the live auth values so branch/business name stay
            // current even if the DB row was written under a different branch.
            final effective = (settings ?? ReceiptSettings(
                  id: businessId,
                  businessId: businessId,
                  contactNumber: contactNumber ?? '',
                  address: address ?? '',
                  updatedAt: DateTime.now(),
                )).copyWith(
              businessName: businessName ?? '',
              storeName: branchName ?? '',
              ownerName: ownerName ?? '',
              email: email ?? '',
            );
            emit(
              state.copyWith(
                settings: effective,
                isLoading: false,
                saveStatus: SettingsSaveStatus.idle,
              ),
            );
          },
          onError: (e) {
            emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
          },
        );

    // Fire-and-forget: pull fresh data from Supabase if online.
    // The stream above will automatically emit the updated row once the
    // local DB is written by pullFromServer.
    _pullIfOnline(businessId);
  }

  Future<void> _pullIfOnline(String businessId) async {
    try {
      await _repo.pullFromServer(businessId);
    } catch (e, st) {
      // Non-fatal — local data is still shown; log and move on.
      debugPrint('[SettingsCubit] Remote pull failed: $e\n$st');
    }
  }

  /// Patch the in-memory draft and auto-save to local DB.
  Future<void> update(ReceiptSettings Function(ReceiptSettings) patch) async {
    final current = state.settings;
    if (current == null) return;

    final updated = patch(current);
    // Optimistic UI — emit updated state before save completes
    emit(
      state.copyWith(settings: updated, saveStatus: SettingsSaveStatus.saving),
    );

    try {
      await _repo.save(updated);
      if (!isClosed) {
        emit(state.copyWith(saveStatus: SettingsSaveStatus.saved));
        // Reset to idle after brief delay so UI can show a "Saved" indicator
        await Future.delayed(const Duration(seconds: 2));
        if (!isClosed) {
          emit(state.copyWith(saveStatus: SettingsSaveStatus.idle));
        }
      }
    } catch (e, st) {
      debugPrint('[SettingsCubit] Error in save: $e\n$st');
      if (!isClosed) {
        emit(
          state.copyWith(
            saveStatus: SettingsSaveStatus.error,
            errorMessage: AppErrorMapper.message(e),
          ),
        );
      }
    }
  }

  /// Save a picked logo (offline-first). The repository writes it locally and
  /// queues the upload; the live [watch] stream emits the updated row, so we
  /// don't patch settings by hand here.
  Future<void> uploadLogo({
    required String businessId,
    required Uint8List bytes,
    required String ext,
    required String mimeType,
  }) async {
    emit(state.copyWith(isUploadingLogo: true));
    try {
      await _repo.saveLogo(
        businessId: businessId,
        bytes: bytes,
        ext: ext,
        mimeType: mimeType,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploadingLogo: false,
            saveStatus: SettingsSaveStatus.saved,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[SettingsCubit] Error in uploadLogo: $e\n$st');
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploadingLogo: false,
            errorMessage: AppErrorMapper.message(e),
            saveStatus: SettingsSaveStatus.error,
          ),
        );
      }
    }
  }

  void dismissError() {
    if (!isClosed) emit(state.clearError());
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
