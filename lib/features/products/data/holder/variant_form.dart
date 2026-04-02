import 'package:flutter/material.dart';
class VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController lowStock = TextEditingController();
  final TextEditingController barcode = TextEditingController();

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    lowStock.dispose();
    barcode.dispose();
  }
}