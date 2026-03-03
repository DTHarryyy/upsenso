/// Branch entity representing a business branch/location
class Branch {
  final String id;
  final String businessId;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  const Branch({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  Branch copyWith({
    String? id,
    String? businessId,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
