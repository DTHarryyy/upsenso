import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/features/insights/data/insights_repository.dart';
import 'package:pos/features/insights/presentation/cubit/insights_state.dart';

/// Drives the dashboard insight card. Loads today's permission-scoped insights
/// for the active business/branch; failures surface as [InsightsError] so the
/// card can degrade gracefully instead of failing silently.
class InsightsCubit extends Cubit<InsightsState> {
  final InsightsRepository _repository;

  InsightsCubit(this._repository) : super(const InsightsInitial());

  Future<void> load({
    required String businessId,
    required String cashierId,
    required String? branchId,
  }) async {
    emit(const InsightsLoading());
    try {
      final insights = await _repository.loadInsights(
        businessId: businessId,
        cashierId: cashierId,
        branchId: branchId,
      );
      if (isClosed) return;
      emit(InsightsLoaded(insights));
    } catch (e, st) {
      debugPrint('[Insights] Error in load: $e\n$st');
      if (isClosed) return;
      emit(const InsightsError());
    }
  }
}
