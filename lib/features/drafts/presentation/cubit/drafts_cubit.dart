import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';
import 'package:pos/features/drafts/presentation/cubit/drafts_state.dart';

/// Drives the Held Sales screen: watches open drafts and discards them.
class DraftsCubit extends Cubit<DraftsState> {
  final IDraftSalesRepository _repository;

  StreamSubscription<List<DraftSale>>? _watcher;

  DraftsCubit(this._repository) : super(const DraftsInitial());

  /// Subscribes to open drafts for [branchId] (all branches when `null`).
  /// Safe to call repeatedly — the prior subscription is cancelled first.
  void startWatching({String? branchId}) {
    _watcher?.cancel();
    emit(const DraftsLoading());

    _watcher = _repository
        .watchOpenDrafts(branchId: branchId)
        .listen(
          (drafts) {
            if (!isClosed) emit(DraftsLoaded(drafts));
          },
          onError: (Object e) {
            if (!isClosed) emit(DraftsError(AppErrorMapper.message(e)));
          },
        );
  }

  Future<void> discard(String id) => _repository.discard(id);

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
