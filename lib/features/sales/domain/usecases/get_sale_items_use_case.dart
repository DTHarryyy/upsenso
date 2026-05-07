import 'package:pos/features/sales/domain/entities/sale_item.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';

class GetSaleItemsUseCase {
  final ISalesRepository _repository;
  const GetSaleItemsUseCase(this._repository);

  Future<List<SaleItem>> call(String transactionId) =>
      _repository.getTransactionItems(transactionId);
}
