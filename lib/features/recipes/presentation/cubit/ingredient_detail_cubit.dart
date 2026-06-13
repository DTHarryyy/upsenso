import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_state.dart';

class IngredientDetailCubit extends Cubit<IngredientDetailState> {
  final IIngredientsRepository _repository;
  final String businessId;
  final String variantId;

  StreamSubscription? _ingredientSub;
  StreamSubscription? _historySub;

  // Latest snapshots — combined into one emit.
  Ingredient? _ingredient;
  final _history = <StockMovement>[];

  IngredientDetailCubit({
    required IIngredientsRepository repository,
    required this.businessId,
    required Ingredient initialIngredient,
  })  : _repository = repository,
        variantId = initialIngredient.id,
        super(IngredientDetailLoading()) {
    _ingredient = initialIngredient;
  }

  void startWatching() {
    // Watch the full business list and extract this ingredient's entry
    // so name/unit/threshold changes are reflected immediately.
    _ingredientSub =
        _repository.watchByBusinessId(businessId).listen((list) {
      _ingredient =
          list.where((i) => i.id == variantId).firstOrNull;
      _tryEmitLoaded();
    }, onError: (Object e, StackTrace st) {
      debugPrint('[IngredientDetailCubit] ingredient watch error: $e\n$st');
    });

    _historySub = _repository.watchHistory(variantId).listen((history) {
      _history
        ..clear()
        ..addAll(history);
      _tryEmitLoaded();
    }, onError: (Object e, StackTrace st) {
      debugPrint('[IngredientDetailCubit] history watch error: $e\n$st');
    });
  }

  void _tryEmitLoaded() {
    final ing = _ingredient;
    if (ing == null) return;
    emit(IngredientDetailLoaded(
      ingredient: ing,
      history: List.unmodifiable(_history),
    ));
  }

  Future<void> adjustStock({
    required String branchId,
    required bool isIncoming,
    required double quantity,
    required String reason,
    String? note,
  }) async {
    final ing = _ingredient;
    if (ing == null) return;
    try {
      await _repository.adjustStock(
        variantId: variantId,
        productId: ing.productId,
        businessId: businessId,
        branchId: branchId,
        isIncoming: isIncoming,
        quantity: quantity,
        reason: reason,
        note: note,
      );
    } catch (e, st) {
      debugPrint('[IngredientDetailCubit] Error in adjustStock: $e\n$st');
      emit(IngredientDetailError('Failed to update stock.'));
      _tryEmitLoaded();
    }
  }

  @override
  Future<void> close() {
    _ingredientSub?.cancel();
    _historySub?.cancel();
    return super.close();
  }
}
