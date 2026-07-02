import 'package:pos/core/database/app_database.dart';

/// Immutable domain entity for a customer (CRM module).
/// Constructed from [CustomerRow] by the repository — UI and cubits never touch
/// Drift-generated types directly.
class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.isActive,
    required this.createdAt,
  });

  factory Customer.fromRow(CustomerRow row) => Customer(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    phone: row.phone,
    email: row.email,
    address: row.address,
    notes: row.notes,
    isActive: row.isActive,
    createdAt: row.createdAt,
  );

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) => Customer(
    id: id,
    businessId: businessId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
