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
                            'Variants · Weight · SKU · Retail · Tax',
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
                ? _buildMoreOptionsBody(state, cubit)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  // ── More Options body — Suggested retail price · SKU · Tax ─────────────────

  Widget _buildMoreOptionsBody(ProductFormState state, ProductFormCubit cubit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProductTypeSection(state, cubit),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Divider(height: 1, color: AppColors.borderSoft),
        ),
        _buildRetailPriceSection(state),
        SkuSectionToggle(
          controller: _skuController,
          onAutoSku: () {
            final sku = context.read<ProductFormCubit>().generateSku(
              _nameController.text,
            );
            if (sku.isNotEmpty) _setState(() => _skuController.text = sku);
          },
        ),
        _buildTaxSection(),
        const SizedBox(height: 4),
      ],
    );
  }

  // Product-type switches — variants, sold-by-weight (+ unit picker), recipe.
  Widget _buildProductTypeSection(
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final canRecipe = sl<PermissionService>().canAccessFeature(
      AppFeature.recipeManagement,
    );
    final isFraction = _sellBy == 'fraction';

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
        ToggleRow(
          icon: Icons.straighten_rounded,
          label: 'Sold by weight',
          subtitle: 'Price per kg, litre, or other unit',
          enabled: isFraction,
          onChanged: (v) => _setState(() => _sellBy = v ? 'fraction' : 'unit'),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isFraction
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priced per unit',
                        style: getOutfitStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kWeightUnits
                            .map(
                              (u) => AppFilterChip(
                                label: u,
                                isSelected: _selectedUnit == u,
                                onTap: () =>
                                    _setState(() => _selectedUnit = u),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        if (canRecipe)
          ToggleRow(
            icon: Icons.blender_outlined,
            label: 'Made from ingredients',
            subtitle: 'Deducts ingredient stock when sold',
            enabled: state.trackingMethod == TrackingMethod.recipe,
            onChanged: (v) => _onRecipeModeChanged(v, cubit, state),
          ),
      ],
    );
  }

  // Suggested retail price — checkbox reveal + adaptive editor (single or
  // per-variant). SRP is stored per variant, so a variant product shows one
  // input per variant.
  Widget _buildRetailPriceSection(ProductFormState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToggleRow(
          icon: Icons.price_change_outlined,
          label: 'Suggested retail price',
          subtitle: 'The recommended selling price (SRP)',
          enabled: _showRetailPrice,
          onChanged: (v) => _setState(() {
            _showRetailPrice = v;
            if (!v) _clearRetailPrices();
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showRetailPrice
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: state.hasVariants
                      ? _buildPerVariantRetail()
                      : _buildSingleRetail(),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildSingleRetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppMoneyField(
          controller: _retailPriceController,
          label: 'Suggested retail price',
          textInputAction: TextInputAction.done,
        ),
        _buildSrpBadge(_retailPriceController, _sellingPriceController),
      ],
    );
  }

  Widget _buildPerVariantRetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _variants.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: v.name,
                builder: (context, nameVal, child) {
                  final name = nameVal.text.trim();
                  return Text(
                    name.isEmpty ? 'Variant ${i + 1}' : name,
                    style: getOutfitStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              AppMoneyField(
                controller: v.retail,
                label: 'Suggested retail price',
                textInputAction: TextInputAction.done,
              ),
              _buildSrpBadge(v.retail, v.price),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _clearRetailPrices() {
    _retailPriceController.clear();
    for (final v in _variants) {
      v.retail.clear();
    }
  }

  // VAT / sales tax — toggle + rate field.
  Widget _buildTaxSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
