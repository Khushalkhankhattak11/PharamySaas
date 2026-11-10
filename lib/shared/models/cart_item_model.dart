class CartItemModel {
  final String medicineId;
  final String name;
  final String unit;
  final double unitPrice;
  final int availableStock;
  final int quantity;

  const CartItemModel({
    required this.medicineId,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.availableStock,
    this.quantity = 1,
  });

  double get lineTotal => quantity * unitPrice;
  double get total => lineTotal;

  CartItemModel copyWith({
    String? medicineId,
    String? name,
    String? unit,
    double? unitPrice,
    int? availableStock,
    int? quantity,
  }) {
    return CartItemModel(
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      availableStock: availableStock ?? this.availableStock,
      quantity: quantity ?? this.quantity,
    );
  }
}

