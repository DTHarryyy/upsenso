import 'package:pos/features/sales/domain/entities/sale_item.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';

abstract class ISalesRepository {
  /// Live stream of all transactions, optionally scoped to a [branchId].
  Stream<List<SaleTransaction>> watchTransactions({String? branchId});

  /// Fetches the line items for a single transaction.
  Future<List<SaleItem>> getTransactionItems(String transactionId);
}
