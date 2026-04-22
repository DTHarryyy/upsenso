import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/data/reports_repository.dart';
import 'package:pos/features/reports/presentation/cubit/reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository _repository;

  StreamSubscription<void>? _watcher;
  String? _businessId;
  String? _branchId;
  ReportPeriod _period = ReportPeriod.last7Days;
  bool _isLoading = false;
  bool _pendingReload = false;

  ReportsCubit(this._repository) : super(const ReportsInitial());

  /// Call this on first load and whenever businessId or branchId changes.
  /// Sets up the live-data watcher so reports auto-update on every sale.
  Future<void> startWatching({
    required String businessId,
    String? branchId,
    required ReportPeriod period,
  }) async {
    _businessId = businessId;
    _branchId = branchId;
    _period = period;

    await _watcher?.cancel();

    // Wire up the watcher BEFORE the initial load so any transaction inserted
    // during the load is captured and triggers a follow-up reload.
    _watcher = _repository
        .watchChanges(businessId: businessId)
        .listen((_) => _doLoad(showSpinner: false));

    await _doLoad(showSpinner: true);
  }

  /// Call when the user picks a different time period.
  Future<void> changePeriod(ReportPeriod period) async {
    _period = period;
    await _doLoad(showSpinner: true);
  }

  /// Call when the branch filter changes.
  Future<void> changeBranch(String? branchId) async {
    _branchId = branchId;
    await _doLoad(showSpinner: true);
  }

  Future<void> _doLoad({required bool showSpinner}) async {
    if (isClosed) return;
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) return;

    // Coalesce rapid updates: if already loading, flag a pending reload instead.
    if (_isLoading) {
      _pendingReload = true;
      return;
    }

    _isLoading = true;
    _pendingReload = false;

    if (showSpinner) emit(const ReportsLoading());

    try {
      final data = await _repository.load(
        businessId: businessId,
        branchId: _branchId,
        period: _period,
      );
      if (!isClosed) emit(ReportsLoaded(data));
    } catch (e) {
      if (!isClosed) emit(ReportsError(AppErrorMapper.message(e)));
    } finally {
      _isLoading = false;
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
