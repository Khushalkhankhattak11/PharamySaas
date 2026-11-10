enum BatchExpiryStatus {
  expired,
  critical30,
  warning90,
  fresh,
}

class BatchModel {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final String? purchaseId;
  final String batchNo;
  final String qrCode;
  final DateTime expiryDate;
  final int quantity;
  final double purchasePrice;
  final DateTime? createdAt;

  const BatchModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    this.purchaseId,
    required this.batchNo,
    required this.qrCode,
    required this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
    this.createdAt,
  });

  static DateTime _parseDate(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    try {
      final dynamic d = val;
      if (d.toDate != null) return d.toDate() as DateTime;
    } catch (_) {}
    return DateTime.now().add(const Duration(days: 365));
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    final rawQty = json['quantity'] ?? 0;
    final int qty = (rawQty is num) ? rawQty.toInt() : (int.tryParse(rawQty.toString()) ?? 0);

    return BatchModel(
      id: json['id']?.toString() ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? '',
      medicineId: json['medicine_id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString(),
      batchNo: json['batch_no']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      expiryDate: _parseDate(json['expiry_date']),
      quantity: qty,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? _parseDate(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'medicine_id': medicineId,
      'purchase_id': purchaseId,
      'batch_no': batchNo,
      'qr_code': qrCode,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'quantity': quantity,
      'purchase_price': purchasePrice,
    };
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  BatchExpiryStatus get expiryStatus {
    final days = daysUntilExpiry;
    if (days < 0) return BatchExpiryStatus.expired;
    if (days <= 30) return BatchExpiryStatus.critical30;
    if (days <= 90) return BatchExpiryStatus.warning90;
    return BatchExpiryStatus.fresh;
  }
}

