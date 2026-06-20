import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

/// Single, atomic entry point for refunding part or all of a completed sale.
///
/// Mirrors [CheckoutService]: every read used for validation plus every write
/// (refund rows, status flip, restock) happens inside one DB transaction, so
/// a crash partway through can never leave money refunded without stock
/// restored, or vice-versa.
class RefundService {
  final AppDatabase _db;
  final TransactionsDao _transactionsDao;
  final RefundsDao _refundsDao;
  final IInventoryRepository _inventoryRepository;
  final PermissionService _permissionService;
  final AuditLogService _auditLogService;

  static const _uuid = Uuid();

  RefundService({
    required AppDatabase db,
    required TransactionsDao transactionsDao,
    required RefundsDao refundsDao,
    required IInventoryRepository inventoryRepository,
    required PermissionService permissionService,
    required AuditLogService auditLogService,
  }) : _db = db,
       _transactionsDao = transactionsDao,
       _refundsDao = refundsDao,
       _inventoryRepository = inventoryRepository,
       _permissionService = permissionService,
       _auditLogService = auditLogService;

  /// Refunds [lines] (transaction-item id, qty to return, and whether that
  /// qty goes back to sellable stock) against [transactionId]. Returns the
  /// new refund's id.
  ///
  /// [restock] lets the refunder mark a damaged/expired/opened return as NOT
  /// going back to inventory — restocking every refund unconditionally would
  /// silently inflate stock for goods that can't actually be resold.
  ///
  /// Hidden UI is not access control — this is the actual enforcement point
  /// for `pos.refund_sale`, regardless of what the caller's UI shows.
  Future<String> refund({
    required String transactionId,
    required List<({String transactionItemId, double qty, bool restock})> lines,
    required String businessId,
    required String refundedBy,
    String? reason,
  }) async {
    if (!_permissionService.hasPermission(AppPermission.refundSale)) {
      throw const RefundPermissionDeniedException();
    }
    final validLines = lines.where((l) => l.qty > 0).toList();
    if (validLines.isEmpty) {
      throw const RefundValidationException('No items selected to refund.');
    }

    final refundId = _uuid.v4();
    double totalAmount = 0;
    double taxAmount = 0;
    String? branchId;
    int itemCount = 0;
    int restockedCount = 0;

    await _db.transaction(() async {
      final tx = await _transactionsDao.getById(transactionId);
      if (tx == null) {
        throw const RefundValidationException('Original sale not found.');
      }
      // Tenant guard: never refund a sale that belongs to a different
      // business than the caller's active one (mirrors AuditLogService).
      if (tx.businessId != null && tx.businessId != businessId) {
        throw const RefundValidationException(
          'Sale does not belong to the active business.',
        );
      }
      // Restock must happen at the SAME branch the sale deducted from, not
      // whichever branch happens to be active on the refunding device.
      branchId = tx.branchId;

      final soldItems = await _transactionsDao.getItemsByTransactionId(
        transactionId,
      );
      final soldById = {for (final i in soldItems) i.id: i};
      final alreadyRefunded = await _refundsDao.getRefundedQtyByTransactionId(
        transactionId,
      );

      final overRefunded = <String>[];
      final itemCompanions = <RefundItemsTableCompanion>[];
      final deductions = <({String variantId, double qty})>[];
      final newlyRefunded = <String, double>{};

      for (final line in validLines) {
        final sold = soldById[line.transactionItemId];
        if (sold == null) continue;
        final priorQty = alreadyRefunded[line.transactionItemId] ?? 0.0;
        if (priorQty + line.qty > sold.qty + 1e-6) {
          overRefunded.add(line.transactionItemId);
          continue;
        }

        final unitTotal = sold.qty == 0 ? 0.0 : sold.lineTotal / sold.qty;
        final unitTax = sold.qty == 0 ? 0.0 : sold.lineTax / sold.qty;
        final lineAmount = unitTotal * line.qty;
        final lineTax = unitTax * line.qty;
        totalAmount += lineAmount;
        taxAmount += lineTax;

        itemCompanions.add(
          RefundItemsTableCompanion.insert(
            id: _uuid.v4(),
            refundId: refundId,
            transactionItemId: line.transactionItemId,
            variantId: sold.variantId,
            qty: line.qty,
            amount: lineAmount,
            restocked: Value(line.restock),
          ),
        );
        if (line.restock) {
          deductions.add((variantId: sold.variantId, qty: line.qty));
          restockedCount++;
        }
        newlyRefunded[line.transactionItemId] = line.qty;
      }

      if (overRefunded.isNotEmpty) {
        throw RefundOverRefundException(overRefunded);
      }
      if (itemCompanions.isEmpty) {
        throw const RefundValidationException('Nothing to refund.');
      }
      itemCount = itemCompanions.length;

      await _refundsDao.insertRefund(
        RefundsTableCompanion.insert(
          id: refundId,
          transactionId: transactionId,
          businessId: businessId,
          branchId: Value(branchId),
          refundedBy: refundedBy,
          totalAmount: totalAmount,
          taxAmount: Value(taxAmount),
          reason: Value(reason),
        ),
        itemCompanions,
      );

      await _transactionsDao.updateStatus(
        transactionId,
        _resolveStatus(soldItems, alreadyRefunded, newlyRefunded),
      );

      await _inventoryRepository.reverseSaleDeductions(
        items: deductions,
        businessId: businessId,
        branchId: branchId,
        sourceId: refundId,
      );
    });

    await _auditLogService.log(
      actionType: AuditLogActionType.refundCreated,
      entityType: 'refund',
      entityId: refundId,
      description:
          'Refunded $itemCount item(s) '
          '(\$${totalAmount.toStringAsFixed(2)}) for transaction $transactionId',
      metadata: {
        'transaction_id': transactionId,
        'total_amount': totalAmount,
        'tax_amount': taxAmount,
        'item_count': itemCount,
        'restocked_line_count': restockedCount,
        'not_restocked_line_count': itemCount - restockedCount,
        'reason': ?reason,
      },
      businessId: businessId,
      branchId: branchId,
      userId: refundedBy,
    );

    return refundId;
  }

  /// A line is fully refunded once `priorRefunded + newlyRefunded >= sold qty`.
  /// The sale is `refunded` when every line is, `partially_refunded` when
  /// some but not all are, else unchanged (`completed`).
  String _resolveStatus(
    List<TransactionItemsTableData> soldItems,
    Map<String, double> priorRefunded,
    Map<String, double> newlyRefunded,
  ) {
    var allFullyRefunded = true;
    var anyRefunded = false;
    for (final item in soldItems) {
      final total =
          (priorRefunded[item.id] ?? 0.0) + (newlyRefunded[item.id] ?? 0.0);
      if (total > 0) anyRefunded = true;
      if (total < item.qty - 1e-6) allFullyRefunded = false;
    }
    if (allFullyRefunded) return 'refunded';
    if (anyRefunded) return 'partially_refunded';
    return 'completed';
  }
}

/// Raised when the current user lacks `pos.refund_sale`.
class RefundPermissionDeniedException implements Exception {
  const RefundPermissionDeniedException();

  @override
  String toString() =>
      'RefundPermissionDeniedException: missing pos.refund_sale permission';
}

/// Raised for any non-stock validation failure (missing sale, empty
/// selection, cross-tenant access).
class RefundValidationException implements Exception {
  final String message;
  const RefundValidationException(this.message);

  @override
  String toString() => 'RefundValidationException: $message';
}

/// Raised when one or more lines would refund more than was sold. Carries
/// the offending `transaction_item_id`s so the UI can point at them.
class RefundOverRefundException implements Exception {
  final List<String> transactionItemIds;
  const RefundOverRefundException(this.transactionItemIds);

  @override
  String toString() =>
      'RefundOverRefundException: ${transactionItemIds.length} line(s) exceed sold quantity';
}
