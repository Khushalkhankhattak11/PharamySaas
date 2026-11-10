class StockAdjustmentModel {
  final String id;
  final String pharmacyId;
  final String batchId;
  final int quantityChange;
  final String reason;
  final String? createdBy;
  final DateTime createdAt;

  const StockAdjustmentModel({
    required this.id,
    required this.pharmacyId,
    required this.batchId,
    required this.quantityChange,
    required this.reason,
    this.createdBy,
    required this.createdAt,
  });

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      batchId: json['batch_id'] as String,
      quantityChange: json['quantity_change'] as int,
      reason: json['reason'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

