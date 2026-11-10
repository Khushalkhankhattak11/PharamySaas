import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';

final pharmacyRegistrationRepositoryProvider =
    Provider<PharmacyRegistrationRepository>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PharmacyRegistrationRepository(storage, firestore, auth);
});

class PharmacyRegistrationRepository {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PharmacyRegistrationRepository(this._storage, this._firestore, this._auth);

  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final ref = _storage.ref('$bucket/$path');
      final metadata = SettableMetadata(contentType: contentType);
      await ref.putData(bytes, metadata);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  Future<String> registerPharmacy({
    required String name,
    required String registrationNumber,
    required String drugSaleLicense,
    required String ownerName,
    required String pharmacistName,
    required String pharmacistRegistration,
    required String cnic,
    required String phone,
    required String email,
    required String province,
    required String city,
    required String address,
    required DateTime licenseIssueDate,
    required DateTime licenseExpiryDate,
    String? licenseDocUrl,
    String? logoUrl,
    String currency = 'Rs',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit pharmacy registration.');
    }

    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc();
    final pharmacyId = pharmacyDoc.id;
    final now = DateTime.now().toIso8601String();

    final batch = _firestore.batch();

    final finalEmail = email.trim().isNotEmpty
        ? email.trim().toLowerCase()
        : (user.email?.trim().toLowerCase() ?? '');

    // 1. Create Pharmacy in pharmacies collection
    batch.set(pharmacyDoc, {
      'id': pharmacyId,
      'owner_id': user.uid,
      'owner_email': finalEmail,
      'owner_name': ownerName.trim(),
      'name': name.trim(),
      'registration_number': registrationNumber.trim().toUpperCase(),
      'drug_sale_license': drugSaleLicense.trim().toUpperCase(),
      'license_no': drugSaleLicense.trim().toUpperCase(),
      'pharmacist_name': pharmacistName.trim(),
      'pharmacist_registration': pharmacistRegistration.trim().toUpperCase(),
      'cnic': cnic.trim(),
      'phone': phone.trim(),
      'email': finalEmail,
      'province': province.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'license_issue_date': licenseIssueDate.toIso8601String(),
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'license_doc_url': licenseDocUrl,
      'logo_url': logoUrl,
      'currency': currency,
      'approval_status': 'pending',
      'created_at': now,
      'updated_at': now,
    });

    // 2. Link Pharmacy to user profile
    final profileRef = _firestore.collection(FirestoreCollections.profiles).doc(user.uid);
    batch.set(profileRef, {
      'id': user.uid,
      'pharmacy_id': pharmacyId,
      'role': 'admin',
      'full_name': ownerName.trim().isNotEmpty ? ownerName.trim() : (user.displayName ?? 'Admin'),
      'email': finalEmail,
      'phone': phone.trim(),
      'is_active': true,
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));

    // 3. Add to approval_logs collection
    final logDoc = _firestore.collection(FirestoreCollections.approvalLogs).doc();
    batch.set(logDoc, {
      'id': logDoc.id,
      'pharmacy_id': pharmacyId,
      'action': 'registered',
      'reason': 'Initial registration submitted by pharmacy owner',
      'acted_by': user.uid,
      'created_at': now,
    });

    // 4. Create initial notification
    final notifDoc = _firestore.collection(FirestoreCollections.notifications).doc();
    batch.set(notifDoc, {
      'id': notifDoc.id,
      'pharmacy_id': pharmacyId,
      'user_id': user.uid,
      'title': 'Registration Submitted',
      'body': 'Your pharmacy registration for "$name" has been received and is pending Super Admin review.',
      'type': 'system',
      'is_read': false,
      'created_at': now,
    });

    await batch.commit();
    return pharmacyId;
  }
}
