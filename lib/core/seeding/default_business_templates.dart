import 'package:pos/features/business/domain/entities/business_template.dart';

/// Hardcoded business templates used as fallback when Supabase is unreachable
/// or the `business_templates` table is empty.
///
/// UUIDs and data must stay in sync with the Supabase `business_templates` rows.
class DefaultBusinessTemplates {
  DefaultBusinessTemplates._();

  static const _allPermissions = {'all': true};

  static const _cashierPermissions = {
    'pos': true,
    'view_reports': false,
    'manage_inventory': false,
  };

  static const _basicStaffPermissions = {
    'pos': true,
    'view_reports': false,
    'manage_inventory': false,
  };

  static const _stockClerkPermissions = {
    'pos': false,
    'view_reports': false,
    'manage_inventory': true,
  };

  static const _pharmacistPermissions = {
    'pos': true,
    'view_reports': true,
    'manage_inventory': true,
  };

  // ── UUIDs matching Supabase business_templates table ──
  static const _restaurantId = '0324d5db-92af-4991-befb-a2522c3eabdb';
  static const _coffeeShopId = '6fda4f15-5df3-438e-8162-fd3e12d40738';
  static const _retailStoreId = '7d03ba41-dacf-41b6-823f-0dd9f05743d3';
  static const _bakeryId = 'f3d00c4c-5152-4b43-abb4-f19affed4a72';
  static const _groceryStoreId = 'ae12bf5c-1ab2-4abe-a385-8a9cef4f5902';
  static const _foodTruckId = 'b298cd4e-253b-42bd-9d2e-4da443d5f7e9';
  static const _pharmacyId = 'eb0367a4-8c1c-488b-bce5-ffbad27b6cd9';
  static const _salonId = '6f98dd23-33e7-4892-954a-e857aeffdb52';

  static List<BusinessTemplate> get all => [
        // 1. Restaurant
        BusinessTemplate(
          id: _restaurantId,
          name: 'restaurant',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': true},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
            {'name': 'Waiter', 'permissions': _basicStaffPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 2. Coffee Shop
        BusinessTemplate(
          id: _coffeeShopId,
          name: 'coffee shop',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': true},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
            {'name': 'Barista', 'permissions': _basicStaffPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 3. Retail Store
        BusinessTemplate(
          id: _retailStoreId,
          name: 'retail store',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': false},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
            {'name': 'Stock Clerk', 'permissions': _stockClerkPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 4. Bakery
        BusinessTemplate(
          id: _bakeryId,
          name: 'bakery',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': true},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 5. Grocery Store
        BusinessTemplate(
          id: _groceryStoreId,
          name: 'grocery store',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': false},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
            {'name': 'Stock Clerk', 'permissions': _stockClerkPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 6. Food Truck
        BusinessTemplate(
          id: _foodTruckId,
          name: 'food truck',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': true},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 7. Pharmacy
        BusinessTemplate(
          id: _pharmacyId,
          name: 'pharmacy',
          defaultModules: {'POS': true, 'Variants': true, 'ComboMenu': false},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
            {'name': 'Pharmacist', 'permissions': _pharmacistPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),

        // 8. Salon / Barbershop
        BusinessTemplate(
          id: _salonId,
          name: 'salon',
          defaultModules: {'POS': true, 'Variants': false, 'ComboMenu': false},
          defaultRoles: [
            {'name': 'Super Admin', 'permissions': _allPermissions},
            {'name': 'Cashier', 'permissions': _cashierPermissions},
          ],
          defaultPermissions: _allPermissions,
          defaultTaxRate: 0.0,
        ),
      ];
}
