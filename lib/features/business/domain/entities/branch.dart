class Branch {
  final String id;
  final String businessId;
  final String name;
  final String? location;

  const Branch({
    required this.id,
    required this.businessId,
    required this.name,
    this.location,
  });

  Branch copyWith({
    String? id,
    String? businessId,
    String? name,
    String? location,
  }) {
    return Branch(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      location: location ?? this.location,
    );
  }
}
