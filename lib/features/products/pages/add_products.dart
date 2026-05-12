import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/data/holder/variant_form.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/presentation/cubit/product_form_cubit.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';
import 'package:pos/features/products/widgets/barcode_togggle_section.dart';
import 'package:pos/features/products/widgets/barcode_toggle_field.dart';
import 'package:pos/features/products/widgets/image_picker_field.dart';
import 'package:pos/features/products/widgets/sku_section_toggle.dart';
import 'package:pos/features/products/widgets/switch_row.dart';
import 'package:pos/features/products/widgets/toggle_row.dart';
import 'package:pos/features/products/widgets/variant_card_state.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

// ── Entry point ───────────────────────────────────────────────────────────────

class AddProductsPage extends StatelessWidget {
  final String? initialBarcode;
  final Product? productToEdit;

  const AddProductsPage({super.key, this.initialBarcode, this.productToEdit});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    return BlocProvider(
      create: (context) {
        final branchCubit = context.read<BranchCubit>();
        // Prefer the explicitly selected branch UUID from BranchCubit.
        // If BranchCubit state hasn't loaded its async prefs yet (selectedBranchId
        // is null but the user isn't on "All Branches"), fall back to the user's
        // own assigned branch from the synchronous auth context.
        final String? effectiveBranchId;
        if (branchCubit.state.selectedBranch == BranchCubit.allBranchesLabel) {
          effectiveBranchId =
              null; // Explicitly "All Branches" — seed all branches
        } else {
          effectiveBranchId =
              branchCubit.state.selectedBranchId ?? authState.user.branchId;
        }
        return ProductFormCubit(
          businessId: authState.user.businessId ?? '',
          selectedBranchId: effectiveBranchId,
        );
      },
      child: _AddProductsView(
        initialBarcode: initialBarcode,
        productToEdit: productToEdit,
      ),
    );
  }
}

// ── View — owns all TextEditingControllers ────────────────────────────────────

class _AddProductsView extends StatefulWidget {
  final String? initialBarcode;
  final Product? productToEdit;

  const _AddProductsView({this.initialBarcode, this.productToEdit});

  @override
  State<_AddProductsView> createState() => _AddProductsViewState();
}

class _AddProductsViewState extends State<_AddProductsView> {
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // Simple mode
  final _simplePriceController = TextEditingController();
  final _simpleBarcodeController = TextEditingController();

  // Advanced — no-variants pricing
  final _sellingPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _taxController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();

  // More Options local toggles (retail price + tax — UI-only, not in cubit)
  bool _showRetailPrice = false;
  bool _showTax = false;

  // More options
  final _skuController = TextEditingController();
  final _expiryController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final List<TextEditingController> _barcodeControllers = [
    TextEditingController(),
  ];

  // Shared UI state
  String _sellBy = 'unit';
  bool _showImagePicker = false;

  // Variants (advanced + hasVariants)
  final List<VariantForm> _variants = [VariantForm()];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initForEdit(widget.productToEdit!),
      );
    } else if (widget.initialBarcode?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cubit = context.read<ProductFormCubit>();
        cubit.switchMode(ProductFormMode.advanced);
        cubit.setHasVariants(true);
        _variants[0].barcode.text = widget.initialBarcode!;
      });
    }
  }

  Future<void> _initForEdit(Product product) async {
    if (!mounted) return;
    final cubit = context.read<ProductFormCubit>();

    // Set cubit-managed state
    cubit.initEditState(product);

    // Pre-fill shared fields
    _nameController.text = product.name;
    setState(() => _sellBy = product.sellBy);

    // Load existing variants + branch-specific stock
    final variants = await cubit.loadVariants(product.id);
    if (!mounted) return;
    final branchStock = await cubit.loadBranchStockMap(
      variants.map((v) => v.id).toList(),
    );
    if (!mounted) return;

    final hasStock = variants.any((v) => v.trackStock);
    if (hasStock) cubit.setTrackInventory(true);

    // branchStock now always contains real sums from inventory_levels
    // (per-branch for specific mode, summed across all branches for All Branches
    // mode). Fall back to the stale product_variants.stock only if this variant
    // has no inventory_levels rows yet (e.g. brand-new product, no stock seeded).
    int stockFor(ProductVariantsTableData v) => branchStock[v.id] ?? v.stock;

    if (product.hasVariants) {
      // Advanced + variants: populate variant forms
      _variants.clear();
      for (final v in variants.where((v) => v.isActive)) {
        final form = VariantForm();
        form.name.text = v.name == 'Default' ? '' : v.name;
        form.price.text = v.price.toStringAsFixed(2);
        if (v.costPrice != null) {
          form.cost.text = v.costPrice!.toStringAsFixed(2);
        }
        form.stock.text = stockFor(v).toString();
        if (v.lowStockAlert != null) {
          form.lowStock.text = v.lowStockAlert.toString();
        }
        if (v.barcode != null) form.barcode.text = v.barcode!;
        _variants.add(form);
      }
      if (_variants.isEmpty) _variants.add(VariantForm());
    } else {
      // Simple or advanced no-variants
      final v = variants.firstOrNull;
      if (v != null) {
        // Reverse out any stored tax so the form shows the pre-tax base price.
        // (On save we re-apply tax, so we must show base here to avoid double-taxing.)
        final taxRate = (product.tax ?? 0.0) / 100.0;
        final basePrice = taxRate > 0 ? v.price / (1 + taxRate) : v.price;
        _simplePriceController.text = basePrice.toStringAsFixed(2);
        _sellingPriceController.text = basePrice.toStringAsFixed(2);
        if (v.costPrice != null) {
          _costPriceController.text = v.costPrice!.toStringAsFixed(2);
        }
        if (v.barcode != null) {
          _simpleBarcodeController.text = v.barcode!;
          _barcodeControllers[0].text = v.barcode!;
        }
        final qty = stockFor(v);
        if (qty > 0) _stockController.text = qty.toString();
        if (v.lowStockAlert != null) {
          _lowStockController.text = v.lowStockAlert.toString();
        }
        // Retail price — must be loaded or it will be wiped on next save
        if (v.retailPrice != null) {
          _retailPriceController.text = v.retailPrice!.toStringAsFixed(2);
          _showRetailPrice = true;
        }
      }
    }

    if (product.tax != null) {
      _taxController.text = product.tax!.toString();
      _showTax = true;
    }
    if (product.sku != null) _skuController.text = product.sku!;

    // Auto-expand More Options when the product already has any advanced fields
    final hasMoreData =
        _showRetailPrice || _showTax || product.sku?.isNotEmpty == true;
    if (hasMoreData && !cubit.state.moreOptionsExpanded) {
      cubit.toggleMoreOptions();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _simplePriceController.dispose();
    _simpleBarcodeController.dispose();
    _sellingPriceController.dispose();
    _retailPriceController.dispose();
    _costPriceController.dispose();
    _taxController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _skuController.dispose();
    _expiryController.dispose();
    _newCategoryController.dispose();

    for (final c in _barcodeControllers) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addBarcode() =>
      setState(() => _barcodeControllers.add(TextEditingController()));

  void _removeBarcode(int index) {
    if (_barcodeControllers.length <= 1) return;
    _barcodeControllers.removeAt(index).dispose();
    setState(() {});
  }

  Future<void> _pickExpiryDate() async {
    final cubit = context.read<ProductFormCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          cubit.state.expiryDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      cubit.setExpiryDate(picked);
      _expiryController.text = _formatDate(picked);
    }
  }

  Future<void> _showAddCategorySheet() async {
    final cubit = context.read<ProductFormCubit>();
    _newCategoryController.clear();
    final saving = ValueNotifier<bool>(false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('New Category', style: AppTextStyles.title(sheetCtx)),
              const SizedBox(height: 4),
              Text(
                'Saved locally and synced when online.',
                style: AppTextStyles.caption(
                  sheetCtx,
                ).copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newCategoryController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: appInputDeco('e.g. Coffee & Tea, Clothing...'),
                style: getOutfitStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: saving,
                builder: (_, isSaving, _) => AppFilledButton(
                  label: 'Save Category',
                  loading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = _newCategoryController.text.trim();
                          if (name.isEmpty) return;
                          saving.value = true;
                          try {
                            await cubit.addCategory(name);
                          } catch (e) {
                            saving.value = false;
                            if (!sheetCtx.mounted) return;
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (!sheetCtx.mounted) return;
                          Navigator.of(sheetCtx).pop();
                          if (mounted) {
                            StatusSnack.show(
                              context,
                              type: StatusType.success,
                              message: 'Category saved',
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<ProductFormCubit>();
    final state = cubit.state;
    final isAdvanced = state.mode == ProductFormMode.advanced;

    final formData = ProductFormData(
      name: _nameController.text,
      sellBy: _sellBy,
      // Simple
      simplePrice: !isAdvanced ? _simplePriceController.text : null,
      simpleBarcode: !isAdvanced ? _simpleBarcodeController.text : null,
      // Advanced no-variants
      sellingPrice: (isAdvanced && !state.hasVariants)
          ? _sellingPriceController.text
          : null,
      retailPrice: (isAdvanced && !state.hasVariants)
          ? _retailPriceController.text
          : null,
      costPrice: (isAdvanced && !state.hasVariants)
          ? _costPriceController.text
          : null,
      taxPercent: (isAdvanced && !state.hasVariants)
          ? _taxController.text
          : null,
      stock: (isAdvanced && !state.hasVariants && state.trackInventory)
          ? _stockController.text
          : null,
      lowStockAlert: (isAdvanced && !state.hasVariants && state.trackInventory)
          ? _lowStockController.text
          : null,
      // Image
      imagePath: state.imagePath,
      // More options
      barcodes: isAdvanced
          ? _barcodeControllers.map((c) => c.text).toList()
          : [],
      sku: isAdvanced ? _skuController.text : null,
      // Variants
      variants: (isAdvanced && state.hasVariants)
          ? _variants
                .map(
                  (v) => VariantFormData(
                    name: v.name.text,
                    price: v.price.text,
                    costPrice: v.cost.text,
                    stock: v.stock.text,
                    lowStockAlert: v.lowStock.text,
                    barcode: v.barcode.text,
                  ),
                )
                .toList()
          : [],
    );

    if (widget.productToEdit != null) {
      cubit.update(widget.productToEdit!.id, formData);
    } else {
      cubit.save(formData);
    }
  }

  // ── Branch assignment dialog ──────────────────────────────────────────────

  /// Shown after a successful new-product save when "All Branches" was active
  /// and the user entered opening stock > 0. Lets the user nominate which
  /// branch receives the opening inventory, then pops the page.
  Future<void> _showBranchAssignmentDialog(
    BuildContext ctx,
    ProductFormCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BranchAssignmentSheet(
        businessId: cubit.businessId,
        onSkip: () {
          Navigator.of(sheetCtx).pop();
          ctx.pop();
        },
        onAssign: (branchId) async {
          Navigator.of(sheetCtx).pop();
          await cubit.assignInventoryToBranch(branchId);
          if (ctx.mounted) ctx.pop();
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormCubit, ProductFormState>(
      listener: (ctx, state) {
        if (state.isSuccess && state.pendingBranchAssignment != null) {
          _showBranchAssignmentDialog(ctx, ctx.read<ProductFormCubit>());
        } else if (state.isSuccess) {
          ctx.pop();
        } else if (state.error != null) {
          StatusSnack.show(
            context,
            type: StatusType.error,
            message: 'Failed to save: ${state.error}',
          );
        }
      },
      child: BlocBuilder<ProductFormCubit, ProductFormState>(
        builder: (ctx, state) {
          final cubit = ctx.read<ProductFormCubit>();
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: Text(
                widget.productToEdit != null ? 'Edit Product' : 'Add Product',
                style: AppTextStyles.title(context),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            // ── Sticky save bar with soft top shadow ────────────────────────
            bottomNavigationBar: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F101828),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: AppFilledButton(
                  label: widget.productToEdit != null
                      ? 'Update Product'
                      : 'Save Product',
                  loading: state.isSaving,
                  onPressed: state.isSaving ? null : _save,
                ),
              ),
            ),
            body: Column(
              children: [
                _ModeToggle(mode: state.mode, onChanged: cubit.switchMode),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      children: [
                        if (state.mode == ProductFormMode.simple) ...[
                          _buildSimpleSection(state, cubit),
                          const SizedBox(height: 16),
                          _buildMoreOptionsSection(state, cubit),
                          const SizedBox(height: 8),
                        ] else ...[
                          _buildBasicInfoSection(state, cubit),
                          const SizedBox(height: 16),
                          if (!state.hasVariants) ...[
                            _buildPricingSection(state, cubit),
                            const SizedBox(height: 16),
                          ] else ...[
                            _buildVariantsSection(state, cubit),
                            const SizedBox(height: 16),
                          ],
                          _buildMoreOptionsSection(state, cubit),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Simple section ─────────────────────────────────────────────────────────

  Widget _buildSimpleSection(ProductFormState state, ProductFormCubit cubit) {
    return AppSectionCard(
      title: 'Basic Info',
      icon: Icons.info_outline_rounded,
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: appInputDeco(
            'e.g. Espresso, White Rice 5kg…',
            label: 'Product name',
          ),
          style: getOutfitStyle(color: AppColors.textPrimary, fontSize: 16),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 12),

        // Category (optional)
        const AppFieldLabel('Category'),
        AppDropdown<String>(
          value: state.selectedCategoryId,
          hint: 'No category',
          addItemLabel: 'Add Category',
          onAddItem: _showAddCategorySheet,
          items: state.categories
              .map((c) => AppDropdownItem(value: c.id, label: c.name))
              .toList(),
          onChanged: cubit.selectCategory,
        ),
        const SizedBox(height: 12),

        // Price
        TextFormField(
          controller: _simplePriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('0.00', label: 'Price', prefixText: '₱ '),
          style: getOutfitStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Price is required' : null,
        ),
      ],
    );
  }

  // ── Advanced — Basic Info ─────────────────────────────────────────────────

  Widget _buildBasicInfoSection(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return AppSectionCard(
      title: 'Basic Info',
      icon: Icons.info_outline_rounded,
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: appInputDeco(
            'e.g. Espresso, White Rice 5kg…',
            label: 'Product name',
          ),
          style: getOutfitStyle(color: AppColors.textPrimary, fontSize: 16),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 12),

        // Category (optional)
        const AppFieldLabel('Category'),
        AppDropdown<String>(
          value: state.selectedCategoryId,
          hint: 'No category',
          addItemLabel: 'Add Category',
          onAddItem: _showAddCategorySheet,
          items: state.categories
              .map((c) => AppDropdownItem(value: c.id, label: c.name))
              .toList(),
          onChanged: cubit.selectCategory,
        ),
        const SizedBox(height: 8),

        // Multiple sizes / options
        SwitchRow(
          icon: Icons.tune_rounded,
          label: 'Multiple sizes or options',
          subtitle: 'e.g. Small / Medium / Large — each with its own price',
          value: state.hasVariants,
          onChanged: cubit.setHasVariants,
        ),
      ],
    );
  }

  // ── Advanced — Pricing (no-variants) ─────────────────────────────────────

  Widget _buildPricingSection(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';
    final isAllBranchesEdit =
        widget.productToEdit != null && cubit.selectedBranchId == null;

    return AppSectionCard(
      title: 'Pricing & Inventory',
      icon: Icons.attach_money_rounded,
      children: [
        // Selling Price *
        TextFormField(
          controller: _sellingPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco(
            '0.00',
            label: 'Selling price',
            prefixText: '₱ ',
          ),
          style: getOutfitStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Selling price is required'
              : null,
        ),
        // Live tax-inclusive final price preview
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _sellingPriceController,
          builder: (context, sellVal, child) =>
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _taxController,
                builder: (context, taxVal, child) {
                  final base = double.tryParse(sellVal.text.trim());
                  final taxPct = double.tryParse(taxVal.text.trim());
                  if (base == null ||
                      base <= 0 ||
                      taxPct == null ||
                      taxPct <= 0) {
                    return const SizedBox.shrink();
                  }
                  final taxAmt = base * taxPct / 100;
                  final finalPrice = base + taxAmt;
                  final taxStr = taxPct % 1 == 0
                      ? taxPct.toInt().toString()
                      : taxPct.toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.brand.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_outlined,
                            size: 14,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Customer sees  ',
                                    style: getOutfitStyle(
                                      color: AppColors.brand,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '₱${finalPrice.toStringAsFixed(2)}',
                                    style: getOutfitStyle(
                                      color: AppColors.brand,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '   ₱${base.toStringAsFixed(2)} + ₱${taxAmt.toStringAsFixed(2)} ($taxStr% tax)',
                                    style: getOutfitStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
        const SizedBox(height: 12),

        // Cost Price (full-width; Retail Price moved to More Options)
        TextFormField(
          controller: _costPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco(
            '0.00',
            label: 'Cost price',
            prefixText: '₱ ',
          ),
          style: getOutfitStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Track stock
        SwitchRow(
          icon: Icons.inventory_2_outlined,
          label: 'Track stock',
          subtitle: 'Show stock counts and low-stock alerts',
          value: state.trackInventory,
          onChanged: cubit.setTrackInventory,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: state.trackInventory
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stock *
                          Expanded(
                            child: Opacity(
                              opacity: isAllBranchesEdit ? 0.6 : 1.0,
                              child: TextFormField(
                                controller: _stockController,
                                readOnly: isAllBranchesEdit,
                                keyboardType: isFraction
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                      )
                                    : TextInputType.number,
                                inputFormatters: isFraction
                                    ? [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,3}'),
                                        ),
                                      ]
                                    : [FilteringTextInputFormatter.digitsOnly],
                                textInputAction: TextInputAction.next,
                                decoration: appInputDeco(
                                  isFraction ? '0.000' : '0',
                                  label: isFraction ? 'Stock (kg)' : 'Stock',
                                  fillColor: isAllBranchesEdit
                                      ? AppColors.surfaceAlt
                                      : AppColors.surface,
                                ),
                                style: getOutfitStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                                validator: (v) {
                                  if (!isAllBranchesEdit &&
                                      state.trackInventory &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Stock is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Low Stock Alert (optional)
                          Expanded(
                            child: TextFormField(
                              controller: _lowStockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.done,
                              decoration: appInputDeco(
                                'e.g. 5',
                                label: 'Low stock alert',
                              ),
                              style: getOutfitStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isAllBranchesEdit) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.info.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 15,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing total stock across all branches. '
                                  'To adjust stock for a specific branch, use the Inventory page.',
                                  style: getOutfitStyle(
                                    color: AppColors.info,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  // ── Advanced — Variants ───────────────────────────────────────────────────

  Widget _buildVariantsSection(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';
    final isAllBranchesEdit =
        widget.productToEdit != null && cubit.selectedBranchId == null;

    return AppSectionCard(
      title: 'Variants',
      icon: Icons.tune_rounded,
      children: [
        // Barcode assignment banner — shown when opened from a POS scan
        if (widget.initialBarcode?.isNotEmpty == true) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brand.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode pre-assigned to Variant 1',
                        style: getOutfitStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.initialBarcode!,
                        style: getOutfitStyle(
                          color: AppColors.brand,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Move it to the correct variant using the barcode field below.',
                        style: getOutfitStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Variants intro hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Give each option a name and price. Optionally add a barcode.',
                  style: getOutfitStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Global Track Inventory
        SwitchRow(
          icon: Icons.inventory_2_outlined,
          label: 'Track stock',
          subtitle: 'Adds a stock field to every option below',
          value: state.trackInventory,
          onChanged: cubit.setTrackInventory,
        ),
        const SizedBox(height: 10),

        // Variant cards
        ..._variants.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VariantCard(
              index: i + 1,
              form: v,
              isFraction: isFraction,
              trackInventory: state.trackInventory,
              canDelete: _variants.length > 1,
              onDelete: () => setState(() {
                v.dispose();
                _variants.removeAt(i);
              }),
              stockReadOnly: isAllBranchesEdit,
            ),
          );
        }),

        if (isAllBranchesEdit && state.trackInventory) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing total stock across all branches. '
                    'To adjust stock for a specific branch, use the Inventory page.',
                    style: getOutfitStyle(color: AppColors.info, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Add Variant button
        OutlinedButton.icon(
          onPressed: () => setState(() => _variants.add(VariantForm())),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(
            'Add Variant',
            style: getOutfitStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brand,
            side: const BorderSide(color: AppColors.brand),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  // ── Advanced — More Options (collapsible) ─────────────────────────────────

  Widget _buildMoreOptionsSection(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header toggle
          InkWell(
            onTap: cubit.toggleMoreOptions,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More options',
                          style: getOutfitStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (!state.moreOptionsExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            state.mode == ProductFormMode.simple
                                ? 'Photo · Barcode · Sold by weight'
                                : 'Photo · Barcode · SKU · Tax · Expiry',
                            style: getOutfitStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: state.moreOptionsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            child: state.moreOptionsExpanded
                ? (state.mode == ProductFormMode.simple
                      ? _buildSimpleMoreOptionsBody(state, cubit)
                      : _buildMoreOptionsBody(state, cubit))
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  // ── Simple — More Options body (Sell By · Image · Barcode only) ─────────────

  Widget _buildSimpleMoreOptionsBody(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sold by weight
        ToggleRow(
          icon: Icons.straighten_rounded,
          label: 'Sold by weight',
          subtitle: 'Price per kg, litre, or other unit',
          enabled: _sellBy == 'fraction',
          onChanged: (v) => setState(() => _sellBy = v ? 'fraction' : 'unit'),
        ),

        // Product Image
        ToggleRow(
          icon: Icons.image_outlined,
          label: 'Product photo',
          subtitle: 'Add a photo for faster recognition',
          enabled: _showImagePicker || state.imagePath != null,
          onChanged: (v) {
            setState(() => _showImagePicker = v);
            if (!v) cubit.clearImage();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: (_showImagePicker || state.imagePath != null)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ImagePickerField(
                    imagePath: state.imagePath,
                    onPick: (source) => cubit.pickImage(source),
                    onClear: cubit.clearImage,
                    isLoading: state.isUploadingImage,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // Barcode
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: BarcodeToggleField(controller: _simpleBarcodeController),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Advanced — More Options body ──────────────────────────────────────────

  Widget _buildMoreOptionsBody(ProductFormState state, ProductFormCubit cubit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sold by weight
        ToggleRow(
          icon: Icons.straighten_rounded,
          label: 'Sold by weight',
          subtitle: 'Price per kg, litre, or other unit',
          enabled: _sellBy == 'fraction',
          onChanged: (v) => setState(() => _sellBy = v ? 'fraction' : 'unit'),
        ),

        // Product Image (optional)
        ToggleRow(
          icon: Icons.image_outlined,
          label: 'Product photo',
          subtitle: 'Add a photo for faster recognition',
          enabled: _showImagePicker || state.imagePath != null,
          onChanged: (v) {
            setState(() => _showImagePicker = v);
            if (!v) cubit.clearImage();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: (_showImagePicker || state.imagePath != null)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ImagePickerField(
                    imagePath: state.imagePath,
                    onPick: (source) => cubit.pickImage(source),
                    onClear: cubit.clearImage,
                    isLoading: state.isUploadingImage,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // Barcodes
        BarcodesSectionToggle(
          controllers: _barcodeControllers,
          onAdd: _addBarcode,
          onRemove: _removeBarcode,
        ),

        // SKU
        SkuSectionToggle(
          controller: _skuController,
          onAutoSku: () {
            final sku = cubit.generateSku(_nameController.text);
            if (sku.isNotEmpty) setState(() => _skuController.text = sku);
          },
        ),

        // Retail Price (optional, toggleable)
        ToggleRow(
          icon: Icons.price_change_outlined,
          label: 'Suggested retail price',
          subtitle: 'The recommended selling price (SRP)',
          enabled: _showRetailPrice,
          onChanged: (v) => setState(() {
            _showRetailPrice = v;
            if (!v) _retailPriceController.clear();
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showRetailPrice
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _retailPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: appInputDeco(
                          '0.00',
                          label: 'Suggested retail price',
                          prefixText: '₱ ',
                        ),
                        style: getOutfitStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      // Live SRP comparison indicator
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _retailPriceController,
                        builder: (context, retailVal, child) =>
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _sellingPriceController,
                              builder: (context, sellVal, child) {
                                final srp = double.tryParse(
                                  retailVal.text.trim(),
                                );
                                final sell = double.tryParse(
                                  sellVal.text.trim(),
                                );
                                if (srp == null || sell == null || srp <= 0) {
                                  return const SizedBox.shrink();
                                }
                                final diff = sell - srp;
                                final pct = (diff / srp * 100).abs();
                                final isAbove = diff > 0.005;
                                final isBelow = diff < -0.005;
                                final Color bg = isAbove
                                    ? AppColors.warningSoft
                                    : isBelow
                                    ? AppColors.successSoft
                                    : AppColors.surfaceAlt;
                                final Color fg = isAbove
                                    ? AppColors.warning
                                    : isBelow
                                    ? AppColors.success
                                    : AppColors.textMuted;
                                final String label = isAbove
                                    ? '${pct.toStringAsFixed(1)}% above SRP — selling above suggested price'
                                    : isBelow
                                    ? '${pct.toStringAsFixed(1)}% below SRP'
                                    : 'Selling at SRP';
                                final IconData icon = isAbove
                                    ? Icons.arrow_upward_rounded
                                    : isBelow
                                    ? Icons.arrow_downward_rounded
                                    : Icons.horizontal_rule_rounded;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 12, color: fg),
                                        const SizedBox(width: 4),
                                        Text(
                                          label,
                                          style: getOutfitStyle(
                                            color: fg,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // Tax % (optional, toggleable)
        ToggleRow(
          icon: Icons.receipt_long_outlined,
          label: 'VAT or sales tax',
          subtitle: 'Added at checkout',
          enabled: _showTax,
          onChanged: (v) => setState(() {
            _showTax = v;
            if (!v) _taxController.clear();
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showTax
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextFormField(
                    controller: _taxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: appInputDeco(
                      'e.g. 12',
                      label: 'Tax rate (%)',
                      prefixText: '% ',
                    ),
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final p = double.tryParse(v);
                        if (p == null) return 'Enter a valid percentage';
                        if (p < 0 || p > 100) return 'Must be 0–100';
                      }
                      return null;
                    },
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // Track Expiry
        ToggleRow(
          icon: Icons.event_rounded,
          label: 'Track expiry',
          subtitle: 'Enable for perishable or dated items',
          enabled: state.trackExpiry,
          onChanged: cubit.setTrackExpiry,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: state.trackExpiry
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextFormField(
                    controller: _expiryController,
                    readOnly: true,
                    onTap: _pickExpiryDate,
                    decoration: appInputDeco('dd/mm/yyyy', label: 'Expiry date')
                        .copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                        ),
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    validator: (_) =>
                        (state.trackExpiry && state.expiryDate == null)
                        ? 'Please select an expiry date'
                        : null,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── Mode Toggle ───────────────────────────────────────────────────────────────
// Slim 36px iOS-style segmented control with a sliding white pill.

class _ModeToggle extends StatelessWidget {
  final ProductFormMode mode;
  final ValueChanged<ProductFormMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSimple = mode == ProductFormMode.simple;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final pillWidth = (c.maxWidth - 8) / 2; // 4px padding each side
          return Container(
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Sliding white pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: isSimple
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: pillWidth,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14101828),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Color(0x0F101828),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Labels
                Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        label: 'Simple',
                        active: isSimple,
                        onTap: () => onChanged(ProductFormMode.simple),
                      ),
                    ),
                    Expanded(
                      child: _ModeChip(
                        label: 'Advanced',
                        active: !isSimple,
                        onTap: () => onChanged(ProductFormMode.advanced),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: getOutfitStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ── Branch assignment bottom sheet ───────────────────────────────────────────

class _BranchAssignmentSheet extends StatefulWidget {
  final String businessId;
  final VoidCallback onSkip;
  final Future<void> Function(String branchId) onAssign;

  const _BranchAssignmentSheet({
    required this.businessId,
    required this.onSkip,
    required this.onAssign,
  });

  @override
  State<_BranchAssignmentSheet> createState() => _BranchAssignmentSheetState();
}

class _BranchAssignmentSheetState extends State<_BranchAssignmentSheet> {
  List<BranchesTableData>? _branches;
  String? _selectedBranchId;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches = await sl<BranchesDao>().getByBusinessId(widget.businessId);
    final active = branches.where((b) => b.isActive).toList();
    if (!mounted) return;
    setState(() {
      _branches = active;
      _selectedBranchId = active.isNotEmpty ? active.first.id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Assign Opening Inventory', style: AppTextStyles.title(context)),
          const SizedBox(height: 6),
          Text(
            'You\'re viewing All Branches. Choose which branch should receive the initial inventory you entered.',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_branches == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_branches!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No active branches found.',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            RadioGroup<String>(
              groupValue: _selectedBranchId,
              onChanged: (v) => setState(() => _selectedBranchId = v),
              child: Column(
                children: _branches!
                    .map(
                      (branch) => RadioListTile<String>(
                        value: branch.id,
                        title: Text(
                          branch.name,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        activeColor: AppColors.brand,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _assigning ? null : widget.onSkip,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedBranchId == null || _assigning)
                      ? null
                      : () async {
                          setState(() => _assigning = true);
                          await widget.onAssign(_selectedBranchId!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.brand.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _assigning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Assign',
                          style: getOutfitStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable switch row (compact, no border container) ───────────────────────
