import 'package:flutter/material.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/widgets/stock_shortage_dialog.dart';

/// Runs stock preflight and the final atomic checkout for an interactive sale.
/// A null result means the user cancelled the shortage warning.
Future<String?> completeInteractiveSale({
  required BuildContext context,
  required CheckoutService checkoutService,
  required IInventoryRepository inventoryRepository,
  required TransactionsTableCompanion transaction,
  required List<TransactionItemsTableCompanion> transactionItems,
  required List<CartItem> cartItems,
  required String businessId,
  required String? branchId,
  required String transactionId,
}) async {
  final deductions = cartItems
      .map((item) => (variantId: item.variantId, qty: item.qty))
      .toList();
  final shortages = await inventoryRepository.checkStockAvailability(
    items: deductions,
    branchId: branchId,
  );

  var allowOversell = false;
  if (shortages.isNotEmpty) {
    if (!context.mounted) return null;
    allowOversell = await showStockShortageDialog(
      context: context,
      items: cartItems,
      shortages: shortages,
    );
    if (!allowOversell) return null;
  }

  try {
    return await checkoutService.completeSale(
      transaction: transaction,
      items: transactionItems,
      deductions: deductions,
      businessId: businessId,
      branchId: branchId,
      transactionId: transactionId,
      allowOversell: allowOversell,
    );
  } on InsufficientStockException catch (error) {
    // Stock can change on another device after preflight. Re-prompt with the
    // transaction-time values rather than turning the race into a generic
    // save error.
    if (allowOversell || !context.mounted) rethrow;
    final proceed = await showStockShortageDialog(
      context: context,
      items: cartItems,
      shortages: error.shortages,
    );
    if (!proceed) return null;
    return checkoutService.completeSale(
      transaction: transaction,
      items: transactionItems,
      deductions: deductions,
      businessId: businessId,
      branchId: branchId,
      transactionId: transactionId,
      allowOversell: true,
    );
  }
}
