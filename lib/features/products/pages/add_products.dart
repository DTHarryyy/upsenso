import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class AddProductsPage extends StatefulWidget {
  const AddProductsPage({super.key});

  @override
  State<AddProductsPage> createState() => _AddProductsPageState();
}

class _AddProductsPageState extends State<AddProductsPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();

  // Controllers — basic info
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();

  // Simple product pricing (used when !_hasVariants)
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  // State
  List<CategoriesTableData> _categories = [];
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _hasVariants = false;
  bool _saving = false;

  // Variant rows (used when _hasVariants)
  final List<_VariantForm> _variants = [_VariantForm()];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

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

  Future<void> _showAddCategorySheet() async {
    final id = _businessId;
    if (id == null) return;
    final controller = TextEditingController();

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
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: appInputDeco('e.g. Coffee & Tea, Clothing...'),
                style: getOutfitStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              AppFilledButton(
                label: 'Save Category',
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  final newId = await _categoriesDao.insertSingle(
                    businessId: id,
                    name: name,
                  );
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  await _loadCategories();
                  if (mounted) setState(() => _selectedCategoryId = newId);
                },
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _businessId;
    if (id == null) return;

    setState(() => _saving = true);

    try {
      final productId = const Uuid().v4();
      final sku = _skuController.text.trim();
      final barcode = _barcodeController.text.trim();

      await _productsDao.insertProduct(
        ProductsTableCompanion.insert(
          id: productId,
          businessId: id,
          name: _nameController.text.trim(),
          categoryId: Value(_selectedCategoryId),
          sku: Value(sku.isEmpty ? null : sku),
          barcode: Value(barcode.isEmpty ? null : barcode),
          hasVariants: Value(_hasVariants),
          isActive: Value(_isActive),
        ),
      );

      if (_hasVariants) {
        final companions = _variants.map((v) {
          final vSku = v.sku.text.trim();
          final vBarcode = v.barcode.text.trim();
          return ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: id,
            name: v.name.text.trim(),
            price: Value(double.tryParse(v.price.text) ?? 0.0),
            costPrice: Value(
              v.cost.text.trim().isEmpty
                  ? null
                  : double.tryParse(v.cost.text),
            ),
            stock: Value(int.tryParse(v.stock.text) ?? 0),
            sku: Value(vSku.isEmpty ? null : vSku),
            barcode: Value(vBarcode.isEmpty ? null : vBarcode),
          );
        }).toList();
        await _productVariantsDao.insertVariants(companions);
      } else {
        final price = double.tryParse(_priceController.text) ?? 0.0;
        final cost = _costController.text.trim().isEmpty
            ? null
            : double.tryParse(_costController.text);
        final stock = int.tryParse(_stockController.text) ?? 0;

        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: id,
            name: 'Default',
            price: Value(price),
            costPrice: Value(cost),
            stock: Value(stock),
          ),
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Basic Info ────────────────────────────────────────────
            AppSectionCard(
              title: 'Basic Info',
              icon: Icons.info_outline_rounded,
              children: [
                const AppFieldLabel('Product Name *'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: appInputDeco('e.g. Espresso, Blue T-Shirt...'),
                  style: getOutfitStyle(color: AppColors.textPrimary),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Product name is required'
                          : null,
                ),
                const SizedBox(height: 16),
                const AppFieldLabel('Category'),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        value: _selectedCategoryId,
                        hint: 'Select category',
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: getOutfitStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _showAddCategorySheet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppLabeledSwitch(
                  label: 'Active',
                  subtitle: 'Product is available for sale',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Identifiers ───────────────────────────────────────────
            AppSectionCard(
              title: 'Identifiers',
              icon: Icons.qr_code_rounded,
              children: [
                const AppFieldLabel('SKU'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: appInputDeco('e.g. CAFE-001'),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _autoGenerateSku,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brand,
                      ),
                      child: Text(
                        'Auto',
                        style: getOutfitStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const AppFieldLabel('Barcode (optional)'),
                TextFormField(
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  decoration: appInputDeco('Scan or enter barcode'),
                  style: getOutfitStyle(color: AppColors.textPrimary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Variants toggle ───────────────────────────────────────
            AppSectionCard(
              title: 'Variants',
              icon: Icons.tune_rounded,
              children: [
                AppLabeledSwitch(
                  label: 'Has variants',
                  subtitle: 'Different sizes, colors, flavors, etc.',
                  value: _hasVariants,
                  onChanged: (v) => setState(() => _hasVariants = v),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Pricing / Variants ────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _hasVariants
                  ? _buildVariantsSection()
                  : _buildSimplePricingSection(),
            ),

            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────
            AppFilledButton(
              label: 'Save Product',
              loading: _saving,
              onPressed: _saveProduct,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePricingSection() {
    return AppSectionCard(
      key: const ValueKey('simple'),
      title: 'Pricing & Stock',
      icon: Icons.attach_money_rounded,
      children: [
        const AppFieldLabel('Price *'),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: appInputDeco('0.00', prefixText: '₱ '),
          style: getOutfitStyle(color: AppColors.textPrimary),
          validator: (v) {
            if (!_hasVariants) {
              if (v == null || v.trim().isEmpty) return 'Price is required';
              if (double.tryParse(v) == null) return 'Enter a valid price';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        const AppFieldLabel('Cost Price (optional)'),
        TextFormField(
          controller: _costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: appInputDeco('0.00', prefixText: '₱ '),
          style: getOutfitStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        const AppFieldLabel('Stock Quantity'),
        TextFormField(
          controller: _stockController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: appInputDeco('0'),
          style: getOutfitStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      key: const ValueKey('variants'),
      children: [
        ..._variants.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VariantCard(
              index: i + 1,
              form: v,
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
// _VariantForm
// ---------------------------------------------------------------------------

class _VariantForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController sku = TextEditingController();
  final TextEditingController barcode = TextEditingController();

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    sku.dispose();
    barcode.dispose();
  }
}

// ---------------------------------------------------------------------------
// _VariantCard
// ---------------------------------------------------------------------------

class _VariantCard extends StatelessWidget {
  final int index;
  final _VariantForm form;
  final bool canDelete;
  final VoidCallback onDelete;

  const _VariantCard({
    required this.index,
    required this.form,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deco = appInputDeco('', fillColor: AppColors.background, radius: 8, isDense: true);

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Variant $index',
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const AppFieldLabel('Name *'),
          TextFormField(
            controller: form.name,
            textCapitalization: TextCapitalization.words,
            decoration: deco.copyWith(hintText: 'e.g. Small, Large, Red...'),
            style: getOutfitStyle(color: AppColors.textPrimary, fontSize: 14),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Variant name required' : null,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Price *'),
                    TextFormField(
                      controller: form.price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: deco.copyWith(
                        hintText: '0.00',
                        prefixText: '₱ ',
                      ),
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Cost'),
                    TextFormField(
                      controller: form.cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: deco.copyWith(
                        hintText: '0.00',
                        prefixText: '₱ ',
                      ),
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel('Stock'),
                    TextFormField(
                      controller: form.stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: deco.copyWith(hintText: '0'),
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
