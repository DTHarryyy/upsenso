/// Hardcoded fallback categories per business template name.
/// Template names match those in the Supabase `business_templates` table.
class DefaultCategories {
  DefaultCategories._();

  static const Map<String, List<String>> _byTemplate = {
    'restaurant': ['Food', 'Beverages', 'Desserts'],
    'retail store': ['Clothing', 'Electronics', 'Accessories'],
    'coffee shop': ['Coffee & Tea', 'Pastries', 'Cold Drinks'],
  };

  /// Returns the default category names for the given template.
  /// Matches case-insensitively; uses contains-matching so
  /// "Quick Restaurant" still hits 'restaurant'.
  /// Falls back to a generic list if no match is found.
  static List<String> forTemplate(String templateName) {
    final lower = templateName.toLowerCase().trim();
    if (_byTemplate.containsKey(lower)) return _byTemplate[lower]!;
    for (final entry in _byTemplate.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return ['General', 'Products', 'Services'];
  }
}
