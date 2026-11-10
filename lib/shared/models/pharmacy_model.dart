import 'approval_status.dart';

class PharmacyModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String? licenseNo;
  final String? registrationNumber;
  final String? drugSaleLicense;
  final String? ownerName;
  final String? pharmacistName;
  final String? pharmacistRegistration;
  final String? cnic;
  final String? email;
  final String? province;
  final DateTime? licenseIssueDate;
  final DateTime? licenseExpiryDate;
  final String? licenseDocUrl;
  final String? logoUrl;
  final String currency;
  final String? receiptHeader;
  final String? receiptFooter;
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? plan;
  final DateTime? planExpiresAt;
  final String? requestedPlan;
  final DateTime? requestedPlanAt;
  final int? requestedPlanDays;
  final DateTime? createdAt;
  final String? ownerId;
  final String? ownerEmail;

  const PharmacyModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.licenseNo,
    this.registrationNumber,
    this.drugSaleLicense,
    this.ownerName,
    this.pharmacistName,
    this.pharmacistRegistration,
    this.cnic,
    this.email,
    this.province,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    this.licenseDocUrl,
    this.logoUrl,
    this.currency = 'Rs',
    this.receiptHeader,
    this.receiptFooter,
    required this.approvalStatus,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    this.plan,
    this.planExpiresAt,
    this.requestedPlan,
    this.requestedPlanAt,
    this.requestedPlanDays,
    this.createdAt,
    this.ownerId,
    this.ownerEmail,
  });

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String && val.trim().isNotEmpty) return DateTime.tryParse(val);
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {}
    return null;
  }

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      licenseNo: json['license_no'] as String? ?? json['drug_sale_license'] as String?,
      registrationNumber: json['registration_number'] as String?,
      drugSaleLicense: json['drug_sale_license'] as String? ?? json['license_no'] as String?,
      ownerName: json['owner_name'] as String?,
      pharmacistName: json['pharmacist_name'] as String?,
      pharmacistRegistration: json['pharmacist_registration'] as String?,
      cnic: json['cnic'] as String?,
      email: json['email'] as String? ?? json['owner_email'] as String?,
      province: json['province'] as String?,
      licenseIssueDate: _parseDate(json['license_issue_date']),
      licenseExpiryDate: _parseDate(json['license_expiry_date']),
      licenseDocUrl: json['license_doc_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      currency: json['currency'] as String? ?? 'Rs',
      receiptHeader: json['receipt_header'] as String?,
      receiptFooter: json['receipt_footer'] as String?,
      approvalStatus:
          ApprovalStatus.fromString(json['approval_status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: _parseDate(json['approved_at']),
      plan: json['plan'] as String?,
      planExpiresAt: _parseDate(json['plan_expires_at']),
      requestedPlan: json['requested_plan'] as String?,
      requestedPlanAt: _parseDate(json['requested_plan_at']),
      requestedPlanDays: (json['requested_plan_days'] is num)
          ? (json['requested_plan_days'] as num).toInt()
          : null,
      createdAt: _parseDate(json['created_at']),
      ownerId: json['owner_id'] as String?,
      ownerEmail: json['owner_email'] as String? ?? json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'license_no': licenseNo ?? drugSaleLicense,
      'registration_number': registrationNumber,
      'drug_sale_license': drugSaleLicense ?? licenseNo,
      'owner_name': ownerName,
      'pharmacist_name': pharmacistName,
      'pharmacist_registration': pharmacistRegistration,
      'cnic': cnic,
      'email': email ?? ownerEmail,
      'province': province,
      if (licenseIssueDate != null)
        'license_issue_date': licenseIssueDate!.toIso8601String(),
      if (licenseExpiryDate != null)
        'license_expiry_date': licenseExpiryDate!.toIso8601String(),
      'license_doc_url': licenseDocUrl,
      'logo_url': logoUrl,
      'currency': currency,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'approval_status': approvalStatus.value,
      'rejection_reason': rejectionReason,
      'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      'plan': plan,
      if (planExpiresAt != null)
        'plan_expires_at': planExpiresAt!.toIso8601String(),
      if (requestedPlan != null) 'requested_plan': requestedPlan,
      if (requestedPlanAt != null)
        'requested_plan_at': requestedPlanAt!.toIso8601String(),
      if (requestedPlanDays != null)
        'requested_plan_days': requestedPlanDays,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (ownerId != null) 'owner_id': ownerId,
      if (ownerEmail != null) 'owner_email': ownerEmail,
    };
  }

  bool get isPlanUpgradePending =>
      requestedPlan != null &&
      requestedPlan!.isNotEmpty &&
      requestedPlan != plan;

  bool get isSubscriptionExpired {
    if (planExpiresAt == null) return false;
    return DateTime.now().isAfter(planExpiresAt!);
  }

  bool get isEffectivelyApproved =>
      approvalStatus.isApproved && !isSubscriptionExpired;

  /// Plan tier helpers
  String get activePlan => plan ?? 'Standard';
  bool get isStandardPlan => activePlan.toLowerCase() == 'standard';
  bool get isProfessionalPlan => activePlan.toLowerCase().contains('pro');
  bool get isEnterprisePlan => activePlan.toLowerCase().contains('enter');

  /// Maximum staff members allowed:
  /// Standard: 2 staff (e.g. 1 cashier + 1 storekeeper, or 2 total staff)
  /// Professional & Enterprise: Unlimited (null)
  int? get maxStaff => isStandardPlan ? 2 : null;

  bool canAddMoreStaff(int currentStaffCount) {
    if (maxStaff == null) return true;
    return currentStaffCount < maxStaff!;
  }

  /// Feature gates
  bool get canUseCustomReceiptBranding => !isStandardPlan;
  bool get canExportExcelReports => isEnterprisePlan;
  bool get canAccessAdvancedReports => !isStandardPlan;
  bool get canAccessBatchExpiryAlerts => !isStandardPlan;

  /// Generates a clean domain for staff emails, e.g. "Khan Pharmacy" -> "khanpharmacy.com"
  String get domain {
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return clean.isNotEmpty ? '$clean.com' : 'pharmacy.com';
  }

  PharmacyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? licenseNo,
    String? registrationNumber,
    String? drugSaleLicense,
    String? ownerName,
    String? pharmacistName,
    String? pharmacistRegistration,
    String? cnic,
    String? email,
    String? province,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? licenseDocUrl,
    String? logoUrl,
    String? currency,
    String? receiptHeader,
    String? receiptFooter,
    ApprovalStatus? approvalStatus,
    String? rejectionReason,
    String? approvedBy,
    DateTime? approvedAt,
    String? plan,
    DateTime? planExpiresAt,
    String? requestedPlan,
    DateTime? requestedPlanAt,
    int? requestedPlanDays,
    DateTime? createdAt,
    String? ownerId,
    String? ownerEmail,
  }) {
    return PharmacyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      licenseNo: licenseNo ?? this.licenseNo,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      drugSaleLicense: drugSaleLicense ?? this.drugSaleLicense,
      ownerName: ownerName ?? this.ownerName,
      pharmacistName: pharmacistName ?? this.pharmacistName,
      pharmacistRegistration: pharmacistRegistration ?? this.pharmacistRegistration,
      cnic: cnic ?? this.cnic,
      email: email ?? this.email,
      province: province ?? this.province,
      licenseIssueDate: licenseIssueDate ?? this.licenseIssueDate,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      licenseDocUrl: licenseDocUrl ?? this.licenseDocUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      plan: plan ?? this.plan,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      requestedPlan: requestedPlan ?? this.requestedPlan,
      requestedPlanAt: requestedPlanAt ?? this.requestedPlanAt,
      requestedPlanDays: requestedPlanDays ?? this.requestedPlanDays,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }
}

