/// A single entry from the stock ledger for an ingredient.
class StockMovement {
  final String id;
  final String changeType; // 'IN' | 'OUT'
  final double quantity;
  final double? quantityBefore;
  final double? quantityAfter;
  final String reason;
  final String? note;
  final DateTime createdAt;
  final String? sourceType;

  const StockMovement({
    required this.id,
    required this.changeType,
    required this.quantity,
    this.quantityBefore,
    this.quantityAfter,
    required this.reason,
    this.note,
    required this.createdAt,
    this.sourceType,
  });

  bool get isIncoming => changeType == 'IN';
}
