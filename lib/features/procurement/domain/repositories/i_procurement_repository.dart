import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/procurement_settings.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order_line.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';

abstract interface class IProcurementRepository {
  // ── Settings ──────────────────────────────────────────────────────────────

  /// Per-business procurement settings (approval threshold). Defaults to an
  /// unset threshold when no row exists yet.
  Future<ProcurementSettings> getSettings(String businessId);

  /// Sets the PO approval threshold (null clears it → self-approve any amount).
  Future<void> updateApprovalThreshold(String businessId, double? threshold);

  // ── Suppliers ───────────────────────────────────────────────────────────────

  Stream<List<Supplier>> watchSuppliers(String businessId);
  Future<List<Supplier>> getSuppliers(String businessId);
  Future<Supplier?> getSupplierById(String id);

  Future<void> createSupplier({
    required String businessId,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
  });

  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
    bool? isActive,
  });

  Future<void> deleteSupplier(String id);

  // ── Purchase Orders ─────────────────────────────────────────────────────────

  Stream<List<PurchaseOrder>> watchPurchaseOrders(String businessId);
  Future<List<PurchaseOrder>> getPurchaseOrders(String businessId);
  Future<PurchaseOrder?> getPurchaseOrderById(String id);
  Stream<List<PurchaseOrderLine>> watchPurchaseOrderLines(String poId);
  Future<List<PurchaseOrderLine>> getPurchaseOrderLines(String poId);

  /// Creates a new PO in draft status. Returns the generated PO id.
  Future<String> createPurchaseOrder({
    required String businessId,
    String? branchId,
    String? supplierId,
    String? supplierName,
    String? notes,
    DateTime? expectedDelivery,
    double discount,
    double shipping,
    required String createdById,
    required String createdByName,
    required List<PoLineInput> lines,
  });

  Future<void> updatePurchaseOrder({
    required String id,
    String? notes,
    DateTime? expectedDelivery,
    String? supplierId,
    String? supplierName,
    double? discount,
    double? shipping,
    List<PoLineInput>? lines,
  });

  /// draft → submitted
  Future<void> submitPurchaseOrder(String id);

  /// submitted → approved
  Future<void> approvePurchaseOrder({
    required String id,
    required String approvedById,
    required String approvedByName,
  });

  /// Receive goods against an approved PO, updating inventory via
  /// StockMovementService and applying moving-weighted-average costing.
  Future<void> receiveGoods({
    required String poId,
    required String branchId,
    required List<ReceiveLineInput> lines,
  });

  /// Cancel a PO that is still in draft / submitted / approved.
  Future<void> cancelPurchaseOrder(String id);
}
