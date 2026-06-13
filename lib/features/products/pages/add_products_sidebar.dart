part of 'add_products.dart';

extension _AddProductsViewSidebar on _AddProductsViewState {
  // ── Desktop sidebar ────────────────────────────────────────────────────────

  Widget _buildDesktopSidebar(
    BuildContext ctx,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 28, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Mode toggle ──
            ProductSidebarLabel(label: 'Mode'),
            const SizedBox(height: 8),
            ProductModeToggle(mode: state.mode, onChanged: cubit.switchMode),

            const SizedBox(height: 24),

            // ── Product preview ──
            ProductSidebarLabel(label: 'Preview'),
            const SizedBox(height: 8),
            _buildProductPreview(state),

            const SizedBox(height: 24),

            // ── Save panel ──
            ProductSidebarLabel(label: 'Publish'),
            const SizedBox(height: 8),
            _buildSidebarSavePanel(state),
          ],
        ),
      ),
    );
  }

  // ── Product preview card ───────────────────────────────────────────────────

  Widget _buildProductPreview(ProductFormState state) {
    final categories = state.categories;
    final selectedCat = categories
        .where((c) => c.id == state.selectedCategoryId)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06101828),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Text(
                'PRODUCT',
                style: getOutfitStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: getOutfitStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image
          Container(
            width: double.infinity,
            height: 108,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: _buildPreviewImage(state),
          ),
          const SizedBox(height: 12),

          // Live name
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (_, nameVal, _) {
              final name = nameVal.text.trim();
              return Text(
                name.isEmpty ? 'Product name' : name,
                style: getOutfitStyle(
                  color: name.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),

          // Live price
          const SizedBox(height: 6),
          _buildPreviewPrice(state),

          // Category chip
          if (selectedCat != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                selectedCat.name,
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewImage(ProductFormState state) {
    final path = state.imagePath;
    if (path == null) {
      return const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
      );
    }
    if (path.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
        ),
      );
    }
    if (!kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
    );
  }

  Widget _buildPreviewPrice(ProductFormState state) {
    final ctrl = state.mode == ProductFormMode.simple
        ? _simplePriceController
        : _sellingPriceController;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, priceVal, _) {
        final raw = priceVal.text.trim();
        final price = double.tryParse(raw);
        if (price == null || price <= 0) {
          return Text(
            '—',
            style: getOutfitStyle(color: AppColors.textMuted, fontSize: 13),
          );
        }
        return Text(
          '₱ ${price.toStringAsFixed(2)}',
          style: getOutfitStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        );
      },
    );
  }

  // ── Sidebar save panel ─────────────────────────────────────────────────────

  Widget _buildSidebarSavePanel(ProductFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: state.isSaving
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brand.withAlpha(30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saving changes…',
                          style: getOutfitStyle(
                            color: AppColors.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AppFilledButton(
          label: widget.productToEdit != null
              ? 'Update Product'
              : 'Save Product',
          loading: state.isSaving,
          onPressed: state.isSaving ? null : _save,
        ),
        const SizedBox(height: 10),
        // Keyboard shortcut hint
        Center(
          child: Text(
            '⌘ + S  to save',
            style: getOutfitStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

}
