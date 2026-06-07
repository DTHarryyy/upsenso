import 'package:pos/core/seeding/default_business_templates.dart';

/// Hardcoded fallback categories per business template.
/// Used offline when the server template cannot be reached.
/// The authoritative categories live in business_templates.default_categories.
class DefaultCategories {
  DefaultCategories._();

  // ── Categories by template UUID (primary lookup) ──────────────────────────
  static const Map<String, List<String>> _byId = {
    DefaultBusinessTemplates.coffeeShopId: [
      'Espresso Drinks',
      'Cold Beverages',
      'Tea & Others',
      'Pastries & Cakes',
      'Food & Snacks',
    ],
    DefaultBusinessTemplates.restaurantId: [
      'Appetizers',
      'Main Course',
      'Soups & Salads',
      'Desserts',
      'Beverages',
    ],
    DefaultBusinessTemplates.groceryStoreId: [
      'Beverages',
      'Dairy & Eggs',
      'Bread & Bakery',
      'Canned & Packaged',
      'Snacks',
      'Personal Care',
      'Household',
    ],
    DefaultBusinessTemplates.convenienceStoreId: [
      'Beverages',
      'Snacks',
      'Frozen & Refrigerated',
      'Personal Care',
      'Household Items',
    ],
    DefaultBusinessTemplates.bakeryId: [
      'Breads',
      'Cakes & Desserts',
      'Pastries & Cookies',
      'Beverages',
      'Savory Items',
    ],
    DefaultBusinessTemplates.pharmacyId: [
      'Prescription Medicines',
      'OTC Medicines',
      'Vitamins & Supplements',
      'Personal Care',
      'Baby Care',
    ],
    DefaultBusinessTemplates.retailStoreId: [
      'Clothing',
      'Footwear',
      'Accessories',
      'Bags',
      'Home & Living',
    ],
    DefaultBusinessTemplates.hardwareStoreId: [
      'Power Tools',
      'Hand Tools',
      'Electrical',
      'Plumbing',
      'Building Materials',
      'Paint & Finishing',
    ],
    DefaultBusinessTemplates.salonId: [
      'Hair Services',
      'Nail Services',
      'Skin Care',
      'Hair Products',
      'Tools & Accessories',
    ],
    DefaultBusinessTemplates.electronicsStoreId: [
      'Smartphones',
      'Laptops & Computers',
      'Audio & Video',
      'Gaming',
      'Accessories & Cables',
    ],
  };

  // ── Name-based fallback (for compatibility with older code) ─────────────────
  static const Map<String, List<String>> _byName = {
    'coffee shop': [
      'Espresso Drinks',
      'Cold Beverages',
      'Tea & Others',
      'Pastries & Cakes',
      'Food & Snacks',
    ],
    'restaurant': [
      'Appetizers',
      'Main Course',
      'Soups & Salads',
      'Desserts',
      'Beverages',
    ],
    'grocery store': [
      'Beverages',
      'Dairy & Eggs',
      'Bread & Bakery',
      'Canned & Packaged',
      'Snacks',
      'Personal Care',
      'Household',
    ],
    'convenience store': [
      'Beverages',
      'Snacks',
      'Frozen & Refrigerated',
      'Personal Care',
      'Household Items',
    ],
    'bakery': [
      'Breads',
      'Cakes & Desserts',
      'Pastries & Cookies',
      'Beverages',
      'Savory Items',
    ],
    'pharmacy': [
      'Prescription Medicines',
      'OTC Medicines',
      'Vitamins & Supplements',
      'Personal Care',
      'Baby Care',
    ],
    'retail store': [
      'Clothing',
      'Footwear',
      'Accessories',
      'Bags',
      'Home & Living',
    ],
    'hardware store': [
      'Power Tools',
      'Hand Tools',
      'Electrical',
      'Plumbing',
      'Building Materials',
      'Paint & Finishing',
    ],
    'salon & barbershop': [
      'Hair Services',
      'Nail Services',
      'Skin Care',
      'Hair Products',
      'Tools & Accessories',
    ],
    'salon': [
      'Hair Services',
      'Nail Services',
      'Skin Care',
      'Hair Products',
      'Tools & Accessories',
    ],
    'electronics store': [
      'Smartphones',
      'Laptops & Computers',
      'Audio & Video',
      'Gaming',
      'Accessories & Cables',
    ],
  };

  static const _fallback = ['General', 'Products', 'Services'];

  /// Primary lookup: use template UUID when available.
  static List<String> forTemplateId(String templateId) =>
      _byId[templateId] ?? _fallback;

  /// Legacy lookup by template name string.
  /// Matches case-insensitively with substring fallback.
  static List<String> forTemplate(String templateName) {
    final lower = templateName.toLowerCase().trim();
    if (_byName.containsKey(lower)) return _byName[lower]!;
    for (final entry in _byName.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return _fallback;
  }
}
