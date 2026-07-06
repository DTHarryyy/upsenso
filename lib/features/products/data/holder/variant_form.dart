import 'package:flutter/material.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

class VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();

  /// Suggested retail price (SRP) for this variant — optional.
  final TextEditingController retail = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController lowStock = TextEditingController();

  /// Multiple barcodes for this variant (starts with one empty row).
  final List<TextEditingController> barcodes = [TextEditingController()];

  /// Per-variant concrete recipe lines — edited directly by the user.
  List<RecipeLineFormEntry> recipeLines = [];

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    retail.dispose();
    stock.dispose();
    lowStock.dispose();
    for (final c in barcodes) {
      c.dispose();
    }
  }
}
