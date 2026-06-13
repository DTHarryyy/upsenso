import 'package:pos/features/recipes/domain/entities/ingredient.dart';

enum IngredientStockFilter { all, lowStock, outOfStock }

sealed class IngredientsState {}

class IngredientsInitial extends IngredientsState {}

class IngredientsLoading extends IngredientsState {}

class IngredientsLoaded extends IngredientsState {
  final List<Ingredient> ingredients;
  final String? searchQuery;
  final IngredientStockFilter stockFilter;

  IngredientsLoaded({
    required this.ingredients,
    this.searchQuery,
    this.stockFilter = IngredientStockFilter.all,
  });

  List<Ingredient> get filtered {
    var list = ingredients;
    final q = searchQuery?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    return switch (stockFilter) {
      IngredientStockFilter.all => list,
      IngredientStockFilter.lowStock => list
          .where((i) => i.lowStockAlert != null && i.stock <= i.lowStockAlert!)
          .toList(),
      IngredientStockFilter.outOfStock =>
        list.where((i) => i.stock <= 0).toList(),
    };
  }

  int get lowStockCount => ingredients
      .where((i) => i.lowStockAlert != null && i.stock <= i.lowStockAlert!)
      .length;

  int get outOfStockCount => ingredients.where((i) => i.stock <= 0).length;

  IngredientsLoaded copyWith({
    List<Ingredient>? ingredients,
    String? searchQuery,
    bool clearSearch = false,
    IngredientStockFilter? stockFilter,
  }) {
    return IngredientsLoaded(
      ingredients: ingredients ?? this.ingredients,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      stockFilter: stockFilter ?? this.stockFilter,
    );
  }
}

class IngredientsActionInProgress extends IngredientsState {
  final List<Ingredient> ingredients;
  IngredientsActionInProgress(this.ingredients);
}

class IngredientsError extends IngredientsState {
  final String message;
  IngredientsError(this.message);
}
