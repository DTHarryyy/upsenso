-- =============================================================================
-- Add procurement, ingredients, and recipes to the modules table.
-- These module codes are used by the Flutter app's module gate but were never
-- seeded into the Supabase `modules` table, causing set_module_enabled to
-- throw "Unknown module code" when toggled from the Module Management page.
-- =============================================================================

INSERT INTO modules (code, name, description, icon, sort_order, is_system)
VALUES
  ('procurement', 'Procurement',  'Purchase orders, goods receiving and supplier management', 'local_shipping', 13, true),
  ('ingredients', 'Ingredients',  'Ingredient stock items consumed by recipe-based products',  'blender',        14, true),
  ('recipes',     'Recipes',      'Bill-of-materials configuration on recipe-based products',  'menu_book',      15, true)
ON CONFLICT (code) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order,
  is_system   = EXCLUDED.is_system;
