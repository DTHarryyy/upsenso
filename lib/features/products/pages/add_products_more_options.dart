part of 'add_products.dart';

extension _AddProductsViewMoreOptions on _AddProductsViewState {
  // ── More Options (collapsible) ────────────────────────────────────────────

  Widget _buildMoreOptionsSection(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x04101828),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible header
          InkWell(
            onTap: cubit.toggleMoreOptions,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withAlpha(18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More options',
                          style: AppTextStyles.subtitle(context).copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!state.moreOptionsExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            state.mode == ProductFormMode.simple
                                ? 'Photo · Barcode · Sold by weight'
                                : 'Variants · Ingredients · Photo · SKU · Tax',
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
                    duration: const Duration(milliseconds: 220),
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

  // ── Simple — More Options body ─────────────────────────────────────────────

  Widget _buildSimpleMoreOptionsBody(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToggleRow(
          icon: Icons.straighten_rounded,
          label: 'Sold by weight',
          subtitle: 'Price per kg, litre, or other unit',
          enabled: _sellBy == 'fraction',
          onChanged: (v) => _setState(() => _sellBy = v ? 'fraction' : 'unit'),
        ),
        ToggleRow(
          icon: Icons.image_outlined,
          label: 'Product photo',
          subtitle: 'Add a photo for faster recognition',
          enabled: _showImagePicker || state.imagePath != null,
          onChanged: (v) {
            _setState(() => _showImagePicker = v);
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
        ToggleRow(
          icon: Icons.qr_code_rounded,
          label: 'Barcode',
          subtitle: 'Scan or type the product barcode',
          enabled: _showSimpleBarcode,
          onChanged: (v) => _setState(() {
            _showSimpleBarcode = v;
            if (!v) _simpleBarcodeController.clear();
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showSimpleBarcode
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextFormField(
                    controller: _simpleBarcodeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: appInputDeco('Scan or type barcode').copyWith(
                      prefixIcon: const Icon(
                        Icons.qr_code_rounded,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                    ),
                    style: getOutfitStyle(color: AppColors.textPrimary),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Advanced — More Options body ──────────────────────────────────────────

  Widget _buildMoreOptionsBody(ProductFormState state, ProductFormCubit cubit) {
    final isFraction = _sellBy == 'fraction';
    final isAllBranchesEdit =
        widget.productToEdit != null && cubit.selectedBranchId == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToggleRow(
          icon: Icons.tune_rounded,
          label: 'Multiple sizes or options',
          subtitle: 'e.g. Small / Medium / Large — each with its own price',
          enabled: state.hasVariants,
          onChanged: cubit.setHasVariants,
        ),
        if (sl<PermissionService>().canAccessFeature(
          AppFeature.recipeManagement,
        ))
          ToggleRow(
            icon: Icons.blender_outlined,
            label: 'Made from ingredients',
            subtitle: 'Deducts ingredient stock when sold',
            enabled: state.trackingMethod == TrackingMethod.recipe,
            onChanged: (v) => _onRecipeModeChanged(v, cubit, state),
          ),
        if (!state.hasVariants &&
            state.trackingMethod == TrackingMethod.productStock) ...[
          ToggleRow(
            icon: Icons.inventory_2_outlined,
            label: 'Track stock',
            subtitle: 'Show stock counts and low-stock alerts',
            enabled: state.trackInventory,
            onChanged: cubit.setTrackInventory,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: state.trackInventory
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                                          decimal: true)
                                      : TextInputType.number,
                                  inputFormatters: isFraction
                                      ? [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,3}')),
                                        ]
                                      : [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                  textInputAction: TextInputAction.next,
                                  decoration: appInputDeco(
                                    isFraction ? '0.000' : '0',
                                    label: isFraction ? 'Stock (kg)' : 'Stock',
                                    fillColor: isAllBranchesEdit
                                        ? AppColors.surfaceAlt
                                        : null,
                                  ),
                                  style: getOutfitStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16),
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
                                decoration: appInputDeco('e.g. 5',
                                    label: 'Low stock alert'),
                                style: getOutfitStyle(
                                    color: AppColors.textPrimary, fontSize: 16),
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
          ),
        ],
        ToggleRow(
          icon: Icons.straighten_rounded,
          label: 'Sold by weight',
          subtitle: 'Price per kg, litre, or other unit',
          enabled: _sellBy == 'fraction',
          onChanged: (v) => _setState(() => _sellBy = v ? 'fraction' : 'unit'),
        ),
        ToggleRow(
          icon: Icons.image_outlined,
          label: 'Product photo',
          subtitle: 'Add a photo for faster recognition',
          enabled: _showImagePicker || state.imagePath != null,
          onChanged: (v) {
            _setState(() => _showImagePicker = v);
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
        BarcodesSectionToggle(
          controllers: _barcodeControllers,
          onAdd: _addBarcode,
          onRemove: _removeBarcode,
        ),
        SkuSectionToggle(
          controller: _skuController,
          onAutoSku: () {
            final sku = context.read<ProductFormCubit>().generateSku(
              _nameController.text,
            );
            if (sku.isNotEmpty) _setState(() => _skuController.text = sku);
          },
        ),
        // Retail price (toggleable)
        ToggleRow(
          icon: Icons.price_change_outlined,
          label: 'Suggested retail price',
          subtitle: 'The recommended selling price (SRP)',
          enabled: _showRetailPrice,
          onChanged: (v) => _setState(() {
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
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        // VAT / sales tax (toggleable)
        ToggleRow(
          icon: Icons.receipt_long_outlined,
          label: 'VAT or sales tax',
          subtitle: 'Added at checkout',
          enabled: _showTax,
          onChanged: (v) => _setState(() {
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
        // Track expiry
        ToggleRow(
          icon: Icons.event_rounded,
          label: 'Track expiry',
          subtitle: 'Enable for perishable or dated items',
          enabled: state.trackExpiry,
          onChanged: context.read<ProductFormCubit>().setTrackExpiry,
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

  // ── Shared info banner ─────────────────────────────────────────────────────

  Widget _buildInfoBanner(
    String message, {
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: getOutfitStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
