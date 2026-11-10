import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/models/user_role.dart';
import '../../auth/data/auth_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return StaffRepository(firestore, authRepo);
});

class StaffRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;

  StaffRepository(this._firestore, this._authRepo);

  /// Real-time stream of pharmacy staff. Emits instantly on local and remote changes.
  Stream<List<ProfileModel>> watchStaff(String pharmacyId) {
    final controller = StreamController<List<ProfileModel>>.broadcast();

    final subQuery = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection('staff');

    final rootQuery = _firestore
        .collection(FirestoreCollections.profiles)
        .where('pharmacy_id', isEqualTo: pharmacyId);

    final Map<String, ProfileModel> subMap = {};
    final Map<String, ProfileModel> rootMap = {};

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, ProfileModel> combined = {};
      combined.addAll(rootMap);
      combined.addAll(subMap);
      final list = combined.values
          .where((p) => p.role != UserRole.admin && p.role != UserRole.superAdmin)
          .toList();
      list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      controller.add(list);
    }

    StreamSubscription? sub1;
    StreamSubscription? sub2;

    controller.onListen = () {
      cleanupLegacyRootStaffCollections(pharmacyId);

      sub1 = subQuery.snapshots().listen(
        (snap) {
          subMap.clear();
          for (final d in snap.docs) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            if (data['full_name'] == null && data['name'] != null) {
              data['full_name'] = data['name'];
            }
            subMap[d.id] = ProfileModel.fromJson(data);
          }
          emitMerged();
        },
        onError: (_) {},
      );

      sub2 = rootQuery.snapshots().listen(
        (snap) {
          rootMap.clear();
          for (final d in snap.docs) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            rootMap[d.id] = ProfileModel.fromJson(data);
          }
          emitMerged();
        },
        onError: (_) {},
      );
    };

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };

    return controller.stream;
  }

  /// Get staff list for a pharmacy (reads from pharmacy's staff subcollection
  /// and profiles collection to ensure both new and existing staff are returned).
  Future<List<ProfileModel>> getStaff(String pharmacyId) async {
    final Map<String, ProfileModel> staffMap = {};

    // 1. Fetch from pharmacy subcollection: pharmacies/{pharmacyId}/staff
    try {
      final subSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .get();

      for (final d in subSnap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        if (data['full_name'] == null && data['name'] != null) {
          data['full_name'] = data['name'];
        }
        staffMap[d.id] = ProfileModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[StaffRepository] subcollection staff read error: $e');
    }

    // 2. Fetch from root profiles collection to ensure any pre-existing staff is included
    try {
      final profileSnap = await _firestore
          .collection(FirestoreCollections.profiles)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .get();

      for (final d in profileSnap.docs) {
        if (!staffMap.containsKey(d.id)) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          final p = ProfileModel.fromJson(data);
          if (p.role != UserRole.admin && p.role != UserRole.superAdmin) {
            staffMap[d.id] = p;
          }
        }
      }
    } catch (e) {
      debugPrint('[StaffRepository] profiles staff read error: $e');
    }

    final list = staffMap.values.toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  /// Cashier collection list (strictly inside pharmacy subcollection: pharmacies/{pharmacyId}/cashiers)
  Future<List<Map<String, dynamic>>> getCashiers(String pharmacyId) async {
    try {
      final subSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('cashiers')
          .get();
      if (subSnap.docs.isNotEmpty) {
        return subSnap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          return data;
        }).toList();
      }
    } catch (_) {}

    try {
      final staffSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .where('role', isEqualTo: 'cashier')
          .get();
      return staffSnap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return data;
      }).toList();
    } catch (_) {}

    return [];
  }

  /// Storekeeper collection list (strictly inside pharmacy subcollection: pharmacies/{pharmacyId}/storekeepers)
  Future<List<Map<String, dynamic>>> getStorekeepers(String pharmacyId) async {
    try {
      final subSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('storekeepers')
          .get();
      if (subSnap.docs.isNotEmpty) {
        return subSnap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          return data;
        }).toList();
      }
    } catch (_) {}

    try {
      final staffSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .where('role', isEqualTo: 'storekeeper')
          .get();
      return staffSnap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return data;
      }).toList();
    } catch (_) {}

    return [];
  }

  /// One-time cleanup: Deletes any old leftover documents from the root cashiers
  /// and storekeepers collections so they no longer appear as top-level collections in Firebase Console.
  Future<void> cleanupLegacyRootStaffCollections(String pharmacyId) async {
    try {
      final oldCashiers = await _firestore
          .collection(FirestoreCollections.cashiers)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .get();
      for (final doc in oldCashiers.docs) {
        await doc.reference.delete().catchError((_) {});
      }

      final oldStorekeepers = await _firestore
          .collection(FirestoreCollections.storekeepers)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .get();
      for (final doc in oldStorekeepers.docs) {
        await doc.reference.delete().catchError((_) {});
      }
    } catch (e) {
      debugPrint('[StaffRepository] cleanupLegacyRootStaffCollections error: $e');
    }
  }

  /// Creates a real Firebase Auth user for the staff member and saves documents
  /// into the pharmacy's subcollections (pharmacies/{pharmacyId}/staff, cashiers, storekeepers)
  /// as well as the root profiles collection for authentication lookups.
  Future<void> createStaff({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required UserRole role,
    String? shiftStart,
    String? shiftEnd,
    String? shiftLabel,
  }) async {
    final currentUser = _authRepo.currentUser;
    if (currentUser == null) {
      throw Exception('Admin must be authenticated to create staff');
    }

    final adminProfile = await _authRepo.getProfile(currentUser.id);
    final pharmacyId = adminProfile?.pharmacyId;
    if (pharmacyId == null) {
      throw Exception('No pharmacy associated with current admin');
    }

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Staff login email is required');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Check plan limits
    final pharmacy = await _authRepo.getPharmacy(pharmacyId);
    if (pharmacy != null) {
      final existingStaff = await getStaff(pharmacyId);
      final cashiersCount = existingStaff.where((s) => s.role == UserRole.cashier).length;
      final storekeepersCount = existingStaff.where((s) => s.role == UserRole.storekeeper).length;

      if (pharmacy.isStandardPlan) {
        if (existingStaff.isNotEmpty) {
          throw Exception(
              'Staff limit reached (1/1 member) on the Standard Plan. Standard includes 1 Cashier OR 1 Storekeeper. Please upgrade to Professional to add up to 6 staff (3 Cashiers + 3 Storekeepers).');
        }
      } else if (pharmacy.isProfessionalPlan) {
        if (existingStaff.length >= 6) {
          throw Exception(
              'Staff limit reached (6/6 members) on the Professional Plan. Please upgrade to Enterprise for unlimited staff accounts.');
        }
        if (role == UserRole.cashier && cashiersCount >= 3) {
          throw Exception(
              'Cashier quota reached (3/3 Cashiers) on the Professional Plan. You can still add Storekeepers (up to 3), or upgrade to Enterprise for unlimited cashiers.');
        }
        if (role == UserRole.storekeeper && storekeepersCount >= 3) {
          throw Exception(
              'Storekeeper quota reached (3/3 Storekeepers) on the Professional Plan. You can still add Cashiers (up to 3), or upgrade to Enterprise for unlimited storekeepers.');
        }
      }
    }

    // 1. Create real Auth user via Firebase Auth REST API directly.
    // This avoids using a secondary FirebaseApp in Flutter Web, which corrupts/resets
    // the active Admin session and causes permission-denied errors on subsequent Firestore queries.
    final apiKey = Firebase.app().options.apiKey;
    String? staffUid;

    final signUpUri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    final response = await http.post(
      signUpUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': cleanEmail,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      staffUid = data['localId'] as String?;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMsg = errorData?['error']?['message'] as String? ?? '';
      if (errorMsg.contains('EMAIL_EXISTS')) {
        // Recover UID by signing in via REST API without altering client FirebaseAuth session
        final signInUri = Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
        final signInRes = await http.post(
          signInUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'password': password,
            'returnSecureToken': true,
          }),
        );
        if (signInRes.statusCode == 200) {
          final signInData = jsonDecode(signInRes.body) as Map<String, dynamic>;
          staffUid = signInData['localId'] as String?;
        } else {
          throw Exception(
              'The email "$cleanEmail" is already registered with another account. Please use a different username/email or the original password.');
        }
      } else if (errorMsg.contains('WEAK_PASSWORD')) {
        throw Exception(
            'Password is too weak. Please use at least 6 characters.');
      } else if (errorMsg.contains('INVALID_EMAIL')) {
        throw Exception('The email address "$cleanEmail" is invalid.');
      } else {
        throw Exception('Failed to create staff credentials: $errorMsg');
      }
    }

    if (staffUid == null) {
      throw Exception('Failed to generate user ID for staff member.');
    }

    final now = DateTime.now().toIso8601String();
    final cleanPhone =
        (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
    final batch = _firestore.batch();

    final cleanShiftStart = (shiftStart != null && shiftStart.trim().isNotEmpty) ? shiftStart.trim() : null;
    final cleanShiftEnd = (shiftEnd != null && shiftEnd.trim().isNotEmpty) ? shiftEnd.trim() : null;
    final cleanShiftLabel = (shiftLabel != null && shiftLabel.trim().isNotEmpty) ? shiftLabel.trim() : null;

    // 2. User profile in root profiles collection (for auth & router role checking)
    final profileRef =
        _firestore.collection(FirestoreCollections.profiles).doc(staffUid);
    batch.set(profileRef, {
      'id': staffUid,
      'pharmacy_id': pharmacyId,
      'role': role.value,
      'full_name': fullName.trim(),
      if (cleanPhone != null) 'phone': cleanPhone,
      'email': cleanEmail,
      'is_active': true,
      if (cleanShiftStart != null) 'shift_start': cleanShiftStart,
      if (cleanShiftEnd != null) 'shift_end': cleanShiftEnd,
      if (cleanShiftLabel != null) 'shift_label': cleanShiftLabel,
      'created_at': now,
      'updated_at': now,
    });

    // 3. Pharmacy staff subcollection: pharmacies/{pharmacyId}/staff/{staffUid}
    final pharmacyStaffRef = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection('staff')
        .doc(staffUid);
    batch.set(pharmacyStaffRef, {
      'id': staffUid,
      'pharmacy_id': pharmacyId,
      'user_id': staffUid,
      'role': role.value,
      'name': fullName.trim(),
      'full_name': fullName.trim(),
      'email': cleanEmail,
      if (cleanPhone != null) 'phone': cleanPhone,
      'is_active': true,
      if (cleanShiftStart != null) 'shift_start': cleanShiftStart,
      if (cleanShiftEnd != null) 'shift_end': cleanShiftEnd,
      if (cleanShiftLabel != null) 'shift_label': cleanShiftLabel,
      'created_at': now,
      'updated_at': now,
    });

    // 4. Dedicated role subcollection in pharmacy
    if (role == UserRole.cashier) {
      final pharmacyCashierRef = _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('cashiers')
          .doc(staffUid);
      final cashierData = {
        'id': staffUid,
        'pharmacy_id': pharmacyId,
        'user_id': staffUid,
        'name': fullName.trim(),
        'email': cleanEmail,
        if (cleanPhone != null) 'phone': cleanPhone,
        'role': 'cashier',
        'is_active': true,
        'total_sales_count': 0,
        'total_sales_amount': 0.0,
        if (cleanShiftStart != null) 'shift_start': cleanShiftStart,
        if (cleanShiftEnd != null) 'shift_end': cleanShiftEnd,
        if (cleanShiftLabel != null) 'shift_label': cleanShiftLabel,
        'created_at': now,
        'updated_at': now,
      };
      batch.set(pharmacyCashierRef, cashierData);
    } else if (role == UserRole.storekeeper) {
      final pharmacyStorekeeperRef = _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('storekeepers')
          .doc(staffUid);
      final storekeeperData = {
        'id': staffUid,
        'pharmacy_id': pharmacyId,
        'user_id': staffUid,
        'name': fullName.trim(),
        'email': cleanEmail,
        if (cleanPhone != null) 'phone': cleanPhone,
        'role': 'storekeeper',
        'is_active': true,
        if (cleanShiftStart != null) 'shift_start': cleanShiftStart,
        if (cleanShiftEnd != null) 'shift_end': cleanShiftEnd,
        if (cleanShiftLabel != null) 'shift_label': cleanShiftLabel,
        'created_at': now,
        'updated_at': now,
      };
      batch.set(pharmacyStorekeeperRef, storekeeperData);
    }

    await batch.commit();
  }

  Future<void> updateStaff({
    required String staffId,
    required String fullName,
    String? phone,
    required UserRole role,
    String? shiftStart,
    String? shiftEnd,
    String? shiftLabel,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();

    final profileDoc = await _firestore
        .collection(FirestoreCollections.profiles)
        .doc(staffId)
        .get();
    final pharmacyId = profileDoc.data()?['pharmacy_id'] as String?;
    final oldRoleStr = profileDoc.data()?['role'] as String?;

    if (pharmacyId != null && oldRoleStr != role.value) {
      final pharmacy = await _authRepo.getPharmacy(pharmacyId);
      if (pharmacy != null && pharmacy.isProfessionalPlan) {
        final existingStaff = await getStaff(pharmacyId);
        final otherStaff = existingStaff.where((s) => s.id != staffId).toList();
        final cashiersCount = otherStaff.where((s) => s.role == UserRole.cashier).length;
        final storekeepersCount = otherStaff.where((s) => s.role == UserRole.storekeeper).length;

        if (role == UserRole.cashier && cashiersCount >= 3) {
          throw Exception('Cannot change role: Professional Plan allows a maximum of 3 Cashiers (3/3 reached). Upgrade to Enterprise for unlimited cashiers.');
        }
        if (role == UserRole.storekeeper && storekeepersCount >= 3) {
          throw Exception('Cannot change role: Professional Plan allows a maximum of 3 Storekeepers (3/3 reached). Upgrade to Enterprise for unlimited storekeepers.');
        }
      }
    }

    final cleanShiftStart = (shiftStart != null && shiftStart.trim().isNotEmpty) ? shiftStart.trim() : null;
    final cleanShiftEnd = (shiftEnd != null && shiftEnd.trim().isNotEmpty) ? shiftEnd.trim() : null;
    final cleanShiftLabel = (shiftLabel != null && shiftLabel.trim().isNotEmpty) ? shiftLabel.trim() : null;

    // 1. Update root profile
    final profileRef =
        _firestore.collection(FirestoreCollections.profiles).doc(staffId);
    final profileUpdate = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'role': role.value,
      'updated_at': now,
    };
    if (cleanShiftStart != null) profileUpdate['shift_start'] = cleanShiftStart;
    if (cleanShiftEnd != null) profileUpdate['shift_end'] = cleanShiftEnd;
    if (cleanShiftLabel != null) profileUpdate['shift_label'] = cleanShiftLabel;
    batch.update(profileRef, profileUpdate);

    // 2. Update pharmacy subcollections
    if (pharmacyId != null) {
      final subStaffRef = _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .doc(staffId);
      final subStaffData = <String, dynamic>{
        'name': fullName.trim(),
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'role': role.value,
        'updated_at': now,
      };
      if (cleanShiftStart != null) subStaffData['shift_start'] = cleanShiftStart;
      if (cleanShiftEnd != null) subStaffData['shift_end'] = cleanShiftEnd;
      if (cleanShiftLabel != null) subStaffData['shift_label'] = cleanShiftLabel;
      batch.set(subStaffRef, subStaffData, SetOptions(merge: true));

      if (role == UserRole.cashier) {
        final subCashierRef = _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('cashiers')
            .doc(staffId);
        final cashierSubData = <String, dynamic>{
          'name': fullName.trim(),
          'phone': phone?.trim(),
          'role': 'cashier',
          'updated_at': now,
        };
        if (cleanShiftStart != null) cashierSubData['shift_start'] = cleanShiftStart;
        if (cleanShiftEnd != null) cashierSubData['shift_end'] = cleanShiftEnd;
        if (cleanShiftLabel != null) cashierSubData['shift_label'] = cleanShiftLabel;
        batch.set(subCashierRef, cashierSubData, SetOptions(merge: true));
      } else if (role == UserRole.storekeeper) {
        final subStorekeeperRef = _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('storekeepers')
            .doc(staffId);
        final storekeeperSubData = <String, dynamic>{
          'name': fullName.trim(),
          'phone': phone?.trim(),
          'role': 'storekeeper',
          'updated_at': now,
        };
        if (cleanShiftStart != null) storekeeperSubData['shift_start'] = cleanShiftStart;
        if (cleanShiftEnd != null) storekeeperSubData['shift_end'] = cleanShiftEnd;
        if (cleanShiftLabel != null) storekeeperSubData['shift_label'] = cleanShiftLabel;
        batch.set(subStorekeeperRef, storekeeperSubData, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<void> toggleStaffStatus({
    required String staffId,
    required bool isActive,
  }) async {
    final profileDoc = await _firestore
        .collection(FirestoreCollections.profiles)
        .doc(staffId)
        .get();
    final roleStr = profileDoc.data()?['role'] as String?;
    final role = UserRole.fromString(roleStr);
    await toggleStaffActive(staffId: staffId, isActive: isActive, role: role);
  }

  Future<void> toggleStaffActive({
    required String staffId,
    required bool isActive,
    required UserRole role,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();

    final profileDoc = await _firestore
        .collection(FirestoreCollections.profiles)
        .doc(staffId)
        .get();
    final pharmacyId = profileDoc.data()?['pharmacy_id'] as String?;

    // Update root profile
    final profileRef =
        _firestore.collection(FirestoreCollections.profiles).doc(staffId);
    batch.update(profileRef, {'is_active': isActive, 'updated_at': now});

    // Update pharmacy subcollections
    if (pharmacyId != null) {
      final subStaffRef = _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .doc(staffId);
      batch.set(subStaffRef, {'is_active': isActive, 'updated_at': now},
          SetOptions(merge: true));

      if (role == UserRole.cashier) {
        final subCashierRef = _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('cashiers')
            .doc(staffId);
        batch.set(subCashierRef, {'is_active': isActive, 'updated_at': now},
            SetOptions(merge: true));
      } else if (role == UserRole.storekeeper) {
        final subStorekeeperRef = _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('storekeepers')
            .doc(staffId);
        batch.set(subStorekeeperRef, {'is_active': isActive, 'updated_at': now},
            SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<void> deleteStaff({
    required String staffId,
    required UserRole role,
  }) async {
    final profileDoc = await _firestore
        .collection(FirestoreCollections.profiles)
        .doc(staffId)
        .get();
    final pharmacyId = profileDoc.data()?['pharmacy_id'] as String?;

    final batch = _firestore.batch();
    batch.delete(
        _firestore.collection(FirestoreCollections.profiles).doc(staffId));

    if (pharmacyId != null) {
      batch.delete(_firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection('staff')
          .doc(staffId));
      if (role == UserRole.cashier) {
        batch.delete(_firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('cashiers')
            .doc(staffId));
      } else if (role == UserRole.storekeeper) {
        batch.delete(_firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection('storekeepers')
            .doc(staffId));
      }
    }

    if (role == UserRole.cashier) {
      batch.delete(
          _firestore.collection(FirestoreCollections.cashiers).doc(staffId));
    } else if (role == UserRole.storekeeper) {
      batch.delete(_firestore
          .collection(FirestoreCollections.storekeepers)
          .doc(staffId));
    }

    await batch.commit();
  }

  Future<void> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    final doc = await _firestore
        .collection(FirestoreCollections.profiles)
        .doc(staffId)
        .get();
    final email = doc.data()?['email'] as String?;
    if (email != null && email.isNotEmpty) {
      await _authRepo.sendPasswordResetEmail(email);
    }
  }
}
