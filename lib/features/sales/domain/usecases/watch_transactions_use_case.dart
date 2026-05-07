import 'package:pos/features/sales/domain/entities/sale_transaction.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';

class WatchTransactionsUseCase {
  final ISalesRepository _repository;
  const WatchTransactionsUseCase(this._repository);

  Stream<List<SaleTransaction>> call({String? branchId}) =>
      _repository.watchTransactions(branchId: branchId);
}
