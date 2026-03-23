import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/products/widgets/more_option_card.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';



enum _FormMode { simple, advanced }

// page
class AddProductsPage extends StatefulWidget {
  final String? initialBarcode;
  const AddProductsPage({super.key, this.initialBarcode});

  @override
  State<AddProductsPage> createState() => _AddProductsPageState();
}

class _AddProductsPageState extends State<AddProductsPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();

  //shared controller available sa both modes simple and advance
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  final _priceController = TextEditingController();
  final _costController = TextEditingController();

  // sa more optiosn controller 
  final _skuController = TextEditingController();
  final _taxController = TextEditingController();
  final _expiryController = TextEditingController();

  final _stockAlertController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final List<TextEditingController> _barcodeControllers = [
    TextEditingController(),
  ];

  // ── UI state ─────────────────────────────────────────────────────────────
  _FormMode _mode = _FormMode.simple;
  bool _moreOptionsExpanded = false;
  bool _trackExpiry = false;
  DateTime? _expiryDate;
  bool _stockAlertEnabled = false;
  String _sellBy = 'unit'; 

  List<CategoriesTableData> _categories = [];
  String? _selectedCategoryId;
  bool _saving = false;

  // varaints sa advance mode lang
  final List<_VariantForm> _variants = [_VariantForm()];


  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _mode = _FormMode.advanced;
      _moreOptionsExpanded = true;
      _barcodeControllers[0].text = widget.initialBarcode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _priceController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _taxController.dispose();
    _expiryController.dispose();
    _stockAlertController.dispose();
    _newCategoryController.dispose();
    for (final c in _barcodeControllers) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  // helpers

  String? get _businessId {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.businessId : null;
  }

  Future<void> _loadCategories() async {
    final id = _businessId;
    if (id == null) return;
    final list = await _categoriesDao.getByBusinessId(id);
    if (mounted) setState(() => _categories = list);
  }

  void _autoGenerateSku() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final prefix = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join('');
    final suffix =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    _skuController.text = '$prefix-$suffix';
  }

  void _switchMode(_FormMode mode) {
    if (_mode == mode) return;
    final hasMoreOptionsData =
        _barcodeControllers.any((c) => c.text.trim().isNotEmpty) ||
        _skuController.text.trim().isNotEmpty ||
        _taxController.text.trim().isNotEmpty ||
        _trackExpiry ||
        _stockAlertEnabled;
    setState(() {
      _mode = mode;
      if (mode == _FormMode.advanced && hasMoreOptionsData) {
        _moreOptionsExpanded = true;
      }
    });
  }

  void _addBarcode() =>
      setState(() => _barcodeControllers.add(TextEditingController()));

  void _removeBarcode(int index) {
    if (_barcodeControllers.length <= 1) return;
    _barcodeControllers.removeAt(index).dispose();
    setState(() {});
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
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
      setState(() {
        _expiryDate = picked;
        _expiryController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _showAddCategorySheet() async {
    final id = _businessId;
    if (id == null) return;
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
                          // Phase 1: insert while sheet is open
                          String? newId;
                          try {
                            newId = await _categoriesDao.insertSingle(
                              businessId: id,
                              name: name,
                            );
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
                          // Phase 2: close + update page state
                          if (!sheetCtx.mounted) return;
                          Navigator.of(sheetCtx).pop();
                          await _loadCategories();
                          if (mounted) {
                            setState(() => _selectedCategoryId = newId!);
                            StatusSnack.show(context, type: StatusType.success, message: 'Category saved successfully');
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
    // _newCategoryController is a page field — disposed in dispose()
    // saving has no listeners — GC handles it
  }

  // saving na 

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!mounted) return;

    final id = _businessId;
    if (id == null) return;

    setState(() => _saving = true);

    try {
      final productId = const Uuid().v4();
      final isAdvanced = _mode == _FormMode.advanced;
      final isFraction = _sellBy == 'fraction';

      final sku = _skuController.text.trim();
      final barcode = _barcodeControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .join(',');
      final tax = _taxController.text.trim().isEmpty
          ? null
          : double.tryParse(_taxController.text);

      await _productsDao.insertProduct(
        ProductsTableCompanion.insert(
          id: productId,
          businessId: id,
          name: _nameController.text.trim(),
          categoryId: Value(_selectedCategoryId),
          sku: Value(isAdvanced && sku.isNotEmpty ? sku : null),
          barcode: Value(isAdvanced && barcode.isNotEmpty ? barcode : null),
          hasVariants: Value(isAdvanced),
          tax: Value(isAdvanced ? tax : null),
          sellBy: Value(_sellBy),
          isActive: const Value(true),
        ),
      );

      if (isAdvanced) {
        // Save all variants
        final companions = _variants.map((v) {
          final vPrice = double.tryParse(v.price.text) ?? 0.0;
          final vCost = v.cost.text.trim().isEmpty
              ? null
              : double.tryParse(v.cost.text);
          final vRetailPrice = v.retailPrice.text.trim().isEmpty
              ? null
              : double.tryParse(v.retailPrice.text);
          final vStockInt = (v.trackInventory && !isFraction)
              ? (int.tryParse(v.stock.text) ?? 0)
              : 0;
          final vStockReal = (v.trackInventory && isFraction)
              ? double.tryParse(v.stock.text)
              : null;
          return ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: id,
            name: v.name.text.trim().isEmpty ? 'Default' : v.name.text.trim(),
            price: Value(vPrice),
            costPrice: Value(vCost),
            retailPrice: Value(vRetailPrice),
            stock: Value(vStockInt),
            stockDecimal: Value(vStockReal),
            trackExpiry: Value(_trackExpiry),
            expiryDate: Value(
              _trackExpiry ? _expiryDate?.toIso8601String() : null,
            ),
          );
        }).toList();
        await _productVariantsDao.insertVariants(companions);
      } else {
        final price = double.tryParse(_priceController.text) ?? 0.0;
        final cost = _costController.text.trim().isEmpty
            ? null
            : double.tryParse(_costController.text);

        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: id,
            name: 'Default',
            price: Value(price),
            costPrice: Value(cost),
            stock: const Value(0),
            stockDecimal: const Value(null),
            retailPrice: const Value(null),
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
          ),
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // eto na yung build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Add Product', style: AppTextStyles.title(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _saveProduct,
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
          _ModeToggle(mode: _mode, onChanged: _switchMode),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  if (_mode == _FormMode.simple) ...[
                    _buildSimpleSection(),
                  ] else ...[
                    _buildBasicInfoSection(),
                    const SizedBox(height: 12),
                    _buildVariantsSection(),
                    const SizedBox(height: 12),
                    MoreOptionsCard(
                      expanded: _moreOptionsExpanded,
                      onToggle: () => setState(
                        () => _moreOptionsExpanded = !_moreOptionsExpanded,
                      ),
                      barcodeControllers: _barcodeControllers,
                      onAddBarcode: _addBarcode,
                      onRemoveBarcode: _removeBarcode,
                      skuController: _skuController,
                      onAutoSku: _autoGenerateSku,
                      taxController: _taxController,
                      trackExpiry: _trackExpiry,
                      onTrackExpiryChanged: (v) {
                        setState(() {
                          _trackExpiry = v;
                          if (!v) {
                            _expiryDate = null;
                            _expiryController.clear();
                          }
                        });
                      },
                      expiryController: _expiryController,
                      onPickExpiryDate: _pickExpiryDate,
                      expiryRequired: _trackExpiry && _expiryDate == null,
                      stockAlertEnabled: _stockAlertEnabled,
                      onStockAlertChanged: (v) => setState(() {
                        _stockAlertEnabled = v;
                        if (!v) _stockAlertController.clear();
                      }),
                      stockAlertController: _stockAlertController,
                    ),
                    const SizedBox(height: 12),
                  ],

                  AppFilledButton(
                    label: 'Save Product',
                    loading: _saving,
                    onPressed: _saveProduct,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// simple build
  Widget _buildSimpleSection() {
    return AppSectionCard(
      title: 'Basic Info',
      icon: Icons.info_outline_rounded,
      children: [
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
        const SizedBox(height: 16),

        const AppFieldLabel('Category *'),
        AppDropdown<String>(
          value: _selectedCategoryId,
          hint: 'Select category',
          addItemLabel: 'Add Category',
          onAddItem: _showAddCategorySheet,
          validator: (v) => v == null ? 'Category is required' : null,
          items: _categories
              .map((c) => AppDropdownItem(value: c.id, label: c.name))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
        const SizedBox(height: 16),

        const AppFieldLabel('Sell By'),
        AppDropdown<String>(
          value: _sellBy,
          items: const [
            AppDropdownItem(value: 'unit', label: 'Unit  (piece, box, bottle…)'),
            AppDropdownItem(
              value: 'fraction',
              label: 'Fraction  (per kg, litre…)',
            ),
          ],
          onChanged: (v) => setState(() => _sellBy = v ?? 'unit'),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppFieldLabel('Price *'),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: appInputDeco('0.00', prefixText: '₱ '),
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) => Validators.required(v, fieldName: "Price"),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppFieldLabel('Cost'),
                  TextFormField(
                    controller: _costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return AppSectionCard(
      title: 'Basic Info',
      icon: Icons.info_outline_rounded,
      children: [
        const AppFieldLabel('Product Name *'),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode, 
          textCapitalization: TextCapitalization.words,
          decoration: appInputDeco('e.g. Espresso, White Rice 5kg...'),
          style: getOutfitStyle(color: AppColors.textPrimary),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Category *'),
        AppDropdown<String>(
          value: _selectedCategoryId,
          hint: 'Select category',
          addItemLabel: 'Add Category',
          onAddItem: _showAddCategorySheet,
          validator: (v) => v == null ? 'Category is required' : null,
          items: _categories
              .map((c) => AppDropdownItem(value: c.id, label: c.name))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('Sell By'),
        AppDropdown<String>(
          value: _sellBy,
          items: const [
            AppDropdownItem(value: 'unit', label: 'Unit  (piece, box, bottle…)'),
            AppDropdownItem(
              value: 'fraction',
              label: 'Fraction  (per kg, litre…)',
            ),
          ],
          onChanged: (v) => setState(() => _sellBy = v ?? 'unit'),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    final isFraction = _sellBy == 'fraction';

    return AppSectionCard(
      title: 'Variants',
      icon: Icons.tune_rounded,
      children: [
        ..._variants.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VariantCard(
              index: i + 1,
              form: v,
              isFraction: isFraction,
              canDelete: _variants.length > 1,
              onDelete: () => setState(() {
                v.dispose();
                _variants.removeAt(i);
              }),
            ),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => setState(() => _variants.add(_VariantForm())),
          icon: const Icon(Icons.add_rounded, size: 18),
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
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mode Toggle
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  final _FormMode mode;
  final ValueChanged<_FormMode> onChanged;

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
              active: mode == _FormMode.simple,
              onTap: () => onChanged(_FormMode.simple),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeChip(
              label: 'Advanced',
              icon: Icons.tune_rounded,
              active: mode == _FormMode.advanced,
              onTap: () => onChanged(_FormMode.advanced),
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

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

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
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : AppColors.textMuted,
            ),
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

// ---------------------------------------------------------------------------
// _VariantForm
// ---------------------------------------------------------------------------

class _VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController retailPrice = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  bool trackInventory = false;

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    retailPrice.dispose();
    stock.dispose();
  }
}

// ---------------------------------------------------------------------------
// _VariantCard
// ---------------------------------------------------------------------------

class _VariantCard extends StatefulWidget {
  final int index;
  final _VariantForm form;
  final bool isFraction;
  final bool canDelete;
  final VoidCallback onDelete;

  const _VariantCard({
    required this.index,
    required this.form,
    required this.isFraction,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  late bool _trackInventory;
  final FocusNode _stockFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _trackInventory = widget.form.trackInventory;
  }

  @override
  void dispose() {
    _stockFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deco = appInputDeco('', fillColor: AppColors.background, radius: 8, isDense: true);
    final isFraction = widget.isFraction;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
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
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Variant Name ────────────────────────────────────────────────
          const AppFieldLabel('Variant Name *'),
          TextFormField(
            controller: widget.form.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: deco.copyWith(hintText: 'e.g. Small, Regular, Large'),
            style: getOutfitStyle(color: AppColors.textPrimary),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name required' : null,
          ),
          const SizedBox(height: 10),

          // ── Price · Cost · Retail Price — one compact row ───────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selling Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Price *'),
                    TextFormField(
                      controller: widget.form.price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textInputAction: TextInputAction.next,
                      decoration:
                          deco.copyWith(hintText: '0.00', prefixText: '₱ '),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cost Price (optional)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Cost'),
                    TextFormField(
                      controller: widget.form.cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textInputAction: TextInputAction.next,
                      decoration:
                          deco.copyWith(hintText: '0.00', prefixText: '₱ '),
                      style: getOutfitStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Retail Price (optional)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Retail'),
                    TextFormField(
                      controller: widget.form.retailPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textInputAction: TextInputAction.done,
                      decoration:
                          deco.copyWith(hintText: '0.00', prefixText: '₱ '),
                      style: getOutfitStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // track Inventory section 
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabeledSwitch(
                  label: 'Track Inventory',
                  subtitle: 'Manage and track stock levels',
                  value: _trackInventory,
                  onChanged: (v) {
                    setState(() {
                      _trackInventory = v;
                      widget.form.trackInventory = v;
                    });
                    if (v) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _stockFocusNode.requestFocus();
                      });
                    }
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _trackInventory
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                  isFraction ? 'Stock * (kg)' : 'Stock *'),
                              TextFormField(
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
                                textInputAction: TextInputAction.done,
                                decoration: deco.copyWith(
                                    hintText: isFraction ? '0.000' : '0'),
                                style:
                                    getOutfitStyle(color: AppColors.textPrimary),
                                validator: (v) {
                                  if (_trackInventory &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Stock is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
