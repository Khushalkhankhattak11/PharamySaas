class SupplierModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String? phone;
  final String? address;
  final DateTime? createdAt;

  const SupplierModel({
    required this.id,
    required this.pharmacyId,
    required this.name,
    this.phone,
    this.address,
    this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}

