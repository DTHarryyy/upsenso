part of 'add_products.dart';

extension _AddProductsViewLayout on _AddProductsViewState {
  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext ctx, ProductFormState state) {
    final isEdit = widget.productToEdit != null;
    final pageTitle = isEdit ? 'Edit Product' : 'Add Product';

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: const Color(0x0A101828),
      centerTitle: false,
      toolbarHeight: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Products',
                style: getOutfitStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                pageTitle,
                style: getOutfitStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(pageTitle, style: AppTextStyles.title(ctx)),
        ],
      ),
      actions: [
        if (state.isSaving)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saving…',
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Bottom save bar (mobile / tablet) ─────────────────────────────────────

  Widget _buildBottomSaveBar(ProductFormState state) {
    return SafeArea(
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
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext ctx,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Column(
      children: [
        // Floating premium mode toggle
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: ProductModeToggle(mode: state.mode, onChanged: cubit.switchMode),
        ),
        const Divider(height: 1, color: AppColors.borderSoft),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: _buildFormSections(ctx, state, cubit),
          ),
        ),
      ],
    );
  }

  // ── Desktop layout (2-column) ──────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext ctx,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final maxW = Breakpoints.maxContentWidth(ctx);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main form — scrolls independently
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(32, 28, 20, 48),
                children: _buildFormSections(ctx, state, cubit),
              ),
            ),
            // Sticky sidebar
            SizedBox(
              width: 292,
              child: _buildDesktopSidebar(ctx, state, cubit),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form sections (shared between mobile + desktop) ────────────────────────

  List<Widget> _buildFormSections(
    BuildContext ctx,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    if (state.mode == ProductFormMode.simple) {
      return [
        _buildSimpleSection(state, cubit),
        const SizedBox(height: 16),
        _buildMoreOptionsSection(state, cubit),
        const SizedBox(height: 8),
      ];
    }
    return [
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
    ];
  }

}
