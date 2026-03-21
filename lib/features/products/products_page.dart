import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/widgets/product_grid.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _categoriesDao = sl<CategoriesDao>();

  final List<Map<String, String>> products = [
    {
      'name': 'Shrimp Basil Salad',
      'price': '\$10.00',
      'image': 'assets/images/shrimp_basil_salad.png',
    },
    {
      'name': 'Onion Rings',
      'price': '\$5.00',
      'image': 'assets/images/onion_rings.png',
    },
  ];

  String selectedCategory = 'All';
  String selectedBrand = 'All Brands';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final businessId = authState is AuthAuthenticated
        ? authState.user.businessId
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<CategoriesTableData>>(
          stream: businessId != null
              ? _categoriesDao.watchByBusinessId(businessId)
              : const Stream.empty(),
          builder: (context, snapshot) {
            final dbCategories = snapshot.data ?? [];
            final categories = [
              'All',
              ...dbCategories.map((c) => c.name),
            ];
            // Reset selection if current category no longer exists
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductSearchBar(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    selectedBrand: selectedBrand,
                    onCategoryChanged: (value) {
                      if (value != null) setState(() => selectedCategory = value);
                    },
                    onBrandChanged: (value) {
                      if (value != null) setState(() => selectedBrand = value);
                    },
                    onSearchChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),

                  const SizedBox(height: 12),

                  ProductCategoryChips(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: (cat) {
                      setState(() => selectedCategory = cat);
                    },
                  ),

                  const SizedBox(height: 16),

                  Expanded(child: ProductGrid(products: products)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductSearchBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final String selectedBrand;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String> onSearchChanged;

  const ProductSearchBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedBrand,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search in products',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
            ),
            style: getOutfitStyle(color: AppColors.textPrimary),
            onChanged: onSearchChanged,
          ),
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBrand,
              items: ['All Brands', 'Brand A', 'Brand B', 'Brand C']
                  .map(
                    (brand) => DropdownMenuItem(
                      value: brand,
                      child: Text(
                        brand,
                        style: getOutfitStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onBrandChanged,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
              ),
              style: getOutfitStyle(color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const ProductCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(
              cat,
              style: getOutfitStyle(
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.brand,
            checkmarkColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.brand : AppColors.borderSoft,
              width: isSelected ? 2 : 1,
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(cat),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}

