class PurchaseModel {
  final String id;
  final String pharmacyId;
  final String? supplierId;
  final String? supplierName;
  final String? invoiceNo;
  final double total;
  final String? createdBy;
  final DateTime createdAt;

  const PurchaseModel({
    required this.id,
    required this.pharmacyId,
    this.supplierId,
    this.supplierName,
    this.invoiceNo,
    required this.total,
    this.createdBy,
    required this.createdAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      supplierId: json['supplier_id'] as String?,
      supplierName: json['suppliers'] != null ? json['suppliers']['name'] as String? : null,
      invoiceNo: json['invoice_no'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PurchaseLineItem {
  final String medicineId;
  final String medicineName;
  final String batchNo;
  final DateTime expiryDate;
  final int quantity;
  final double purchasePrice;

  const PurchaseLineItem({
    required this.medicineId,
    required this.medicineName,
    required this.batchNo,
    required this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
  });

  double get lineTotal => quantity * purchasePrice;

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'batch_no': batchNo,
      'expiry_date': expiryDate.toIso8601String(),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'line_total': lineTotal,
    };
  }
}

