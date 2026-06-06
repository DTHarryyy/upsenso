/// A pre-built POS configuration the user selects during business onboarding.
///
/// The module list, role definitions, and permission maps now live in
/// server-side normalized tables. The Flutter client only needs the
/// display fields and [code] to drive offline fallback logic.
class BusinessTemplate {
  final String id;

  /// Stable machine-readable key, e.g. 'coffee_shop'.
  /// Matches business_templates.code on the server.
  final String code;

  final String name;
  final String description;
  final int version;
  final bool isActive;
  final DateTime? createdAt;

  const BusinessTemplate({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.version = 1,
    this.isActive = true,
    this.createdAt,
  });
}
