import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sticky_action_bar.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/procurement/domain/entities/approval_policy.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';

/// What to do with a newly-created PO once it's saved: leave it as a draft,
/// route it for approval, or (for approvers) approve it immediately.
enum _SaveMode { draft, submit, approve }

/// Create or edit a Purchase Order.
///
/// When [po] is null a new draft is created. When non-null the existing draft
/// is updated. Only drafts may be edited.
///
/// Suppliers and product variants are loaded asynchronously on open.
class PoFormPage extends StatefulWidget {
  final PurchaseOrder? po;
  final String businessId;

  /// Pre-selects a supplier when creating a new PO (e.g. opened from the
  /// supplier detail page). Ignored in edit mode.
  final Supplier? initialSupplier;

  const PoFormPage({
    super.key,
    this.po,
    required this.businessId,
    this.initialSupplier,
  });

  @override
  State<PoFormPage> createState() => _PoFormPageState();
}

class _PoFormPageState extends State<PoFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _supplierId;
  String? _supplierName;
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  DateTime? _expectedDelivery;
  final List<_LineEntry> _lines = [];
  bool _saving = false;

  List<Supplier> _suppliers = [];
  List<ProductVariantsTableData> _variants = [];
  Map<String, ProductsTableData> _productsById = {};
  bool _loadingData = true;
  // A load failure must not silently leave a blank form — it flips this so the
  // body shows a graceful error with a retry instead.
  bool _loadError = false;
  // PO approval threshold for this business (null = unset). Decides whether the
  // creator can instant-approve or must route for a separate approver.
  double? _approvalThreshold;

  bool get _isEdit => widget.po != null;

  Future<void> _loadFormData() async {
    if (mounted) {
      setState(() {
        _loadingData = true;
        _loadError = false;
      });
    }
    try {
      final repo = sl<IProcurementRepository>();
      final variantsDao = sl<ProductVariantsDao>();
      final productsDao = sl<ProductsDao>();
      final suppliers = await repo.getSuppliers(widget.businessId);
      final variants = await variantsDao.getByBusinessId(widget.businessId);
      final products = await productsDao.getByBusinessId(widget.businessId);
      final settings = await repo.getSettings(widget.businessId);
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _variants = variants;
          _productsById = {for (final p in products) p.id: p};
          _approvalThreshold = settings.approvalThreshold;
          _loadingData = false;
        });
      }
    } catch (e, st) {
      debugPrint('[PoFormPage] Error in _loadFormData: $e\n$st');
      if (mounted) {
        setState(() {
          _loadingData = false;
          _loadError = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFormData());
    // Discount/shipping change the live order total, same as line edits.
    _discountCtrl.addListener(_onLineChanged);
    _shippingCtrl.addListener(_onLineChanged);
    if (_isEdit) {
      final po = widget.po!;
      _supplierId = po.supplierId;
      _supplierName = po.supplierName;
      _notesCtrl.text = po.notes ?? '';
      if (po.discount > 0) _discountCtrl.text = po.discount.toStringAsFixed(2);
      if (po.shipping > 0) _shippingCtrl.text = po.shipping.toStringAsFixed(2);
      _expectedDelivery = po.expectedDelivery;
      for (final l in po.lines) {
        _addEntry(
          _LineEntry(
            productId: l.productId,
            variantId: l.variantId,
            productName: l.productName,
            variantName: l.variantName,
            sku: l.sku,
            qtyCtrl: TextEditingController(
              text: AppFormatters.quantity(l.quantityOrdered),
            ),
            costCtrl: TextEditingController(
              text: l.unitCost.toStringAsFixed(2),
            ),
          ),
        );
      }
    } else if (widget.initialSupplier != null) {
      _supplierId = widget.initialSupplier!.id;
      _supplierName = widget.initialSupplier!.name;
    }
  }

  // Registers a line and wires its qty/cost fields to the live summary bar.
  void _addEntry(_LineEntry e) {
    e.qtyCtrl.addListener(_onLineChanged);
    e.costCtrl.addListener(_onLineChanged);
    _lines.add(e);
  }

  void _onLineChanged() {
    if (mounted) setState(() {});
  }

  ({int count, double total}) get _summary {
    var total = 0.0;
    var count = 0;
    for (final l in _lines) {
      final qty = double.tryParse(l.qtyCtrl.text) ?? 0;
      final cost = double.tryParse(l.costCtrl.text) ?? 0;
      // Reject non-finite input (e.g. a literal "Infinity"/"NaN" typed into
      // the field) so it can't show a garbage preview total.
      if (qty <= 0 || !qty.isFinite || !cost.isFinite) continue;
      count++;
      total += qty * cost;
    }
    return (count: count, total: total);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _shippingCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _discountValue {
    final v = double.tryParse(_discountCtrl.text) ?? 0;
    return v.isFinite && v > 0 ? v : 0;
  }

  double get _shippingValue {
    final v = double.tryParse(_shippingCtrl.text) ?? 0;
    return v.isFinite && v > 0 ? v : 0;
  }

  // Order total shown on the action bar: subtotal − discount + shipping.
  double get _orderTotal {
    final t = _summary.total - _discountValue + _shippingValue;
    return t < 0 ? 0 : t;
  }

  List<PoLineInput> _buildLineInputs() {
    final result = <PoLineInput>[];
    for (final l in _lines) {
      final qty = double.tryParse(l.qtyCtrl.text) ?? 0;
      final cost = double.tryParse(l.costCtrl.text) ?? 0;
      if (qty <= 0) continue;
      result.add(
        PoLineInput(
          productId: l.productId,
          variantId: l.variantId,
          productName: l.productName,
          variantName: l.variantName,
          sku: l.sku,
          quantityOrdered: qty,
          unitCost: cost,
        ),
      );
    }
    return result;
  }

  Future<void> _save(_SaveMode mode) async {
    if (!_formKey.currentState!.validate()) return;
    final lines = _buildLineInputs();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product line.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final cubit = context.read<PoCubit>();
      if (_isEdit) {
        await cubit.updatePurchaseOrder(
          id: widget.po!.id,
          supplierId: _supplierId,
          supplierName: _supplierName,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          expectedDelivery: _expectedDelivery,
          discount: _discountValue,
          shipping: _shippingValue,
          lines: lines,
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      final id = await cubit.createPurchaseOrder(
        supplierId: _supplierId,
        supplierName: _supplierName,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        expectedDelivery: _expectedDelivery,
        discount: _discountValue,
        shipping: _shippingValue,
        lines: lines,
      );
      // Null id = the cubit blocked or failed it and already surfaced the error.
      if (id == null) return;
      // Chain the lifecycle move so the user lands on the right state in one go.
      // A PO is created as draft, so the approve path must submit first
      // (approvePurchaseOrder only accepts a submitted PO).
      if (mode == _SaveMode.submit) {
        await cubit.submitPurchaseOrder(id);
      } else if (mode == _SaveMode.approve) {
        await cubit.submitPurchaseOrder(id);
        await cubit.approvePurchaseOrder(id);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoCubit, PoState>(
      listenWhen: (_, s) => s is PoError,
      listener: (_, s) {
        if (s is PoError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: Breakpoints.isTablet(context)
            ? null
            : AppSubPageBar(
                title: _isEdit ? 'Edit Purchase Order' : 'New Purchase Order',
              ),
        body: _loadingData
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              )
            : _loadError
            ? AppEmptyState(
                icon: IconlyLight.danger,
                title: "Couldn't load the form",
                message:
                    'Something went wrong loading suppliers and products. '
                    'Please try again.',
                actionLabel: 'Retry',
                onAction: _loadFormData,
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    AppSectionCard(
                      title: 'Supplier',
                      icon: Icons.storefront_outlined,
                      children: [
                        _SupplierPicker(
                          suppliers: _suppliers,
                          selectedId: _supplierId,
                          selectedName: _supplierName,
                          onChanged: (id, name) => setState(() {
                            _supplierId = id;
                            _supplierName = name;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'Details',
                      icon: IconlyLight.document,
                      children: [
                        _inputField(
                          controller: _notesCtrl,
                          label: 'Notes (optional)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _DateField(
                          label: 'Expected Delivery',
                          value: _expectedDelivery,
                          onChanged: (d) =>
                              setState(() => _expectedDelivery = d),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _amountField(
                                controller: _discountCtrl,
                                label: 'Discount',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _amountField(
                                controller: _shippingCtrl,
                                label: 'Shipping',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'Products',
                      icon: IconlyLight.bag,
                      trailing: _lines.isEmpty
                          ? null
                          : _AddProductsChip(
                              onTap: () => _showProductPicker(context),
                            ),
                      children: [
                        if (_lines.isEmpty)
                          _ProductsEmptyState(
                            onAdd: () => _showProductPicker(context),
                          )
                        else
                          ..._lines.asMap().entries.map(
                            (e) => _LineRow(
                              entry: e.value,
                              index: e.key,
                              onRemove: () =>
                                  setState(() => _lines.removeAt(e.key)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: (_loadingData || _loadError)
            ? null
            : _buildActionBar(),
      ),
    );
  }

  Widget _buildActionBar() {
    final s = _summary;
    final summary = Row(
      children: [
        Text(
          s.count == 1 ? '1 item' : '${s.count} items',
          style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          AppFormatters.currency(_orderTotal),
          style: getOutfitStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );

    // Editing a draft just saves; the lifecycle actions live on the detail page.
    if (_isEdit) {
      return AppStickyActionBar(
        summary: summary,
        primary: AppFilledButton(
          label: 'Save Changes',
          loading: _saving,
          onPressed: _saving ? null : () => _save(_SaveMode.draft),
        ),
      );
    }

    // Creating: the creator finishes in one tap (Create & Approve) only when
    // they're authorized to instant-approve this order — owners always, and
    // approvers for amounts at/under the business threshold (or when unset).
    // Above the threshold a non-owner routes it to a different approver.
    final perms = sl<PermissionService>();
    final instant = ApprovalPolicy.canInstantApprove(
      canApprove: perms.can(PermissionKeys.procurementApprovePo),
      total: _orderTotal,
      threshold: _approvalThreshold,
      actorIsOwner: perms.isOwnerRole,
    );
    return AppStickyActionBar(
      summary: summary,
      secondary: _draftButton(),
      primary: AppFilledButton(
        label: instant ? 'Create & Approve' : 'Submit for Approval',
        loading: _saving,
        onPressed: _saving
            ? null
            : () => _save(instant ? _SaveMode.approve : _SaveMode.submit),
      ),
    );
  }

  Widget _draftButton() => OutlinedButton(
    onPressed: _saving ? null : () => _save(_SaveMode.draft),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.brand),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      'Save as Draft',
      style: getOutfitStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.brand,
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
    decoration: _inputDeco(label),
    validator: validator,
  );

  // Optional order-level amount (discount / shipping). Decimal, ₱-prefixed.
  Widget _amountField({
    required TextEditingController controller,
    required String label,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ],
    style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
    decoration: _inputDeco(label).copyWith(prefixText: '₱ '),
  );

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderSoft),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderSoft),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
    ),
  );

  // Simple products carry a hidden variant named "Default"; surface the real
  // product name in that case, and only append the variant when it's a named
  // option (mirrors the catalog label convention used across the app).
  String _variantLabel(ProductVariantsTableData v) {
    final productName = _productsById[v.productId]?.name ?? v.name;
    if (v.name == 'Default') return productName;
    return '$productName · ${v.name}';
  }

  // Only stock-holding items can be purchased: ingredients (ordered directly)
  // and products that track their own stock. Recipe products are made from
  // ingredients and service products hold no inventory, so neither is orderable.
  bool _isPurchasable(ProductVariantsTableData v) {
    final p = _productsById[v.productId];
    if (p == null || !p.isActive) return false;
    return p.type == 'ingredient' || p.trackingMethod == 'product_stock';
  }

  // A non-variant product should contribute exactly one purchasable row. Stale
  // duplicate variant rows (e.g. an old variant resurrected by a sync after an
  // edit) otherwise show up as phantom lines, so collapse each simple product to
  // its most recently updated variant. Products with real variants are untouched.
  List<ProductVariantsTableData> _collapseSimpleDuplicates(
    List<ProductVariantsTableData> variants,
  ) {
    final keptBySimpleProduct = <String, ProductVariantsTableData>{};
    final result = <ProductVariantsTableData>[];
    for (final v in variants) {
      final hasVariants = _productsById[v.productId]?.hasVariants ?? false;
      if (hasVariants) {
        result.add(v);
        continue;
      }
      final kept = keptBySimpleProduct[v.productId];
      if (kept == null || v.localUpdatedAt.isAfter(kept.localUpdatedAt)) {
        keptBySimpleProduct[v.productId] = v;
      }
    }
    return result..addAll(keptBySimpleProduct.values);
  }

  void _showProductPicker(BuildContext context) {
    // Variants already on the PO are excluded so the picker only adds new ones.
    final existing = _lines.map((l) => l.variantId).toSet();
    final purchasable = _variants
        .where((v) => !existing.contains(v.id) && _isPurchasable(v))
        .toList();
    final available = _collapseSimpleDuplicates(purchasable);
    final items =
        available
            .map(
              (v) => _PickerItem(
                variant: v,
                label: _variantLabel(v),
                isIngredient: _productsById[v.productId]?.type == 'ingredient',
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );
    showModalBottomSheet<List<ProductVariantsTableData>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(items: items),
    ).then((picked) {
      if (picked == null || picked.isEmpty) return;
      setState(() {
        for (final variant in picked) {
          _addEntry(
            _LineEntry(
              productId: variant.productId,
              variantId: variant.id,
              productName: _variantLabel(variant),
              variantName: variant.name,
              sku: variant.sku,
              qtyCtrl: TextEditingController(text: '1'),
              costCtrl: TextEditingController(
                text: (variant.costPrice ?? 0.0).toStringAsFixed(2),
              ),
            ),
          );
        }
      });
    });
  }
}

class _SupplierPicker extends StatelessWidget {
  final List<Supplier> suppliers;
  final String? selectedId;
  final String? selectedName;
  final void Function(String? id, String? name) onChanged;

  const _SupplierPicker({
    required this.suppliers,
    required this.selectedId,
    required this.selectedName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedName ?? 'Select supplier (optional)',
                style: getOutfitStyle(
                  fontSize: 14,
                  color: selectedName != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    showDialog<_SupplierChoice>(
      context: context,
      builder: (_) =>
          _SupplierPickerDialog(suppliers: suppliers, selectedId: selectedId),
    ).then((choice) {
      // Null = dismissed (barrier/back) — keep the current selection untouched.
      // A returned choice carries either a supplier or an explicit "no supplier".
      if (choice == null) return;
      onChanged(choice.supplier?.id, choice.supplier?.name);
    });
  }
}

/// Result of the supplier dialog. A null [supplier] means the user explicitly
/// chose "No supplier"; a null result from the dialog means it was dismissed.
class _SupplierChoice {
  final Supplier? supplier;

  const _SupplierChoice(this.supplier);
}

/// Premium supplier selection dialog. Tapping a row selects and closes; the
/// "No supplier" row clears. A search field appears once the list is long.
class _SupplierPickerDialog extends StatefulWidget {
  final List<Supplier> suppliers;
  final String? selectedId;

  const _SupplierPickerDialog({
    required this.suppliers,
    required this.selectedId,
  });

  @override
  State<_SupplierPickerDialog> createState() => _SupplierPickerDialogState();
}

class _SupplierPickerDialogState extends State<_SupplierPickerDialog> {
  String _query = '';

  bool get _showSearch => widget.suppliers.length > 6;

  List<Supplier> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return widget.suppliers;
    return widget.suppliers
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.phone?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(20),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 19,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Supplier',
                          style: getOutfitStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Who you are ordering from',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: AppSearchBar(
                  hint: 'Search suppliers...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                shrinkWrap: true,
                children: [
                  _SupplierTile(
                    title: 'No supplier',
                    subtitle: 'Leave this order without a supplier',
                    isSelected: widget.selectedId == null,
                    isNone: true,
                    onTap: () =>
                        Navigator.pop(context, const _SupplierChoice(null)),
                  ),
                  for (final s in filtered)
                    _SupplierTile(
                      title: s.name,
                      subtitle: s.phone,
                      isSelected: s.id == widget.selectedId,
                      onTap: () => Navigator.pop(context, _SupplierChoice(s)),
                    ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No suppliers match your search',
                          style: getOutfitStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isNone;
  final VoidCallback onTap;

  const _SupplierTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isNone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brand.withAlpha(12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.brand : AppColors.borderSoft,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isNone && !isSelected
                              ? AppColors.textMuted
                              : isSelected
                              ? AppColors.brand
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SelectDot(selected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Icon(IconlyLight.calendar, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null
                    ? AppFormatters.shortDate(value!)
                    : '$label (optional)',
                style: getOutfitStyle(
                  fontSize: 14,
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineEntry {
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String? sku;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;

  _LineEntry({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.sku,
    required this.qtyCtrl,
    required this.costCtrl,
  });

  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class _LineRow extends StatelessWidget {
  final _LineEntry entry;
  final int index;
  final VoidCallback onRemove;

  const _LineRow({
    required this.entry,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // The form rebuilds on every qty/cost keystroke (controller listeners), so
    // this subtotal stays live without local state.
    final qty = double.tryParse(entry.qtyCtrl.text) ?? 0;
    final cost = double.tryParse(entry.costCtrl.text) ?? 0;
    final subtotal = qty * cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withAlpha(20),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    IconlyLight.bag,
                    size: 16,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (entry.sku != null)
                        Text(
                          'SKU: ${entry.sku}',
                          style: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 15,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numField(entry.qtyCtrl, 'Qty')),
                const SizedBox(width: 10),
                Expanded(child: _numField(entry.costCtrl, 'Unit Cost')),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Text(
                    'Subtotal',
                    style: getOutfitStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.currency(subtotal),
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) => TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: hint,
      labelStyle: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Required';
      if ((double.tryParse(v) ?? 0) <= 0) return '>0';
      return null;
    },
  );
}

/// Compact brand "Add" pill shown in the Products section header once at least
/// one line exists, so more items can be added without scrolling.
class _AddProductsChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductsChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.plus, size: 16, color: AppColors.brand),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly first-run state for the Products card — a tappable zone that invites
/// the user to add their first line instead of dead-ending on plain text.
class _ProductsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _ProductsEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.brand.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                IconlyLight.bag,
                size: 24,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No items yet',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add products or ingredients to purchase on this order',
              textAlign: TextAlign.center,
              style: getOutfitStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppColors.textInverse),
                  const SizedBox(width: 6),
                  Text(
                    'Add products',
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textInverse,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A purchasable line in the picker — a variant paired with its resolved
/// catalog label and whether it's an ingredient, so the sheet can group and
/// badge the two kinds without re-querying products.
class _PickerItem {
  final ProductVariantsTableData variant;
  final String label;
  final bool isIngredient;

  const _PickerItem({
    required this.variant,
    required this.label,
    required this.isIngredient,
  });
}

enum _ItemFilter { all, products, ingredients }

/// Multi-select picker for products and ingredients to purchase. Returns the
/// chosen variants so several lines can be added in a single pass.
class _ProductPickerSheet extends StatefulWidget {
  final List<_PickerItem> items;

  const _ProductPickerSheet({required this.items});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';
  _ItemFilter _filter = _ItemFilter.all;
  final Set<String> _selected = {};

  late final int _productCount = widget.items
      .where((i) => !i.isIngredient)
      .length;
  late final int _ingredientCount = widget.items
      .where((i) => i.isIngredient)
      .length;

  // The type filter only earns its place when both kinds are present.
  bool get _showFilter => _productCount > 0 && _ingredientCount > 0;

  List<_PickerItem> get _filtered {
    final q = _query.toLowerCase().trim();
    return widget.items.where((i) {
      switch (_filter) {
        case _ItemFilter.products:
          if (i.isIngredient) return false;
        case _ItemFilter.ingredients:
          if (!i.isIngredient) return false;
        case _ItemFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      return i.label.toLowerCase().contains(q) ||
          (i.variant.sku?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  void _confirm() {
    final picked = widget.items
        .where((i) => _selected.contains(i.variant.id))
        .map((i) => i.variant)
        .toList();
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final count = _selected.length;

    return AppBottomSheetScaffold(
      title: 'Add to Order',
      titleTrailing: count == 0 ? null : _CountPill(count: count),
      action: AppFilledButton(
        label: count == 0
            ? 'Select items'
            : 'Add $count ${count == 1 ? 'item' : 'items'}',
        onPressed: count == 0 ? null : _confirm,
      ),
      maxHeightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose products and ingredients to purchase',
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchBar(
              hint: 'Search by name or SKU...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_showFilter) ...[
            const SizedBox(height: 12),
            _FilterRow(
              filter: _filter,
              total: widget.items.length,
              productCount: _productCount,
              ingredientCount: _ingredientCount,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyResults(searching: _query.trim().isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return _ItemRow(
                        item: item,
                        selected: _selected.contains(item.variant.id),
                        onTap: () => _toggle(item.variant.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Brand pill showing how many items are selected, pinned in the sheet header.
class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count selected',
        style: getOutfitStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _ItemFilter filter;
  final int total;
  final int productCount;
  final int ingredientCount;
  final ValueChanged<_ItemFilter> onChanged;

  const _FilterRow({
    required this.filter,
    required this.total,
    required this.productCount,
    required this.ingredientCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          AppFilterChip(
            label: 'All',
            isSelected: filter == _ItemFilter.all,
            badgeCount: total,
            onTap: () => onChanged(_ItemFilter.all),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Items',
            isSelected: filter == _ItemFilter.products,
            badgeCount: productCount,
            onTap: () => onChanged(_ItemFilter.products),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Ingredients',
            isSelected: filter == _ItemFilter.ingredients,
            badgeCount: ingredientCount,
            selectedColor: AppColors.success,
            onTap: () => onChanged(_ItemFilter.ingredients),
          ),
        ],
      ),
    );
  }
}

/// A selectable catalog row: type-coloured icon badge, name + meta, cost and a
/// selection check. Products use the brand accent, ingredients use success.
class _ItemRow extends StatelessWidget {
  final _PickerItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ItemRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.isIngredient ? AppColors.success : AppColors.brand;
    final icon = item.isIngredient ? Icons.eco_outlined : IconlyLight.bag;
    final sku = item.variant.sku;
    final meta = item.isIngredient
        ? 'Ingredient${sku != null ? ' · $sku' : ''}'
        : sku;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand.withAlpha(12) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.borderSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          fontSize: 11,
                          fontWeight: item.isIngredient
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: item.isIngredient
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.currency(item.variant.costPrice ?? 0),
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              _SelectDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round selection indicator — filled brand check when chosen, hollow outline
/// otherwise. Cleaner and more on-brand than a default checkbox.
class _SelectDot extends StatelessWidget {
  final bool selected;

  const _SelectDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.borderSoft,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: AppColors.textInverse)
          : null,
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool searching;

  const _EmptyResults({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          searching ? 'No items match your search' : 'Nothing here to purchase',
          style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
