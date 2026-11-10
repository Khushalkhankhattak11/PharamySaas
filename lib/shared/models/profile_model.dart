import 'user_role.dart';

class ProfileModel {
  final String id;
  final String? pharmacyId;
  final UserRole role;
  final String fullName;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final String? shiftStart; // e.g. "09:00"
  final String? shiftEnd;   // e.g. "17:00"
  final String? shiftLabel; // e.g. "Morning (09:00 - 17:00)"

  const ProfileModel({
    required this.id,
    this.pharmacyId,
    required this.role,
    required this.fullName,
    this.email,
    this.phone,
    required this.isActive,
    this.createdAt,
    this.shiftStart,
    this.shiftEnd,
    this.shiftLabel,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? 'User',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      shiftStart: json['shift_start'] as String?,
      shiftEnd: json['shift_end'] as String?,
      shiftLabel: json['shift_label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'role': role.value,
      'full_name': fullName,
      if (email != null) 'email': email,
      'phone': phone,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (shiftStart != null) 'shift_start': shiftStart,
      if (shiftEnd != null) 'shift_end': shiftEnd,
      if (shiftLabel != null) 'shift_label': shiftLabel,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? pharmacyId,
    UserRole? role,
    String? fullName,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    String? shiftStart,
    String? shiftEnd,
    String? shiftLabel,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      shiftLabel: shiftLabel ?? this.shiftLabel,
    );
  }
}
