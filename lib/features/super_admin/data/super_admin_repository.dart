import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/pharmacy_model.dart';

class PlatformStatsModel {
  final int totalPharmacies;
  final int pendingPharmacies;
  final int approvedPharmacies;
  final int rejectedPharmacies;
  final int suspendedPharmacies;
  final int activeUsers;
  final double totalPlatformVolume;
  double get totalSalesVolume => totalPlatformVolume;

  const PlatformStatsModel({
    required this.totalPharmacies,
    required this.pendingPharmacies,
    required this.approvedPharmacies,
    required this.rejectedPharmacies,
    required this.suspendedPharmacies,
    required this.activeUsers,
    required this.totalPlatformVolume,
  });

  factory PlatformStatsModel.fromJson(Map<String, dynamic> json) {
    return PlatformStatsModel(
      totalPharmacies: json['total_pharmacies'] as int? ?? 0,
      pendingPharmacies: json['pending_pharmacies'] as int? ?? 0,
      approvedPharmacies: json['approved_pharmacies'] as int? ?? 0,
      rejectedPharmacies: json['rejected_pharmacies'] as int? ?? 0,
      suspendedPharmacies: json['suspended_pharmacies'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      totalPlatformVolume: (json['total_platform_volume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ApprovalLogModel {
  final String id;
  final String pharmacyId;
  final String action;
  final String? reason;
  final String? actedBy;
  final DateTime createdAt;

  const ApprovalLogModel({
    required this.id,
    required this.pharmacyId,
    required this.action,
    this.reason,
    this.actedBy,
    required this.createdAt,
  });

  factory ApprovalLogModel.fromJson(Map<String, dynamic> json) {
    return ApprovalLogModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      action: json['action'] as String,
      reason: json['reason'] as String?,
      actedBy: json['acted_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return SuperAdminRepository(firestore, auth);
});

class SuperAdminRepository {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  SuperAdminRepository(this._firestore, this._auth);

  Future<PlatformStatsModel> getPlatformStats() async {
    final pharmSnap = await _firestore.collection(FirestoreCollections.pharmacies).get();
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    int suspended = 0;

    for (final doc in pharmSnap.docs) {
      final status = doc.data()['approval_status'] as String? ?? 'pending';
      if (status == 'pending') pending++;
      if (status == 'approved') approved++;
      if (status == 'rejected') rejected++;
      if (status == 'suspended') suspended++;
    }

    final usersSnap = await _firestore
        .collection(FirestoreCollections.profiles)
        .where('is_active', isEqualTo: true)
        .get();

    final salesSnap = await _firestore.collection(FirestoreCollections.sales).get();
    double totalVol = 0.0;
    for (final doc in salesSnap.docs) {
      totalVol += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
    }

    return PlatformStatsModel(
      totalPharmacies: pharmSnap.docs.length,
      pendingPharmacies: pending,
      approvedPharmacies: approved,
      rejectedPharmacies: rejected,
      suspendedPharmacies: suspended,
      activeUsers: usersSnap.docs.length,
      totalPlatformVolume: totalVol,
    );
  }

  /// Real-time stream of pending pharmacy registrations for SuperAdmin.
  Stream<List<PharmacyModel>> watchPendingPharmacies() {
    return _firestore
        .collection(FirestoreCollections.pharmacies)
        .where('approval_status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return PharmacyModel.fromJson(data);
      }).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Real-time stream of pharmacies that have requested a subscription plan upgrade.
  Stream<List<PharmacyModel>> watchPlanUpgradeRequests() {
    return _firestore
        .collection(FirestoreCollections.pharmacies)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return PharmacyModel.fromJson(data);
      }).where((p) => p.isPlanUpgradePending).toList();

      list.sort((a, b) => (b.requestedPlanAt ?? DateTime.now())
          .compareTo(a.requestedPlanAt ?? DateTime.now()));
      return list;
    });
  }

  /// Real-time stream of all pharmacies with search & filtering.
  Stream<List<PharmacyModel>> watchAllPharmacies({String? status, String? search}) {
    Query<Map<String, dynamic>> query = _firestore.collection(FirestoreCollections.pharmacies);
    if (status != null && status != 'all') {
      query = query.where('approval_status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return PharmacyModel.fromJson(data);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        list = list.where((p) =>
            p.name.toLowerCase().contains(s) ||
            (p.city?.toLowerCase().contains(s) ?? false) ||
            (p.licenseNo?.toLowerCase().contains(s) ?? false)).toList();
      }

      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<List<PharmacyModel>> getPendingPharmacies() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.pharmacies)
        .where('approval_status', isEqualTo: 'pending')
        .get();

    final list = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return PharmacyModel.fromJson(data);
    }).toList();

    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<List<PharmacyModel>> getAllPharmacies({String? status, String? search}) async {
    Query<Map<String, dynamic>> query = _firestore.collection(FirestoreCollections.pharmacies);
    if (status != null && status != 'all') {
      query = query.where('approval_status', isEqualTo: status);
    }

    final snapshot = await query.get();
    var list = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return PharmacyModel.fromJson(data);
    }).toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(s) ||
          (p.city?.toLowerCase().contains(s) ?? false) ||
          (p.licenseNo?.toLowerCase().contains(s) ?? false)).toList();
    }

    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<PharmacyModel?> getPharmacyById(String pharmacyId) async {
    final doc = await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return PharmacyModel.fromJson(data);
  }

  Future<void> approvePharmacy(String pharmacyId) async {
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    final batch = _firestore.batch();
    final pharmRef = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);
    batch.update(pharmRef, {
      'approval_status': 'approved',
      'approved_at': now,
      'approved_by': currentUserId,
      'rejection_reason': null,
      'updated_at': now,
    });

    final logRef = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    batch.set(logRef, {
      'id': logRef.id,
      'pharmacy_id': pharmacyId,
      'action': 'approved',
      'acted_by': currentUserId,
      'created_at': now,
    });

    final notifRef = _firestore.collection(FirestoreCollections.notifications).doc();
    batch.set(notifRef, {
      'id': notifRef.id,
      'pharmacy_id': pharmacyId,
      'title': 'Pharmacy Approved!',
      'body': 'Your pharmacy has been approved by the platform Super Admin. You now have full access.',
      'type': 'system',
      'is_read': false,
      'created_at': now,
    });

    await batch.commit();
  }

  Future<void> rejectPharmacy(String pharmacyId, String reason) async {
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    final batch = _firestore.batch();
    final pharmRef = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);
    batch.update(pharmRef, {
      'approval_status': 'rejected',
      'rejection_reason': reason.trim(),
      'updated_at': now,
    });

    final logRef = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    batch.set(logRef, {
      'id': logRef.id,
      'pharmacy_id': pharmacyId,
      'action': 'rejected',
      'reason': reason.trim(),
      'acted_by': currentUserId,
      'created_at': now,
    });

    final notifRef = _firestore.collection(FirestoreCollections.notifications).doc();
    batch.set(notifRef, {
      'id': notifRef.id,
      'pharmacy_id': pharmacyId,
      'title': 'Application Status Updated',
      'body': 'Your application was rejected: ${reason.trim()}',
      'type': 'alert',
      'is_read': false,
      'created_at': now,
    });

    await batch.commit();
  }

  Future<void> suspendPharmacy(String pharmacyId, String reason) async {
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    final batch = _firestore.batch();
    final pharmRef = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);
    batch.update(pharmRef, {
      'approval_status': 'suspended',
      'rejection_reason': reason.trim(),
      'updated_at': now,
    });

    final logRef = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    batch.set(logRef, {
      'id': logRef.id,
      'pharmacy_id': pharmacyId,
      'action': 'suspended',
      'reason': reason.trim(),
      'acted_by': currentUserId,
      'created_at': now,
    });

    await batch.commit();
  }

  Future<void> reactivatePharmacy(String pharmacyId) async {
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    final batch = _firestore.batch();
    final pharmRef = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);
    batch.update(pharmRef, {
      'approval_status': 'approved',
      'rejection_reason': null,
      'updated_at': now,
    });

    final logRef = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    batch.set(logRef, {
      'id': logRef.id,
      'pharmacy_id': pharmacyId,
      'action': 'reactivated',
      'acted_by': currentUserId,
      'created_at': now,
    });

    await batch.commit();
  }

  Future<List<PharmacyModel>> getPendingApprovals() => getPendingPharmacies();

  Future<List<PharmacyModel>> getPharmacies({String? statusFilter, String? search}) =>
      getAllPharmacies(status: statusFilter, search: search);

  Future<void> reviewPharmacy({
    required String pharmacyId,
    required String action,
    String? reason,
    String? plan,
    int extendDays = 365,
  }) async {
    final lower = action.toLowerCase();
    if (lower == 'approve') {
      await approvePharmacy(pharmacyId);
      if (plan != null) {
        await updateSubscriptionPlan(
          pharmacyId: pharmacyId,
          plan: plan,
          expiresAt: DateTime.now().add(Duration(days: extendDays)),
        );
      }
    } else if (lower == 'reject') {
      await rejectPharmacy(pharmacyId, reason ?? 'Rejected by platform admin');
    } else if (lower == 'suspend') {
      await suspendPharmacy(pharmacyId, reason ?? 'Suspended by platform admin');
    } else if (lower == 'reactivate') {
      await reactivatePharmacy(pharmacyId);
    }
  }

  Future<void> updateSubscriptionPlan({
    required String pharmacyId,
    required String plan,
    required DateTime expiresAt,
  }) async {
    await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).update({
      'plan': plan,
      'plan_expires_at': expiresAt.toIso8601String(),
      'requested_plan': FieldValue.delete(),
      'requested_plan_at': FieldValue.delete(),
      'requested_plan_days': FieldValue.delete(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> acceptPlanUpgrade({
    required String pharmacyId,
    required String plan,
    int planDays = 365,
  }) async {
    final now = DateTime.now();
    final expiryIso = now.add(Duration(days: planDays)).toIso8601String();
    await _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .update({
      'plan': plan,
      'plan_expires_at': expiryIso,
      'requested_plan': FieldValue.delete(),
      'requested_plan_at': FieldValue.delete(),
      'requested_plan_days': FieldValue.delete(),
      'updated_at': now.toIso8601String(),
    });
  }

  Future<void> rejectPlanUpgrade({
    required String pharmacyId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .update({
      'requested_plan': FieldValue.delete(),
      'requested_plan_at': FieldValue.delete(),
      'requested_plan_days': FieldValue.delete(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> addPharmacy({
    required String name,
    required String ownerEmail,
    required String ownerPassword,
    String? ownerFullName,
    String? ownerName,
    String? registrationNumber,
    String? drugSaleLicense,
    String? pharmacistName,
    String? pharmacistRegistration,
    String? cnic,
    String? province,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? address,
    String? city,
    String? phone,
    String? licenseNo,
    String currency = 'Rs',
    String plan = 'Standard',
    int planDays = 365,
    String approvalStatus = 'approved',
  }) async {
    final cleanEmail = ownerEmail.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Pharmacy owner email is required.');
    }
    if (ownerPassword.length < 6) {
      throw Exception('Pharmacy owner password must be at least 6 characters.');
    }

    final docRef = _firestore.collection(FirestoreCollections.pharmacies).doc();
    final pharmacyId = docRef.id;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final expiryIso = now.add(Duration(days: planDays)).toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    // 1. Create owner authentication user via Firebase Auth REST API directly
    // This avoids using a secondary FirebaseApp in Flutter Web, which corrupts/resets
    // the active Super Admin session and causes permission-denied errors on subsequent Firestore queries.
    final apiKey = Firebase.app().options.apiKey;
    String? ownerUid;

    final signUpUri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    final response = await http.post(
      signUpUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': cleanEmail,
        'password': ownerPassword,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      ownerUid = data['localId'] as String?;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMsg = errorData?['error']?['message'] as String? ?? '';
      if (errorMsg.contains('EMAIL_EXISTS')) {
        throw Exception(
            'The email "$cleanEmail" is already registered with another account.');
      } else if (errorMsg.contains('WEAK_PASSWORD')) {
        throw Exception(
            'The password is too weak. Please use at least 6 characters.');
      } else if (errorMsg.contains('INVALID_EMAIL')) {
        throw Exception('The email address "$cleanEmail" is invalid.');
      }
      throw Exception('Failed to create pharmacy owner credentials: $errorMsg');
    }

    if (ownerUid == null) {
      throw Exception('Failed to generate user ID for pharmacy owner.');
    }

    final dsl = (drugSaleLicense ?? licenseNo)?.trim().toUpperCase();
    final finalOwnerName = ((ownerName ?? ownerFullName) ?? '').trim();

    // 2. Create the Pharmacy Document
    await docRef.set({
      'id': pharmacyId,
      'name': name.trim(),
      'owner_id': ownerUid,
      'owner_email': cleanEmail,
      'owner_name': finalOwnerName.isNotEmpty ? finalOwnerName : null,
      'registration_number': registrationNumber?.trim().toUpperCase(),
      'drug_sale_license': dsl,
      'license_no': dsl,
      'pharmacist_name': pharmacistName?.trim(),
      'pharmacist_registration': pharmacistRegistration?.trim().toUpperCase(),
      'cnic': cnic?.trim(),
      'email': cleanEmail,
      'province': province?.trim(),
      'address': address?.trim(),
      'city': city?.trim(),
      'phone': phone?.trim(),
      if (licenseIssueDate != null)
        'license_issue_date': licenseIssueDate.toIso8601String(),
      if (licenseExpiryDate != null)
        'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'currency': currency,
      'approval_status': approvalStatus,
      'plan': plan,
      'plan_expires_at': expiryIso,
      'approved_at': approvalStatus == 'approved' ? nowIso : null,
      'approved_by': approvalStatus == 'approved' ? currentUserId : null,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    // 3. Create the Owner Profile Document with role: 'admin'
    await _firestore.collection(FirestoreCollections.profiles).doc(ownerUid).set({
      'id': ownerUid,
      'pharmacy_id': pharmacyId,
      'role': 'admin',
      'full_name': finalOwnerName.isNotEmpty ? finalOwnerName : '${name.trim()} Owner',
      'phone': phone?.trim(),
      'email': cleanEmail,
      'is_active': true,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    // 4. Log the approval action
    final logRef = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    await logRef.set({
      'id': logRef.id,
      'pharmacy_id': pharmacyId,
      'action': 'created_by_super_admin',
      'acted_by': currentUserId,
      'reason': 'Created by Super Admin with owner account ($cleanEmail)',
      'created_at': nowIso,
    });

    return pharmacyId;
  }

  Future<void> updatePharmacy({
    required String pharmacyId,
    required String name,
    String? ownerName,
    String? registrationNumber,
    String? drugSaleLicense,
    String? pharmacistName,
    String? pharmacistRegistration,
    String? cnic,
    String? email,
    String? province,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? address,
    String? city,
    String? phone,
    String? licenseNo,
    required String currency,
    String? plan,
    DateTime? planExpiresAt,
    String? approvalStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    final dsl = (drugSaleLicense ?? licenseNo)?.trim().toUpperCase();

    final data = <String, dynamic>{
      'name': name.trim(),
      'currency': currency,
      'updated_at': now,
    };

    if (ownerName != null) data['owner_name'] = ownerName.trim();
    if (registrationNumber != null) {
      data['registration_number'] = registrationNumber.trim().toUpperCase();
    }
    if (dsl != null) {
      data['drug_sale_license'] = dsl;
      data['license_no'] = dsl;
    }
    if (pharmacistName != null) data['pharmacist_name'] = pharmacistName.trim();
    if (pharmacistRegistration != null) {
      data['pharmacist_registration'] = pharmacistRegistration.trim().toUpperCase();
    }
    if (cnic != null) data['cnic'] = cnic.trim();
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim().toLowerCase();
      data['owner_email'] = email.trim().toLowerCase();
    }
    if (province != null) data['province'] = province.trim();
    if (address != null) data['address'] = address.trim();
    if (city != null) data['city'] = city.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (licenseIssueDate != null) {
      data['license_issue_date'] = licenseIssueDate.toIso8601String();
    }
    if (licenseExpiryDate != null) {
      data['license_expiry_date'] = licenseExpiryDate.toIso8601String();
    }

    if (plan != null) data['plan'] = plan;
    if (planExpiresAt != null) data['plan_expires_at'] = planExpiresAt.toIso8601String();
    if (approvalStatus != null) {
      data['approval_status'] = approvalStatus;
      if (approvalStatus == 'approved') {
        data['approved_at'] = now;
        data['approved_by'] = currentUserId;
      }
    }

    await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).update(data);
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).delete();
  }

  Future<List<ApprovalLogModel>> getApprovalLogs(String pharmacyId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.approvalLogs)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final list = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return ApprovalLogModel.fromJson(data);
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
