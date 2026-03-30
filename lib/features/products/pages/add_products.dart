import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/presentation/cubit/product_form_cubit.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

// ── Entry point ───────────────────────────────────────────────────────────────

class AddProductsPage extends StatelessWidget {
  final String? initialBarcode;
  final ProductsTableData? productToEdit;

  const AddProductsPage({super.key, this.initialBarcode, this.productToEdit});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) =>
          ProductFormCubit(businessId: authState.user.businessId ?? ''),
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
  final ProductsTableData? productToEdit;

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
  final List<_VariantForm> _variants = [_VariantForm()];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initForEdit(widget.productToEdit!));
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

  Future<void> _initForEdit(ProductsTableData product) async {
    if (!mounted) return;
    final cubit = context.read<ProductFormCubit>();

    // Set cubit-managed state
    cubit.initEditState(product);

    // Pre-fill shared fields
    _nameController.text = product.name;
    setState(() => _sellBy = product.sellBy);

    // Load existing variants
    final variants = await cubit.loadVariants(product.id);
    if (!mounted) return;

    final hasStock = variants.any((v) => v.stock > 0 || (v.stockDecimal ?? 0) > 0);
    if (hasStock) cubit.setTrackInventory(true);

    if (product.hasVariants) {
      // Advanced + variants: populate variant forms
      _variants.clear();
      for (final v in variants.where((v) => v.isActive)) {
        final form = _VariantForm();
        form.name.text = v.name == 'Default' ? '' : v.name;
        form.price.text = v.price.toStringAsFixed(2);
        if (v.costPrice != null) form.cost.text = v.costPrice!.toStringAsFixed(2);
        form.stock.text = v.stock.toString();
        if (v.lowStockAlert != null) form.lowStock.text = v.lowStockAlert.toString();
        if (v.barcode != null) form.barcode.text = v.barcode!;
        _variants.add(form);
      }
      if (_variants.isEmpty) _variants.add(_VariantForm());
    } else {
      // Simple or advanced no-variants
      final v = variants.firstOrNull;
      if (v != null) {
        _simplePriceController.text = v.price.toStringAsFixed(2);
        _sellingPriceController.text = v.price.toStringAsFixed(2);
        if (v.costPrice != null) _costPriceController.text = v.costPrice!.toStringAsFixed(2);
        if (v.barcode != null) {
          _simpleBarcodeController.text = v.barcode!;
          _barcodeControllers[0].text = v.barcode!;
        }
        if (v.stock > 0) _stockController.text = v.stock.toString();
        if (v.lowStockAlert != null) _lowStockController.text = v.lowStockAlert.toString();
      }
    }

    if (product.tax != null) _taxController.text = product.tax!.toString();
    if (product.sku != null) _skuController.text = product.sku!;

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
      initialDate: cubit.state.expiryDate ??
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
            20, 16, 20,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
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
                style: AppTextStyles.caption(sheetCtx)
                    .copyWith(color: AppColors.textMuted),
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
                            StatusSnack.show(context,
                                type: StatusType.success,
                                message: 'Category saved');
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
      sellingPrice:
          (isAdvanced && !state.hasVariants) ? _sellingPriceController.text : null,
      retailPrice:
          (isAdvanced && !state.hasVariants) ? _retailPriceController.text : null,
      costPrice:
          (isAdvanced && !state.hasVariants) ? _costPriceController.text : null,
      taxPercent:
          (isAdvanced && !state.hasVariants) ? _taxController.text : null,
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
              .map((v) => VariantFormData(
                    name: v.name.text,
                    price: v.price.text,
                    costPrice: v.cost.text,
                    stock: v.stock.text,
                    lowStockAlert: v.lowStock.text,
                    barcode: v.barcode.text,
                  ))
              .toList()
          : [],
    );

    if (widget.productToEdit != null) {
      cubit.update(widget.productToEdit!.id, formData);
    } else {
      cubit.save(formData);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormCubit, ProductFormState>(
      listener: (ctx, state) {
        if (state.isSuccess) {
          ctx.pop();
        } else if (state.error != null) {
          StatusSnack.show(context,
              type: StatusType.error,
              message: 'Failed to save: ${state.error}');
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: state.isSaving
                      ? const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brand,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _save,
                          child: Text(
                            'Save',
                            style: getOutfitStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            body: Column(
              children: [
                _ModeToggle(mode: state.mode, onChanged: cubit.switchMode),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      children: [
                        if (state.mode == ProductFormMode.simple) ...[
                          _buildSimpleSection(state, cubit),
                        ] else ...[
                          _buildBasicInfoSection(state, cubit),
                          const SizedBox(height: 12),
                          if (!state.hasVariants) ...[
                            _buildPricingSection(state, cubit),
                            const SizedBox(height: 12),
                          ] else ...[
                            _buildVariantsSection(state, cubit),
                            const SizedBox(height: 12),
                          ],
                          _buildMoreOptionsSection(state, cubit),
                          const SizedBox(height: 12),
                        ],
                        AppFilledButton(
                          label: 'Save Product',
                          loading: state.isSaving,
                          onPressed: state.isSaving ? null : _save,
                        ),
                        const SizedBox(height: 24),
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
        const AppFieldLabel('Product Name *'),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('e.g. Espresso, White Rice 5kg...'),
          style: getOutfitStyle(color: AppColors.textPrimary),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 14),

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
        const SizedBox(height: 14),

        // Sell By
        const AppFieldLabel('Sell By'),
        AppDropdown<String>(
          value: _sellBy,
          items: const [
            AppDropdownItem(value: 'unit', label: 'Unit  (piece, box, bottle…)'),
            AppDropdownItem(value: 'fraction', label: 'Fraction  (per kg, litre…)'),
          ],
          onChanged: (v) => setState(() => _sellBy = v ?? 'unit'),
        ),
        const SizedBox(height: 14),

        // Price
        const AppFieldLabel('Price *'),
        TextFormField(
          controller: _simplePriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('0.00', prefixText: '₱ '),
          style: getOutfitStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Price is required' : null,
        ),
        const SizedBox(height: 10),

        // Barcode (optional toggle)
        _BarcodeToggleField(controller: _simpleBarcodeController),
        const SizedBox(height: 10),

        // Product Image (optional, toggleable) — bottom of card
        _SwitchRow(
          icon: Icons.image_outlined,
          label: 'Product Image',
          subtitle: 'Optional photo for this product',
          value: _showImagePicker || state.imagePath != null,
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
                  padding: const EdgeInsets.only(top: 8),
                  child: _ImagePickerField(
                    imagePath: state.imagePath,
                    onPick: (source) => cubit.pickImage(source),
                    onClear: cubit.clearImage,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  // ── Advanced — Basic Info ─────────────────────────────────────────────────

  Widget _buildBasicInfoSection(
      ProductFormState state, ProductFormCubit cubit) {
    return AppSectionCard(
      title: 'Basic Info',
      icon: Icons.info_outline_rounded,
      children: [
        // Name
        const AppFieldLabel('Product Name *'),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('e.g. Espresso, White Rice 5kg...'),
          style: getOutfitStyle(color: AppColors.textPrimary),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 14),

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
        const SizedBox(height: 14),

        // Sell By
        const AppFieldLabel('Sell By'),
        AppDropdown<String>(
          value: _sellBy,
          items: const [
            AppDropdownItem(value: 'unit', label: 'Unit  (piece, box, bottle…)'),
            AppDropdownItem(value: 'fraction', label: 'Fraction  (per kg, litre…)'),
          ],
          onChanged: (v) => setState(() => _sellBy = v ?? 'unit'),
        ),
        const SizedBox(height: 14),

        // Has Variants toggle
        _SwitchRow(
          icon: Icons.tune_rounded,
          label: 'Has Variants',
          subtitle: 'Each variant has its own price  (e.g. Small / Medium / Large)',
          value: state.hasVariants,
          onChanged: cubit.setHasVariants,
        ),
      ],
    );
  }

  // ── Advanced — Pricing (no-variants) ─────────────────────────────────────

  Widget _buildPricingSection(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';

    return AppSectionCard(
      title: 'Pricing & Inventory',
      icon: Icons.attach_money_rounded,
      children: [
        // Selling Price *
        const AppFieldLabel('Selling Price *'),
        TextFormField(
          controller: _sellingPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('0.00', prefixText: '₱ '),
          style: getOutfitStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Selling price is required' : null,
        ),
        const SizedBox(height: 12),

        // Cost Price (full-width; Retail Price moved to More Options)
        const AppFieldLabel('Cost Price'),
        TextFormField(
          controller: _costPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          decoration: appInputDeco('0.00', prefixText: '₱ '),
          style: getOutfitStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 14),

        // Track Inventory
        _SwitchRow(
          icon: Icons.inventory_2_outlined,
          label: 'Track Inventory',
          subtitle: 'Manage stock levels',
          value: state.trackInventory,
          onChanged: cubit.setTrackInventory,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: state.trackInventory
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock *
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppFieldLabel(
                                isFraction ? 'Stock * (kg)' : 'Stock *'),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: isFraction
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true)
                                  : TextInputType.number,
                              inputFormatters: isFraction
                                  ? [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,3}'))
                                    ]
                                  : [FilteringTextInputFormatter.digitsOnly],
                              textInputAction: TextInputAction.next,
                              decoration:
                                  appInputDeco(isFraction ? '0.000' : '0'),
                              style:
                                  getOutfitStyle(color: AppColors.textPrimary),
                              validator: (v) {
                                if (state.trackInventory &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Stock is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Low Stock Alert (optional)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppFieldLabel('Low Stock Alert'),
                            TextFormField(
                              controller: _lowStockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.done,
                              decoration: appInputDeco('e.g. 5'),
                              style:
                                  getOutfitStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  // ── Advanced — Variants ───────────────────────────────────────────────────

  Widget _buildVariantsSection(
      ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';

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
                const Icon(Icons.qr_code_rounded,
                    size: 16, color: AppColors.brand),
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
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Give each option a name, price, and optionally a barcode. '
                  'Customers never see these — they\'re for your records.',
                  style: getOutfitStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Global Track Inventory
        _SwitchRow(
          icon: Icons.inventory_2_outlined,
          label: 'Track Inventory',
          subtitle: 'Adds a stock field to every variant below',
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
            child: _VariantCard(
              index: i + 1,
              form: v,
              isFraction: isFraction,
              trackInventory: state.trackInventory,
              canDelete: _variants.length > 1,
              onDelete: () => setState(() {
                v.dispose();
                _variants.removeAt(i);
              }),
            ),
          );
        }),

        // Add Variant button
        OutlinedButton.icon(
          onPressed: () => setState(() => _variants.add(_VariantForm())),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(
            'Add Variant',
            style:
                getOutfitStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brand,
            side: const BorderSide(color: AppColors.brand),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  // ── Advanced — More Options (collapsible) ─────────────────────────────────

  Widget _buildMoreOptionsSection(
      ProductFormState state, ProductFormCubit cubit) {
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
          GestureDetector(
            onTap: cubit.toggleMoreOptions,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined,
                      size: 17, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    'More Options',
                    style: getOutfitStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: state.moreOptionsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            child: state.moreOptionsExpanded
                ? _buildMoreOptionsBody(state, cubit)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsBody(
      ProductFormState state, ProductFormCubit cubit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: AppColors.borderSoft),

        // Product Image (optional)
        _ToggleRow(
          icon: Icons.image_outlined,
          label: 'Product Image',
          subtitle: 'Add a photo for this product',
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
                  child: _ImagePickerField(
                    imagePath: state.imagePath,
                    onPick: (source) => cubit.pickImage(source),
                    onClear: cubit.clearImage,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const Divider(height: 1, color: AppColors.borderSoft),

        // Barcodes
        _BarcodesSectionToggle(
          controllers: _barcodeControllers,
          onAdd: _addBarcode,
          onRemove: _removeBarcode,
        ),
        const Divider(height: 1, color: AppColors.borderSoft),

        // SKU
        _SkuSectionToggle(
          controller: _skuController,
          onAutoSku: () {
            final sku = cubit.generateSku(_nameController.text);
            if (sku.isNotEmpty) setState(() => _skuController.text = sku);
          },
        ),
        const Divider(height: 1, color: AppColors.borderSoft),

        // Retail Price (optional, toggleable)
        _ToggleRow(
          icon: Icons.price_change_outlined,
          label: 'Retail Price',
          subtitle: 'Suggested customer / SRP price',
          enabled: _showRetailPrice,
          onChanged: (v) => setState(() => _showRetailPrice = v),
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
                      const AppFieldLabel('Retail Price'),
                      TextFormField(
                        controller: _retailPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: appInputDeco('0.00', prefixText: '₱ '),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const Divider(height: 1, color: AppColors.borderSoft),

        // Tax % (optional, toggleable)
        _ToggleRow(
          icon: Icons.receipt_long_outlined,
          label: 'Tax (%)',
          subtitle: 'Already included in the selling price',
          enabled: _showTax,
          onChanged: (v) => setState(() => _showTax = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showTax
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFieldLabel('Tax (%)'),
                      TextFormField(
                        controller: _taxController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: appInputDeco('e.g. 12', prefixText: '% '),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final p = double.tryParse(v);
                            if (p == null) return 'Enter a valid percentage';
                            if (p < 0 || p > 100) return 'Must be 0–100';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const Divider(height: 1, color: AppColors.borderSoft),

        // Track Expiry
        _ToggleRow(
          icon: Icons.event_rounded,
          label: 'Track Expiry',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFieldLabel('Expiry Date'),
                      TextFormField(
                        controller: _expiryController,
                        readOnly: true,
                        onTap: _pickExpiryDate,
                        decoration: appInputDeco('dd/mm/yyyy').copyWith(
                          suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 17,
                              color: AppColors.textMuted),
                        ),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                        validator: (_) =>
                            (state.trackExpiry && state.expiryDate == null)
                                ? 'Please select an expiry date'
                                : null,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── Mode Toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final ProductFormMode mode;
  final ValueChanged<ProductFormMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'Simple',
              icon: Icons.flash_on_rounded,
              active: mode == ProductFormMode.simple,
              onTap: () => onChanged(ProductFormMode.simple),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeChip(
              label: 'Advanced',
              icon: Icons.tune_rounded,
              active: mode == ProductFormMode.advanced,
              onTap: () => onChanged(ProductFormMode.advanced),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: getOutfitStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable switch row (compact, no border container) ───────────────────────

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: value ? AppColors.brand : AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: getOutfitStyle(
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!,
                    style: getOutfitStyle(
                        color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.brand,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

// ── Toggle row (for More Options sections) ───────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: enabled ? AppColors.brand : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getOutfitStyle(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      style: getOutfitStyle(
                          color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

// ── Barcode toggle field (simple mode inline) ─────────────────────────────────

class _BarcodeToggleField extends StatefulWidget {
  final TextEditingController controller;
  const _BarcodeToggleField({required this.controller});

  @override
  State<_BarcodeToggleField> createState() => _BarcodeToggleFieldState();
}

class _BarcodeToggleFieldState extends State<_BarcodeToggleField> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code_rounded,
                size: 16,
                color: _enabled ? AppColors.brand : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              'Barcode',
              style: getOutfitStyle(
                color: _enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Text('(optional)',
                style: getOutfitStyle(
                    color: AppColors.textMuted, fontSize: 11)),
            const Spacer(),
            Switch.adaptive(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              activeThumbColor: AppColors.brand,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: appInputDeco('Scan or type barcode').copyWith(
                      prefixIcon: const Icon(Icons.qr_code_rounded,
                          size: 17, color: AppColors.textMuted),
                    ),
                    style: getOutfitStyle(color: AppColors.textPrimary),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── Barcodes section (More Options) ──────────────────────────────────────────

class _BarcodesSectionToggle extends StatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _BarcodesSectionToggle(
      {required this.controllers,
      required this.onAdd,
      required this.onRemove});

  @override
  State<_BarcodesSectionToggle> createState() =>
      _BarcodesSectionToggleState();
}

class _BarcodesSectionToggleState extends State<_BarcodesSectionToggle> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controllers.any((c) => c.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleRow(
          icon: Icons.qr_code_rounded,
          label: 'Barcode(s)',
          enabled: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.controllers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final ctrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  decoration: appInputDeco(
                                    i == 0
                                        ? 'Scan or type barcode'
                                        : 'Additional barcode',
                                  ).copyWith(
                                    prefixIcon: const Icon(
                                        Icons.qr_code_rounded,
                                        size: 17,
                                        color: AppColors.textMuted),
                                  ),
                                  style: getOutfitStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              if (widget.controllers.length > 1) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => widget.onRemove(i),
                                  child: const Icon(Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: widget.onAdd,
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: Text(
                          'Add Barcode',
                          style: getOutfitStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── SKU section (More Options) ────────────────────────────────────────────────

class _SkuSectionToggle extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAutoSku;
  const _SkuSectionToggle(
      {required this.controller, required this.onAutoSku});

  @override
  State<_SkuSectionToggle> createState() => _SkuSectionToggleState();
}

class _SkuSectionToggleState extends State<_SkuSectionToggle> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleRow(
          icon: Icons.tag_rounded,
          label: 'SKU',
          enabled: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
                          textCapitalization: TextCapitalization.characters,
                          decoration: appInputDeco('e.g. CAFE-001'),
                          style:
                              getOutfitStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onAutoSku,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.brand),
                        child: Text(
                          'Auto',
                          style: getOutfitStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── Variant data holder ───────────────────────────────────────────────────────

class _VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController lowStock = TextEditingController();
  final TextEditingController barcode = TextEditingController();

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    lowStock.dispose();
    barcode.dispose();
  }
}

// ── Variant Card (compact) ────────────────────────────────────────────────────

class _VariantCard extends StatefulWidget {
  final int index;
  final _VariantForm form;
  final bool isFraction;
  final bool trackInventory;
  final bool canDelete;
  final VoidCallback onDelete;

  const _VariantCard({
    required this.index,
    required this.form,
    required this.isFraction,
    required this.trackInventory,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  final FocusNode _stockFocusNode = FocusNode();

  @override
  void dispose() {
    _stockFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deco = appInputDeco('',
        fillColor: AppColors.background, radius: 8, isDense: true);
    final isFraction = widget.isFraction;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Variant ${widget.index}',
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Name
          TextFormField(
            controller: widget.form.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: deco.copyWith(
              hintText: 'Variant name  (e.g. Small, Regular)',
              labelText: 'Name *',
            ),
            style: getOutfitStyle(color: AppColors.textPrimary),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name required' : null,
          ),
          const SizedBox(height: 8),

          // Price + Cost (2-column, NO retail)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.form.price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: deco.copyWith(
                      hintText: '0.00',
                      prefixText: '₱ ',
                      labelText: 'Price *'),
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: widget.form.cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.done,
                  decoration: deco.copyWith(
                      hintText: '0.00',
                      prefixText: '₱ ',
                      labelText: 'Cost'),
                  style: getOutfitStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),

          // Stock — compact inline row, only when trackInventory ON
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: widget.trackInventory
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          isFraction ? 'Stock (kg) *' : 'Stock *',
                          style: getOutfitStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            controller: widget.form.stock,
                            focusNode: _stockFocusNode,
                            keyboardType: isFraction
                                ? const TextInputType.numberWithOptions(
                                    decimal: true)
                                : TextInputType.number,
                            inputFormatters: isFraction
                                ? [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,3}'))
                                  ]
                                : [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.next,
                            decoration: deco.copyWith(
                                hintText: isFraction ? '0.000' : '0'),
                            style: getOutfitStyle(
                                color: AppColors.textPrimary),
                            validator: (v) {
                              if (widget.trackInventory &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: widget.form.lowStock,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.done,
                            decoration: deco.copyWith(
                              hintText: 'Alert',
                              labelText: 'Low',
                            ),
                            style: getOutfitStyle(
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: 8),

          // Barcode (per-variant, toggleable)
          _BarcodeToggleField(controller: widget.form.barcode),
        ],
      ),
    );
  }
}

// ── Product Image Picker ──────────────────────────────────────────────────────

class _ImagePickerField extends StatelessWidget {
  final String? imagePath;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback onClear;

  const _ImagePickerField({
    required this.imagePath,
    required this.onPick,
    required this.onClear,
  });

  Future<void> _showSourcePicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.brand),
              title: Text('Take Photo',
                  style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.brand),
              title: Text('Choose from Gallery',
                  style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath!),
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => _emptyPicker(ctx),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _showSourcePicker(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: getOutfitStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _emptyPicker(context);
  }

  Widget _emptyPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSourcePicker(context),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              'Tap to add image',
              style: getOutfitStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
