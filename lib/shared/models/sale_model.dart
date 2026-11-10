class SaleItemModel {
  final String? id;
  final String? medicineId;
  final String medicineName;
  final String? batchNo;
  final int quantity;
  final double unitPrice;
  final double? costPrice;
  final double total;

  const SaleItemModel({
    this.id,
    this.medicineId,
    required this.medicineName,
    this.batchNo,
    required this.quantity,
    required this.unitPrice,
    this.costPrice,
    required this.total,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] as int? ?? 1;
    final price = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
    return SaleItemModel(
      id: json['id'] as String?,
      medicineId: json['medicine_id'] as String?,
      medicineName: json['medicine_name'] as String? ??
          (json['medicines'] != null ? json['medicines']['name'] as String? : 'Medicine') ??
          'Medicine',
      batchNo: json['batch_no'] as String? ??
          (json['batches'] != null ? json['batches']['batch_no'] as String? : null),
      quantity: qty,
      unitPrice: price,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble() ?? (qty * price),
    );
  }
}

class SaleModel {
  final String id;
  final String pharmacyId;
  final int invoiceNo;
  final String? cashierId;
  final String? cashierName;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final String customerName;
  final DateTime createdAt;
  final List<SaleItemModel> items;

  const SaleModel({
    required this.id,
    required this.pharmacyId,
    required this.invoiceNo,
    this.cashierId,
    this.cashierName,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.customerName,
    required this.createdAt,
    this.items = const [],
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    if (rawItems == null && json['sale_items'] != null) {
      rawItems = json['sale_items'];
    }

    final itemsList = rawItems is List
        ? rawItems.map((i) => SaleItemModel.fromJson(i as Map<String, dynamic>)).toList()
        : <SaleItemModel>[];

    return SaleModel(
      id: (json['sale_id'] ?? json['id']) as String,
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      invoiceNo: json['invoice_no'] as int? ?? 0,
      cashierId: json['cashier_id'] as String?,
      cashierName: json['profiles'] != null ? json['profiles']['full_name'] as String? : null,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      customerName: json['customer_name'] as String? ?? 'Walk-in Customer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: itemsList,
    );
  }
}

