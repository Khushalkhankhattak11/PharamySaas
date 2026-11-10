class MedicineModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String? brandName;
  final String? registrationNumber;
  final String? genericName;
  final String? category;
  final String? manufacturer;
  final String? barcode;
  final String qrCode;
  final String unit;
  final double salePrice;
  final double discountPercent;
  final int minStockLevel;
  final bool isActive;
  final int availableStock;
  final DateTime? nearestExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;

  const MedicineModel({
    required this.id,
    required this.pharmacyId,
    required this.name,
    this.brandName,
    this.registrationNumber,
    this.genericName,
    this.category,
    this.manufacturer,
    this.barcode,
    required this.qrCode,
    this.unit = 'Strip',
    required this.salePrice,
    this.discountPercent = 0.0,
    this.minStockLevel = 10,
    required this.isActive,
    this.availableStock = 0,
    this.nearestExpiry,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    try {
      final dynamic d = val;
      if (d.toDate != null) {
        return d.toDate() as DateTime;
      }
    } catch (_) {}
    return null;
  }

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    final rawStock = json['available_stock'] ?? json['total_stock'] ?? json['stock'] ?? 0;
    final int stock = (rawStock is num) ? rawStock.toInt() : (int.tryParse(rawStock.toString()) ?? 0);

    final rawMinStock = json['min_stock_level'] ?? 10;
    final int minStock = (rawMinStock is num) ? rawMinStock.toInt() : (int.tryParse(rawMinStock.toString()) ?? 10);

    final rawPrice = json['sale_price'] ?? json['price'] ?? 0.0;
    final double price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);

    final rawDiscount = json['discount_percent'] ?? 0.0;
    final double discount = (rawDiscount is num) ? rawDiscount.toDouble() : (double.tryParse(rawDiscount.toString()) ?? 0.0);

    final rawActive = json['is_active'];
    final bool active = rawActive == null ? true : (rawActive is bool ? rawActive : rawActive.toString().toLowerCase() == 'true');

    return MedicineModel(
      id: json['id']?.toString() ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brandName: json['brand_name']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      genericName: json['generic_name']?.toString(),
      category: json['category']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      barcode: json['barcode']?.toString(),
      qrCode: json['qr_code']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Strip',
      salePrice: price,
      discountPercent: discount,
      minStockLevel: minStock,
      isActive: active,
      availableStock: stock,
      nearestExpiry: _parseDate(json['nearest_expiry']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'name': name,
      if (brandName != null && brandName!.isNotEmpty) 'brand_name': brandName,
      if (registrationNumber != null && registrationNumber!.isNotEmpty) 'registration_number': registrationNumber,
      'generic_name': genericName,
      'category': category,
      'manufacturer': manufacturer,
      'barcode': barcode,
      'qr_code': qrCode,
      'unit': unit,
      'sale_price': salePrice,
      'discount_percent': discountPercent,
      'min_stock_level': minStockLevel,
      'is_active': isActive,
      'available_stock': availableStock,
      'image_url': imageUrl,
      if (nearestExpiry != null) 'nearest_expiry': nearestExpiry!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  MedicineModel copyWith({
    String? id,
    String? pharmacyId,
    String? name,
    String? brandName,
    String? registrationNumber,
    String? genericName,
    String? category,
    String? manufacturer,
    String? barcode,
    String? qrCode,
    String? unit,
    double? salePrice,
    double? discountPercent,
    int? minStockLevel,
    bool? isActive,
    int? availableStock,
    DateTime? nearestExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      discountPercent: discountPercent ?? this.discountPercent,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isActive: isActive ?? this.isActive,
      availableStock: availableStock ?? this.availableStock,
      nearestExpiry: nearestExpiry ?? this.nearestExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  double get effectivePrice => discountPercent > 0
      ? (salePrice * (1.0 - (discountPercent / 100.0))).clamp(0.0, double.infinity)
      : salePrice;

  bool get isLowStock => availableStock <= minStockLevel;
}
