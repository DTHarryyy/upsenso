import 'package:pos/features/business/domain/entities/business_template.dart';

/// Offline fallback templates used when Supabase is unreachable.
///
/// UUIDs MUST match the fixed UUIDs seeded in:
/// supabase/migrations/20260601000000_add_business_templates_and_template_id.sql
///
/// Adding a new template: add a row here AND in the migration seed data.
class DefaultBusinessTemplates {
  DefaultBusinessTemplates._();

  // ── Stable UUIDs — keep in sync with migration seed ──────────────────────
  static const coffeeShopId       = '00000000-0001-0001-0001-000000000001';
  static const restaurantId       = '00000000-0002-0002-0002-000000000002';
  static const groceryStoreId     = '00000000-0003-0003-0003-000000000003';
  static const convenienceStoreId = '00000000-0004-0004-0004-000000000004';
  static const bakeryId           = '00000000-0005-0005-0005-000000000005';
  static const pharmacyId         = '00000000-0006-0006-0006-000000000006';
  static const retailStoreId      = '00000000-0007-0007-0007-000000000007';
  static const hardwareStoreId    = '00000000-0008-0008-0008-000000000008';
  static const salonId            = '00000000-0009-0009-0009-000000000009';
  static const electronicsStoreId = '00000000-0010-0010-0010-000000000010';

  /// Maps stable UUIDs → code string for rows cached before the schema upgrade.
  static String codeFromId(String id) {
    const map = {
      coffeeShopId:       'coffee_shop',
      restaurantId:       'restaurant',
      groceryStoreId:     'grocery_store',
      convenienceStoreId: 'convenience_store',
      bakeryId:           'bakery',
      pharmacyId:         'pharmacy',
      retailStoreId:      'retail_store',
      hardwareStoreId:    'hardware_store',
      salonId:            'salon_barbershop',
      electronicsStoreId: 'electronics_store',
    };
    return map[id] ?? '';
  }

  static List<BusinessTemplate> get all => [
    const BusinessTemplate(
      id: coffeeShopId,
      code: 'coffee_shop',
      name: 'Coffee Shop',
      description: 'Perfect for cafes serving hot and cold beverages with food options',
    ),
    const BusinessTemplate(
      id: restaurantId,
      code: 'restaurant',
      name: 'Restaurant',
      description: 'Full-service dining with kitchen operations and table management',
    ),
    const BusinessTemplate(
      id: groceryStoreId,
      code: 'grocery_store',
      name: 'Grocery Store',
      description: 'Full grocery setup with broad product categories and stock tracking',
    ),
    const BusinessTemplate(
      id: convenienceStoreId,
      code: 'convenience_store',
      name: 'Convenience Store',
      description: 'Quick-service retail with everyday essentials and fast checkout',
    ),
    const BusinessTemplate(
      id: bakeryId,
      code: 'bakery',
      name: 'Bakery',
      description: 'Bakery and pastry shop with fresh baked goods and daily specials',
    ),
    const BusinessTemplate(
      id: pharmacyId,
      code: 'pharmacy',
      name: 'Pharmacy',
      description: 'Pharmacy and drugstore with controlled inventory and compliance needs',
    ),
    const BusinessTemplate(
      id: retailStoreId,
      code: 'retail_store',
      name: 'Retail Store',
      description: 'General retail for clothing, accessories, and lifestyle products',
    ),
    const BusinessTemplate(
      id: hardwareStoreId,
      code: 'hardware_store',
      name: 'Hardware Store',
      description: 'Tools, building materials, and construction supplies',
    ),
    const BusinessTemplate(
      id: salonId,
      code: 'salon_barbershop',
      name: 'Salon & Barbershop',
      description: 'Beauty and grooming services with product retail',
    ),
    const BusinessTemplate(
      id: electronicsStoreId,
      code: 'electronics_store',
      name: 'Electronics Store',
      description: 'Consumer electronics, gadgets, and accessories with warranty tracking',
    ),
  ];
}
