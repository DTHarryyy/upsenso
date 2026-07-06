import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/data/holder/variant_form.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/presentation/cubit/product_form_cubit.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';
import 'package:pos/features/products/widgets/barcodes_editor.dart';
import 'package:pos/features/products/widgets/branch_assignment_sheet.dart';
import 'package:pos/features/products/widgets/image_picker_field.dart';
import 'package:pos/features/products/widgets/product_sidebar_label.dart';
import 'package:pos/features/products/widgets/recipe_builder_sheet.dart';
import 'package:pos/features/products/widgets/recipe_summary_row.dart';
import 'package:pos/features/products/widgets/sku_section_toggle.dart';
import 'package:pos/features/products/widgets/toggle_row.dart';
import 'package:pos/features/products/widgets/variant_card_state.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/permission_service.dart';

part 'add_products_layout.dart';
part 'add_products_sidebar.dart';
part 'add_products_sections.dart';
part 'add_products_more_options.dart';

// Units offered for weighed products (sellBy == 'fraction').
const List<String> _kWeightUnits = ['kg', 'g', 'L', 'ml'];

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
        final String? effectiveBranchId;
        if (branchCubit.state.selectedBranch == BranchCubit.allBranchesLabel) {
          effectiveBranchId = null;
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

  // No-variants pricing
  final _sellingPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _taxController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();

  // Inline reveal toggles (UI-only, not in cubit)
  bool _showRetailPrice = false;
  bool _showTax = false;

  // Identifiers
  final _skuController = TextEditingController();
  final _newCategoryController = TextEditingController();
  // Multiple barcodes for the no-variants (Default) variant.
  final List<TextEditingController> _barcodeControllers = [
    TextEditingController(),
  ];

  // Shared UI state
  String _sellBy = 'unit';

  // Unit of measure for weighed products (kg/g/L/ml). Applied to every variant.
  String _selectedUnit = 'kg';

  // Variants (advanced + hasVariants)
  final List<VariantForm> _variants = [VariantForm()];

  // Relay for setState — @protected cannot be called from extension methods in part files
  void _setState(VoidCallback fn) => setState(fn);

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
        _variants[0].barcodes[0].text = widget.initialBarcode!;
      });
    }
  }

  Future<void> _initForEdit(Product product) async {
    if (!mounted) return;
    final cubit = context.read<ProductFormCubit>();

    cubit.initEditState(product);

    _nameController.text = product.name;
    setState(() => _sellBy = product.sellBy);

    final variants = await cubit.loadVariants(product.id);
    if (!mounted) return;
    final branchStock = await cubit.loadBranchStockMap(
      variants.map((v) => v.id).toList(),
    );
    if (!mounted) return;

    // Restore the weighed unit from the first variant that has one.
    for (final v in variants) {
      if (v.unit != null && v.unit!.isNotEmpty) {
        _selectedUnit = v.unit!;
        break;
      }
    }

    final isRecipe = product.trackingMethod == 'recipe';
    final hasStock = variants.any((v) => v.trackStock);
    if (hasStock) cubit.setTrackInventory(true);

    // Load recipe lines per variant (edit mode — no base/scale concept yet).
    Map<String, List<RecipeLineFormEntry>> variantRecipeLines = {};
    if (isRecipe) {
      if (product.hasVariants) {
        variantRecipeLines = await cubit.loadVariantRecipeLines(
          variants.where((v) => v.isActive).map((v) => v.id).toList(),
        );
      } else {
        await cubit.loadRecipeLinesForProduct(product.id);
      }
    }

    // Load each variant's barcodes from the normalized store (falls back to the
    // legacy comma column for any pre-backfill row).
    final barcodeMap = await cubit.loadBarcodesForVariants(
      variants.where((v) => v.isActive).map((v) => v.id).toList(),
    );
    if (!mounted) return;
    List<String> codesFor(ProductVariantsTableData v) {
      final loaded = barcodeMap[v.id];
      if (loaded != null && loaded.isNotEmpty) return loaded;
      final legacy = v.barcode;
      if (legacy != null && legacy.trim().isNotEmpty) {
        return legacy.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      }
      return const [];
    }

    double stockFor(ProductVariantsTableData v) => branchStock[v.id] ?? v.stock;

    if (product.hasVariants) {
      _variants.clear();
      for (final v in variants.where((v) => v.isActive)) {
        final form = VariantForm();
        form.name.text = v.name == 'Default' ? '' : v.name;
        form.price.text = v.price.toStringAsFixed(2);
        if (v.costPrice != null) {
          form.cost.text = v.costPrice!.toStringAsFixed(2);
        }
        if (v.retailPrice != null) {
          form.retail.text = v.retailPrice!.toStringAsFixed(2);
          _showRetailPrice = true;
        }
        form.stock.text = stockFor(v).toString();
        if (v.lowStockAlert != null) {
          form.lowStock.text = v.lowStockAlert.toString();
        }
        _setBarcodeControllers(form.barcodes, codesFor(v));
        form.recipeLines = variantRecipeLines[v.id] ?? [];
        _variants.add(form);
      }
      if (_variants.isEmpty) _variants.add(VariantForm());
    } else {
      final v = variants.firstOrNull;
      if (v != null) {
        final taxRate = (product.tax ?? 0.0) / 100.0;
        final basePrice = taxRate > 0 ? v.price / (1 + taxRate) : v.price;
        _sellingPriceController.text = basePrice.toStringAsFixed(2);
        if (v.costPrice != null) {
          _costPriceController.text = v.costPrice!.toStringAsFixed(2);
        }
        _setBarcodeControllers(_barcodeControllers, codesFor(v));
        final qty = stockFor(v);
        if (qty > 0) _stockController.text = qty.toString();
        if (v.lowStockAlert != null) {
          _lowStockController.text = v.lowStockAlert.toString();
        }
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

    // Expand "More options" when it holds data (SRP, SKU, or tax).
    final hasMoreData =
        _showTax || _showRetailPrice || product.sku?.isNotEmpty == true;
    if (hasMoreData && !cubit.state.moreOptionsExpanded) {
      cubit.toggleMoreOptions();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _sellingPriceController.dispose();
    _retailPriceController.dispose();
    _costPriceController.dispose();
    _taxController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _skuController.dispose();
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
    setState(() => _barcodeControllers.removeAt(index).dispose());
  }

  /// Rebuilds a barcode-controller list from [codes] (one controller per code,
  /// or a single empty one when there are none). Disposes the old controllers.
  void _setBarcodeControllers(
    List<TextEditingController> list,
    List<String> codes,
  ) {
    for (final c in list) {
      c.dispose();
    }
    list.clear();
    if (codes.isEmpty) {
      list.add(TextEditingController());
    } else {
      for (final code in codes) {
        list.add(TextEditingController(text: code));
      }
    }
  }

  Future<void> _onRecipeModeChanged(
    bool enable,
    ProductFormCubit cubit,
    ProductFormState state,
  ) async {
    if (!enable) {
      final hasData =
          state.recipeLines.isNotEmpty ||
          _variants.any((v) => v.recipeLines.isNotEmpty);
      if (hasData) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Remove recipe?', style: AppTextStyles.title(ctx)),
            content: Text(
              'Switching off will clear all ingredient data you\'ve entered.',
              style: getOutfitStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: getOutfitStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Remove',
                  style: getOutfitStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        // Clear per-variant recipe lines
        for (final v in _variants) {
          v.recipeLines = [];
        }
      }
    }
    cubit.setTrackingMethod(
      enable ? TrackingMethod.recipe : TrackingMethod.productStock,
    );
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
                          } catch (e, st) {
                            debugPrint('[AddProducts] Error in addCategory: $e\n$st');
                            saving.value = false;
                            if (!sheetCtx.mounted) return;
                            AppToast.show(
                              sheetCtx,
                              'Failed to save',
                              subtitle: AppErrorMapper.message(e),
                              variant: AppToastVariant.error,
                            );
                            return;
                          }
                          if (!sheetCtx.mounted) return;
                          Navigator.of(sheetCtx).pop();
                          if (mounted) {
                            AppToast.show(context, 'Category saved');
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
    final hasVariants = state.hasVariants;

    final formData = ProductFormData(
      name: _nameController.text,
      sellBy: _sellBy,
      unit: _sellBy == 'fraction' ? _selectedUnit : null,
      sellingPrice: !hasVariants ? _sellingPriceController.text : null,
      retailPrice: !hasVariants ? _retailPriceController.text : null,
      costPrice: !hasVariants ? _costPriceController.text : null,
      taxPercent: !hasVariants ? _taxController.text : null,
      stock: (!hasVariants && state.trackInventory)
          ? _stockController.text
          : null,
      lowStockAlert: (!hasVariants && state.trackInventory)
          ? _lowStockController.text
          : null,
      imagePath: state.imagePath,
      trackingMethod: state.trackingMethod,
      recipeLines: state.recipeLines,
      barcodes: _barcodeControllers.map((c) => c.text).toList(),
      sku: _skuController.text,
      variants: hasVariants
          ? _variants
                .map(
                  (v) => VariantFormData(
                    name: v.name.text,
                    price: v.price.text,
                    costPrice: v.cost.text,
                    retailPrice: v.retail.text,
                    stock: v.stock.text,
                    lowStockAlert: v.lowStock.text,
                    barcodes: v.barcodes.map((c) => c.text).toList(),
                    recipeLines: state.trackingMethod == TrackingMethod.recipe
                        ? v.recipeLines
                        : const [],
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

  Future<void> _showBranchAssignmentDialog(
    BuildContext ctx,
    ProductFormCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BranchAssignmentSheet(
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
          AppToast.show(
            context,
            'Failed to save: ${state.error}',
            variant: AppToastVariant.error,
          );
        }
      },
      child: BlocBuilder<ProductFormCubit, ProductFormState>(
        builder: (ctx, state) {
          final cubit = ctx.read<ProductFormCubit>();
          final screenWidth = MediaQuery.sizeOf(ctx).width;
          final isDesktop = screenWidth >= 1024;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(ctx, state),
            // Sticky bottom save bar — mobile & tablet only
            bottomNavigationBar: isDesktop ? null : _buildBottomSaveBar(state),
            body: Form(
              key: _formKey,
              child: isDesktop
                  ? _buildDesktopLayout(ctx, state, cubit)
                  : _buildMobileLayout(ctx, state, cubit),
            ),
          );
        },
      ),
    );
  }
}
