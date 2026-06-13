import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';

sealed class IngredientDetailState {}

class IngredientDetailLoading extends IngredientDetailState {}

class IngredientDetailLoaded extends IngredientDetailState {
  final Ingredient ingredient;
  final List<StockMovement> history;

  IngredientDetailLoaded({
    required this.ingredient,
    required this.history,
  });

  IngredientDetailLoaded copyWith({
    Ingredient? ingredient,
    List<StockMovement>? history,
  }) {
    return IngredientDetailLoaded(
      ingredient: ingredient ?? this.ingredient,
      history: history ?? this.history,
    );
  }
}

class IngredientDetailError extends IngredientDetailState {
  final String message;
  IngredientDetailError(this.message);
}
