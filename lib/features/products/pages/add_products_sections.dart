part of 'add_products.dart';

extension _AddProductsViewSections on _AddProductsViewState {
  // ── Basics (photo + name + category) ───────────────────────────────────────

  Widget _buildBasicInfoSection(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return AppSectionCard(
      title: 'Basics',
      icon: Icons.info_outline_rounded,
      children: [
        // A square photo on the left, sized to span both stacked fields (name
        // + category) on the right for a balanced two-row block.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The placeholder is the affordance, so there's no separate
            // "add photo" toggle.
            SizedBox(
              width: 116,
              height: 116,
              child: ImagePickerField(
                compact: true,
                imagePath: state.imagePath,
                onPick: (source) => cubit.pickImage(source),
                onClear: cubit.clearImage,
                isLoading: state.isUploadingImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: appInputDeco(
                      'e.g. Espresso, White Rice 5kg…',
                      label: 'Product name',
                    ),
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Product name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    value: state.selectedCategoryId,
                    hint: 'No category',
                    addItemLabel: 'Add Category',
                    onAddItem: _showAddCategorySheet,
                    items: state.categories
                        .map(
                          (c) => AppDropdownItem(value: c.id, label: c.name),
                        )
                        .toList(),
                    onChanged: cubit.selectCategory,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Track-stock header trailing (shared by Pricing + Variants cards) ───────

  Widget _trackStockTrailing(ProductFormState state, ProductFormCubit cubit) {
    return GestureDetector(
      onTap: () => cubit.setTrackInventory(!state.trackInventory),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Track stock',
            style: getOutfitStyle(
              color: state.trackInventory
                  ? AppColors.brand
                  : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Checkbox(
            value: state.trackInventory,
            onChanged: (v) => cubit.setTrackInventory(v ?? false),
            activeColor: AppColors.brand,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: AppColors.borderSoft, width: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Pricing & Inventory (no-variants) ──────────────────────────────────────

  Widget _buildPricingSection(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';
    final isAllBranchesEdit =
        widget.productToEdit != null && cubit.selectedBranchId == null;

    return AppSectionCard(
      title: 'Pricing & Inventory',
      icon: Icons.attach_money_rounded,
      trailing: _trackStockTrailing(state, cubit),
      children: [
        AppMoneyField(
          controller: _sellingPriceController,
          label: 'Selling price',
          emphasized: true,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Selling price is required'
              : null,
        ),
        _buildTaxInclusivePreview(),
        const SizedBox(height: 14),
        AppMoneyField(
          controller: _costPriceController,
          label: 'Cost price',
        ),
        // Recipe summary row (no-variants mode)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: state.trackingMethod == TrackingMethod.recipe
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RecipeSummaryRow(
                    lines: state.recipeLines,
                    sellingPriceController: _sellingPriceController,
                    onEdit: () => _showRecipeBuilderSheet(
                      context,
                      title: 'Recipe',
                      initialLines: state.recipeLines,
                      sellingPrice: double.tryParse(
                        _sellingPriceController.text.trim(),
                      ),
                      onSave: cubit.setRecipeLines,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        // Stock + low-stock fields — revealed by the header Track-stock checkbox.
        _buildStockFields(state, isFraction, isAllBranchesEdit),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.borderSoft),
        const SizedBox(height: 8),
        BarcodesEditor(
          controllers: _barcodeControllers,
          onGenerate: cubit.generateUniqueBarcode,
          onAdd: _addBarcode,
          onRemove: _removeBarcode,
        ),
      ],
    );
  }

  // Live tax-inclusive "Customer sees ₱X" hint under the selling price.
  Widget _buildTaxInclusivePreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _sellingPriceController,
      builder: (context, sellVal, child) =>
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _taxController,
            builder: (context, taxVal, child) {
              final base = double.tryParse(sellVal.text.trim());
              final taxPct = double.tryParse(taxVal.text.trim());
              if (base == null || base <= 0 || taxPct == null || taxPct <= 0) {
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brand.withAlpha(40)),
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
    );
  }

  // Above/below-SRP margin badge comparing [retailCtrl] against [priceCtrl].
  Widget _buildSrpBadge(
    TextEditingController retailCtrl,
    TextEditingController priceCtrl,
  ) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: retailCtrl,
      builder: (context, retailVal, child) =>
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: priceCtrl,
            builder: (context, sellVal, child) {
              final srp = double.tryParse(retailVal.text.trim());
              final sell = double.tryParse(sellVal.text.trim());
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
              final String lbl = isAbove
                  ? '${pct.toStringAsFixed(1)}% above SRP — selling above suggested price'
                  : isBelow
                  ? '${pct.toStringAsFixed(1)}% below SRP'
                  : 'Selling at SRP';
              final IconData ico = isAbove
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ico, size: 12, color: fg),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lbl,
                          overflow: TextOverflow.ellipsis,
                          style: getOutfitStyle(
                            color: fg,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // Stock + low-stock alert fields, revealed when Track stock is on.
  Widget _buildStockFields(
    ProductFormState state,
    bool isFraction,
    bool isAllBranchesEdit,
  ) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: state.trackInventory
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              isFraction ? 'e.g. 1.5' : 'e.g. 100',
                              label: isFraction
                                  ? 'Stock on hand ($_selectedUnit)'
                                  : 'Stock on hand',
                              fillColor: isAllBranchesEdit
                                  ? AppColors.surfaceAlt
                                  : null,
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
                    const SizedBox(height: 10),
                    _buildInfoBanner(
                      'Showing total stock across all branches. '
                      'To adjust stock for a specific branch, use the Inventory page.',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.info,
                      background: AppColors.infoSoft,
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Future<void> _showRecipeBuilderSheet(
    BuildContext ctx, {
    required String title,
    required List<RecipeLineFormEntry> initialLines,
    required void Function(List<RecipeLineFormEntry>) onSave,
    double? sellingPrice,
    List<RecipeLineFormEntry> templateLines = const [],
    String? templateLabel,
  }) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeBuilderSheet(
        title: title,
        initialLines: initialLines,
        sellingPrice: sellingPrice,
        businessId: context.read<ProductFormCubit>().businessId,
        onSave: onSave,
        templateLines: templateLines,
        templateLabel: templateLabel,
      ),
    );
  }

  /// Opens the recipe builder for a specific variant.
  /// Finds the first other variant that already has ingredients and offers
  /// it as a "Copy from Variant X" shortcut.
  Future<void> _showVariantRecipeSheet(BuildContext ctx, int index) async {
    final v = _variants[index];

    // Find the nearest earlier variant with lines to offer as a copy template.
    VariantForm? templateVariant;
    String? templateLabel;
    for (int j = 0; j < _variants.length; j++) {
      if (j != index && _variants[j].recipeLines.isNotEmpty) {
        templateVariant = _variants[j];
        final name = _variants[j].name.text.trim();
        templateLabel =
            'Copy from ${name.isEmpty ? 'Variant ${j + 1}' : name}';
        break;
      }
    }

    await _showRecipeBuilderSheet(
      ctx,
      title: () {
        final name = v.name.text.trim();
        return name.isEmpty ? 'Variant $index Recipe' : '$name Recipe';
      }(),
      initialLines: v.recipeLines,
      sellingPrice: double.tryParse(v.price.text.trim()),
      templateLines: templateVariant?.recipeLines ?? const [],
      templateLabel: templateLabel,
      onSave: (lines) => _setState(() => v.recipeLines = lines),
    );
  }

  // ── Variants ───────────────────────────────────────────────────────────────

  Widget _buildVariantsSection(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';
    final isAllBranchesEdit =
        widget.productToEdit != null && cubit.selectedBranchId == null;

    return AppSectionCard(
      title: 'Variants',
      icon: Icons.tune_rounded,
      trailing: _trackStockTrailing(state, cubit),
      children: [
        if (widget.initialBarcode?.isNotEmpty == true) ...[
          _buildInfoBanner(
            'Barcode pre-assigned to Variant 1 — '
            '${widget.initialBarcode!}\n'
            'Move it to the correct variant using the barcode field below.',
            icon: Icons.qr_code_rounded,
            color: AppColors.brand,
            background: AppColors.brandSoft,
          ),
          const SizedBox(height: 12),
        ],
        ..._variants.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          final isRecipe = state.trackingMethod == TrackingMethod.recipe;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VariantCard(
              index: i + 1,
              form: v,
              isFraction: isFraction,
              unitLabel: _selectedUnit,
              trackInventory: state.trackInventory,
              canDelete: _variants.length > 1,
              onDelete: () => _setState(() {
                v.dispose();
                _variants.removeAt(i);
              }),
              stockReadOnly: isAllBranchesEdit,
              isRecipeMode: isRecipe,
              onEditRecipe: () => _showVariantRecipeSheet(context, i),
              onGenerateBarcode: cubit.generateUniqueBarcode,
            ),
          );
        }),
        if (isAllBranchesEdit && state.trackInventory) ...[
          const SizedBox(height: 4),
          _buildInfoBanner(
            'Showing total stock across all branches. '
            'To adjust stock for a specific branch, use the Inventory page.',
            icon: Icons.info_outline_rounded,
            color: AppColors.info,
            background: AppColors.infoSoft,
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () => _setState(() => _variants.add(VariantForm())),
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
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 46),
          ),
        ),
      ],
    );
  }
}
