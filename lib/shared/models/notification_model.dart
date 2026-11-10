enum AppNotificationType {
  lowStock('low_stock', 'Low Stock'),
  expiringSoon('expiring_soon', 'Expiring Soon'),
  expired('expired', 'Expired'),
  newPharmacy('new_pharmacy', 'New Pharmacy'),
  pharmacyApproved('pharmacy_approved', 'Approved'),
  pharmacyRejected('pharmacy_rejected', 'Rejected'),
  pharmacySuspended('pharmacy_suspended', 'Suspended');

  final String value;
  final String label;
  const AppNotificationType(this.value, this.label);

  static AppNotificationType fromString(String? val) {
    switch (val) {
      case 'low_stock':
        return AppNotificationType.lowStock;
      case 'expiring_soon':
        return AppNotificationType.expiringSoon;
      case 'expired':
        return AppNotificationType.expired;
      case 'new_pharmacy':
        return AppNotificationType.newPharmacy;
      case 'pharmacy_approved':
        return AppNotificationType.pharmacyApproved;
      case 'pharmacy_rejected':
        return AppNotificationType.pharmacyRejected;
      case 'pharmacy_suspended':
        return AppNotificationType.pharmacySuspended;
      default:
        return AppNotificationType.lowStock;
    }
  }
}

class NotificationModel {
  final String id;
  final String? pharmacyId;
  final String? targetRole;
  final String? targetUserId;
  final AppNotificationType type;
  final String title;
  final String message;
  final String? medicineId;
  final String? batchId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.pharmacyId,
    this.targetRole,
    this.targetUserId,
    required this.type,
    required this.title,
    required this.message,
    this.medicineId,
    this.batchId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String?,
      targetRole: json['target_role'] as String?,
      targetUserId: json['target_user_id'] as String?,
      type: AppNotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      medicineId: json['medicine_id'] as String?,
      batchId: json['batch_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

