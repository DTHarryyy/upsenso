import 'package:flutter/material.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

class VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController lowStock = TextEditingController();
  final TextEditingController barcode = TextEditingController();

  /// Per-variant concrete recipe lines — edited directly by the user.
  List<RecipeLineFormEntry> recipeLines = [];

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    lowStock.dispose();
    barcode.dispose();
  }
}
