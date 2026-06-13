import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredients_state.dart';

class IngredientsCubit extends Cubit<IngredientsState> {
  final IIngredientsRepository _repository;
  final String businessId;

  StreamSubscription? _subscription;

  IngredientsCubit({
    required IIngredientsRepository repository,
    required this.businessId,
  })  : _repository = repository,
        super(IngredientsInitial());

  void watch() {
    emit(IngredientsLoading());
    _subscription?.cancel();
    _subscription = _repository.watchByBusinessId(businessId).listen(
      (ingredients) {
        final current = state;
        final q = current is IngredientsLoaded ? current.searchQuery : null;
        final filter = current is IngredientsLoaded
            ? current.stockFilter
            : IngredientStockFilter.all;
        emit(IngredientsLoaded(
          ingredients: ingredients,
          searchQuery: q,
          stockFilter: filter,
        ));
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[IngredientsCubit] watch error: $e\n$st');
        emit(IngredientsError('Failed to load ingredients.'));
      },
    );
  }

  void search(String query) {
    final current = state;
    if (current is IngredientsLoaded) {
      emit(current.copyWith(searchQuery: query.isEmpty ? null : query));
    }
  }

  void setFilter(IngredientStockFilter filter) {
    final current = state;
    if (current is IngredientsLoaded) {
      emit(current.copyWith(stockFilter: filter));
    }
  }

  Future<void> create({
    required String name,
    String? unit,
    double openingStock = 0,
    String? branchId,
    int? lowStockAlert,
  }) async {
    final current = state;
    if (current is IngredientsLoaded) {
      emit(IngredientsActionInProgress(current.ingredients));
    }
    try {
      await _repository.create(
        businessId: businessId,
        name: name,
        unit: unit,
        openingStock: openingStock,
        branchId: branchId,
        lowStockAlert: lowStockAlert,
      );
    } catch (e, st) {
      debugPrint('[IngredientsCubit] Error in create: $e\n$st');
      emit(IngredientsError('Failed to save ingredient.'));
      if (current is IngredientsLoaded) {
        emit(IngredientsLoaded(ingredients: current.ingredients));
      }
    }
  }

  Future<void> update({
    required String variantId,
    required String productId,
    required String name,
    String? unit,
    int? lowStockAlert,
  }) async {
    // Optimistic loading indicator only when the list is already visible.
    final current = state;
    if (current is IngredientsLoaded) {
      emit(IngredientsActionInProgress(current.ingredients));
    }
    try {
      await _repository.update(
        variantId: variantId,
        productId: productId,
        name: name,
        unit: unit,
        lowStockAlert: lowStockAlert,
      );
    } catch (e, st) {
      debugPrint('[IngredientsCubit] Error in update: $e\n$st');
      emit(IngredientsError('Failed to update ingredient.'));
      if (current is IngredientsLoaded) {
        emit(IngredientsLoaded(ingredients: current.ingredients));
      }
    }
  }

  Future<void> delete(String productId) async {
    final current = state;
    if (current is IngredientsLoaded) {
      emit(IngredientsActionInProgress(current.ingredients));
    }
    try {
      await _repository.softDelete(productId);
    } catch (e, st) {
      debugPrint('[IngredientsCubit] Error in delete: $e\n$st');
      emit(IngredientsError('Failed to delete ingredient.'));
      if (current is IngredientsLoaded) {
        emit(IngredientsLoaded(ingredients: current.ingredients));
      }
    }
  }

  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String branchId,
    required bool isIncoming,
    required double quantity,
    required String reason,
    String? note,
  }) async {
    try {
      await _repository.adjustStock(
        variantId: variantId,
        productId: productId,
        businessId: businessId,
        branchId: branchId,
        isIncoming: isIncoming,
        quantity: quantity,
        reason: reason,
        note: note,
      );
    } catch (e, st) {
      debugPrint('[IngredientsCubit] Error in adjustStock: $e\n$st');
      final current = state;
      emit(IngredientsError('Failed to update stock.'));
      if (current is IngredientsLoaded) {
        emit(IngredientsLoaded(
          ingredients: current.ingredients,
          searchQuery: current.searchQuery,
          stockFilter: current.stockFilter,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
