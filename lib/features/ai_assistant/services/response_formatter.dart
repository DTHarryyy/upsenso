import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';

/// Layer 10 — Response Layer: Converts results into user-friendly messages.
class AiResponseFormatter {
  static const String _currency = '₱';

  /// Format a date label for display (e.g. "today", "Mar 10", "Mar 1 – Mar 7").
  static String _dateLabel(AiDateFilter filter) {
    switch (filter.type) {
      case AiDateType.today:
        return 'today';
      case AiDateType.specific:
        if (filter.value != null) {
          final d = filter.value!;
          return '${_monthName(d.month)} ${d.day}';
        }
        return '';
      case AiDateType.range:
        final s = filter.start;
        final e = filter.end;
        if (s != null && e != null) {
          return '${_monthName(s.month)} ${s.day} – ${_monthName(e.month)} ${e.day}';
        }
        return '';
      case AiDateType.none:
        return '';
    }
  }

  static String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month.clamp(1, 12)];
  }

  static String formatSalesTotal(double total, AiDateFilter filter) {
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Total sales for $label: $_currency${_formatNumber(total)}';
    }
    return 'Total sales: $_currency${_formatNumber(total)}';
  }

  static String formatSalesByCategory(
    List<CategorySalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }

    final label = _dateLabel(filter);
    final header = label.isNotEmpty
        ? 'Sales by category ($label):\n'
        : 'Sales by category:\n';
    final buffer = StringBuffer(header);

    double grandTotal = 0;
    for (final r in results) {
      buffer.writeln('• ${r.category}: $_currency${_formatNumber(r.total)}');
      grandTotal += r.total;
    }
    buffer.writeln();
    buffer.write('Total: $_currency${_formatNumber(grandTotal)}');

    return buffer.toString();
  }

  static String formatSalesByProduct(
    List<ProductSalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }

    final label = _dateLabel(filter);
    final header = label.isNotEmpty
        ? 'Sales by product ($label):\n'
        : 'Sales by product:\n';
    final buffer = StringBuffer(header);

    double grandTotal = 0;
    for (final r in results) {
      buffer.writeln(
        '• ${r.productName}: $_currency${_formatNumber(r.total)}'
        ' (${_formatQty(r.quantity)} sold)',
      );
      grandTotal += r.total;
    }
    buffer.writeln();
    buffer.write('Total: $_currency${_formatNumber(grandTotal)}');

    return buffer.toString();
  }

  static String formatCategorySales(
    String category,
    double total,
    AiDateFilter filter,
  ) {
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Sales for "$category" ($label): $_currency${_formatNumber(total)}';
    }
    return 'Sales for "$category": $_currency${_formatNumber(total)}';
  }

  static String formatProductSales(
    ProductSalesResult result,
    AiDateFilter filter,
  ) {
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Sales for "${result.productName}" ($label): '
          '$_currency${_formatNumber(result.total)} '
          '(${_formatQty(result.quantity)} sold)';
    }
    return 'Sales for "${result.productName}": '
        '$_currency${_formatNumber(result.total)} '
        '(${_formatQty(result.quantity)} sold)';
  }

  static String formatProductSalesNotFound(
    String productName,
    AiDateFilter filter,
  ) {
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'No sales found for "$productName" ($label).';
    }
    return 'No sales found for "$productName".';
  }

  static String formatHighestCategory(
    List<CategorySalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }
    final top = results.first;
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Highest selling category ($label): '
          '${top.category} with $_currency${_formatNumber(top.total)}';
    }
    return 'Highest selling category: '
        '${top.category} with $_currency${_formatNumber(top.total)}';
  }

  static String formatLowestCategory(
    List<CategorySalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }
    final bottom = results.last;
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Lowest selling category ($label): '
          '${bottom.category} with $_currency${_formatNumber(bottom.total)}';
    }
    return 'Lowest selling category: '
        '${bottom.category} with $_currency${_formatNumber(bottom.total)}';
  }

  static String formatHighestProduct(
    List<ProductSalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }
    final top = results.first;
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Top selling product ($label): '
          '${top.productName} with $_currency${_formatNumber(top.total)} '
          '(${_formatQty(top.quantity)} sold)';
    }
    return 'Top selling product: '
        '${top.productName} with $_currency${_formatNumber(top.total)} '
        '(${_formatQty(top.quantity)} sold)';
  }

  static String formatLowestProduct(
    List<ProductSalesResult> results,
    AiDateFilter filter,
  ) {
    if (results.isEmpty) {
      final label = _dateLabel(filter);
      return label.isNotEmpty
          ? 'No sales data found for $label.'
          : 'No sales data found.';
    }
    final bottom = results.last;
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'Lowest selling product ($label): '
          '${bottom.productName} with $_currency${_formatNumber(bottom.total)} '
          '(${_formatQty(bottom.quantity)} sold)';
    }
    return 'Lowest selling product: '
        '${bottom.productName} with $_currency${_formatNumber(bottom.total)} '
        '(${_formatQty(bottom.quantity)} sold)';
  }

  static String formatProductCount(int count) {
    return 'You have $count active product${count == 1 ? '' : 's'} in your inventory.';
  }

  static String formatProductsWithoutSales(
    List<ActiveProductInfo> products,
    AiDateFilter filter,
  ) {
    final label = _dateLabel(filter);
    if (products.isEmpty) {
      return label.isNotEmpty
          ? 'All products have sales for $label! Great job!'
          : 'All products have sales! Great job!';
    }

    final header = label.isNotEmpty
        ? '${products.length} product${products.length == 1 ? '' : 's'} with no sales ($label):\n'
        : '${products.length} product${products.length == 1 ? '' : 's'} with no sales:\n';
    final buffer = StringBuffer(header);

    for (final p in products) {
      final variant = p.variantName != 'Default' ? ' (${p.variantName})' : '';
      buffer.writeln(
        '• ${p.name}$variant — $_currency${_formatNumber(p.price)}'
        ' | Stock: ${p.stock}',
      );
    }
    return buffer.toString().trim();
  }

  static String formatActiveProducts(List<ActiveProductInfo> products) {
    if (products.isEmpty) {
      return 'No active products found in your inventory.';
    }

    final buffer = StringBuffer(
      '${products.length} active product${products.length == 1 ? '' : 's'}:\n',
    );
    for (final p in products) {
      final variant = p.variantName != 'Default' ? ' (${p.variantName})' : '';
      buffer.writeln(
        '• ${p.name}$variant — $_currency${_formatNumber(p.price)}'
        ' | Stock: ${p.stock}',
      );
    }
    return buffer.toString().trim();
  }

  static String formatTransactionCount(int count, AiDateFilter filter) {
    final label = _dateLabel(filter);
    if (label.isNotEmpty) {
      return 'You have $count transaction${count == 1 ? '' : 's'} for $label.';
    }
    return 'You have $count transaction${count == 1 ? '' : 's'}.';
  }

  static String formatExpensesUnavailable() {
    return 'Expense tracking is not set up yet. '
        'This feature will be available in a future update.';
  }

  static String formatTransactionCreated(String txId) {
    return 'Transaction created successfully! 🎉';
  }

  static String formatTransactionCancelled() {
    return 'Transaction cancelled.';
  }

  static String formatUnknownIntent() {
    return "I'm not sure what you mean. You can ask me about:\n"
        "• Sales — \"how much are my sales today\"\n"
        "• Sales by category — \"sales per category\"\n"
        "• Sales by product — \"sales by product this week\"\n"
        '• Product count — "how many products"\n'
        '• Active products — "show active products"\n'
        '• Unsold products — "products without sales"\n'
        '• Transaction count — "how many transactions"\n'
        '• Create a sale — "2 coke, 1 chips"';
  }

  static String formatError(String message) {
    return 'Sorry, something went wrong: $message';
  }

  static String formatUnmatchedProducts(
    List<String> names, {
    List<String> catalogNames = const [],
  }) {
    if (names.isEmpty) return '';
    final joined = names.map((n) => '"$n"').join(', ');
    final buffer = StringBuffer(
      "I couldn't find these products: $joined.\n",
    );

    if (catalogNames.isNotEmpty) {
      // Suggest up to 5 product names so the user can pick the right one
      final suggestions = catalogNames.take(5).map((n) => '"$n"').join(', ');
      buffer.write(
        '\nAvailable products include: $suggestions'
        '${catalogNames.length > 5 ? ' and ${catalogNames.length - 5} more' : ''}.'
        '\n\nTip: Try using the exact product name, or a shorter keyword.',
      );
    } else {
      buffer.write('Please check the names and try again.');
    }

    return buffer.toString();
  }

  static String formatPreviewMessage(AiTransactionPreview preview) {
    if (preview.matchedProducts.isEmpty) {
      return formatUnmatchedProducts(preview.unmatchedNames);
    }

    final buffer = StringBuffer('Here\'s what I found:\n\n');
    for (final p in preview.matchedProducts) {
      buffer.writeln(
        '• ${p.productName}'
        '${p.variantName != 'Default' ? ' (${p.variantName})' : ''}'
        ' × ${_formatQty(p.quantity)}'
        ' — $_currency${_formatNumber(p.lineTotal)}',
      );
    }

    buffer.writeln();
    buffer.writeln('Subtotal: $_currency${_formatNumber(preview.subtotal)}');
    if (preview.totalTax > 0) {
      buffer.writeln('Tax: $_currency${_formatNumber(preview.totalTax)}');
    }
    buffer.writeln('Total: $_currency${_formatNumber(preview.grandTotal)}');

    if (preview.unmatchedNames.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'Note: Could not find ${preview.unmatchedNames.map((n) => '"$n"').join(', ')}.',
      );
    }

    return buffer.toString().trim();
  }

  static String _formatNumber(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+\.)'),
      (m) => '${m[1]},',
    );
  }

  static String _formatQty(double qty) {
    if (qty == qty.toInt().toDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }
}
