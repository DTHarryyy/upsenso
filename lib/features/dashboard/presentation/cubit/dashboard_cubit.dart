import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/features/dashboard/data/dashboard_repository.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  StreamSubscription<void>? _watcher;
  String? _businessId;
  String? _branchId;
  bool _isLoading = false;
  bool _pendingReload = false;

  DashboardCubit(this._repository) : super(const DashboardInitial());

  /// Call this once (and again whenever businessId/branchId changes).
  /// Sets up the transaction watcher so the dashboard auto-updates on every sale.
  Future<void> startWatching({
    required String businessId,
    String? branchId,
  }) async {
    _businessId = businessId;
    _branchId = branchId;

    // Cancel any previous watcher first
    await _watcher?.cancel();

    // Initial full load (shows spinner)
    await _doLoad(showSpinner: true);

    // Watch for any transaction change → silent refresh
    _watcher = _repository.watchChanges().listen((_) {
      _doLoad(showSpinner: false);
    });
  }

  Future<void> _doLoad({required bool showSpinner}) async {
    if (isClosed) return;
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) return;

    if (_isLoading) {
      _pendingReload = true;
      return;
    }

    _isLoading = true;
    _pendingReload = false;

    if (showSpinner) emit(const DashboardLoading());

    try {
      final data = await _repository.load(
        businessId: businessId,
        branchId: _branchId,
      );
      if (!isClosed) emit(DashboardLoaded(data));
    } catch (e) {
      if (!isClosed) emit(DashboardError(e.toString()));
    } finally {
      _isLoading = false;
      // If another change came in while we were loading, reload now
      if (_pendingReload && !isClosed) {
        _pendingReload = false;
        _doLoad(showSpinner: false);
      }
    }
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
