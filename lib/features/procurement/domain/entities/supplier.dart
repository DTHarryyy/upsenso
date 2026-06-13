import 'package:pos/core/database/app_database.dart';

/// Immutable domain entity for a supplier.
/// Constructed from [SupplierRow] by the repository — UI and cubits never
/// touch Drift-generated types directly.
class Supplier {
  final String id;
  final String businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.taxId,
    this.notes,
    required this.isActive,
    required this.createdAt,
  });

  factory Supplier.fromRow(SupplierRow row) => Supplier(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    contactName: row.contactName,
    phone: row.phone,
    email: row.email,
    address: row.address,
    taxId: row.taxId,
    notes: row.notes,
    isActive: row.isActive,
    createdAt: row.createdAt,
  );

  Supplier copyWith({
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
    bool? isActive,
  }) => Supplier(
    id: id,
    businessId: businessId,
    name: name ?? this.name,
    contactName: contactName ?? this.contactName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    taxId: taxId ?? this.taxId,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
