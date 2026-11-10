// ignore_for_file: unused_local_variable, equal_keys_in_map

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/pharmacy_model.dart';
import '../../../shared/models/profile_model.dart';

class AuthUser {
  final String id;
  final String? email;

  const AuthUser({required this.id, this.email});
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepository(auth, firestore);
});

class AuthRepository {
  final fb.FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  AuthRepository(this._auth, this._firestore);

  AuthUser? get currentUser {
    if (_auth == null) return null;
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return AuthUser(id: user.uid, email: user.email);
    } catch (_) {
      return null;
    }
  }

  Stream<AuthUser?> get authStateChanges {
    if (_auth == null) return Stream.value(null);
    try {
      return _auth.authStateChanges().map((user) {
        if (user == null) return null;
        return AuthUser(id: user.uid, email: user.email);
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth == null) throw Exception('Firebase Auth not initialized');
    final cleanEmail = email.trim();
    final normalized = cleanEmail.toLowerCase();

    // Auto-bootstrap Platform Owner / Super Admin account
    if (normalized == 'superadmin@admin.com' && password == 'mysuperadmin89') {
      try {
        await _auth.signInWithEmailAndPassword(
          email: 'SuperAdmin@admin.com',
          password: password,
        );
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'channel-error') {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: 'SuperAdmin@admin.com',
            password: password,
          );
          final user = cred.user;
          if (user != null && _firestore != null) {
            await _firestore
                .collection(FirestoreCollections.profiles)
                .doc(user.uid)
                .set({
              'id': user.uid,
              'pharmacy_id': null,
              'role': 'super_admin',
              'full_name': 'Super Admin',
              'email': 'SuperAdmin@admin.com',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
          return;
        }
        rethrow;
      }

      final user = _auth.currentUser;
      if (user != null && _firestore != null) {
        final profileDoc = await _firestore
            .collection(FirestoreCollections.profiles)
            .doc(user.uid)
            .get();
        if (!profileDoc.exists) {
          await _firestore
              .collection(FirestoreCollections.profiles)
              .doc(user.uid)
              .set({
            'id': user.uid,
            'pharmacy_id': null,
            'role': 'super_admin',
            'full_name': 'Super Admin',
            'email': 'SuperAdmin@admin.com',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
      return;
    }

    await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
  }

  Future<void> signUpAdmin({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase not initialized');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await _firestore
          .collection(FirestoreCollections.profiles)
          .doc(user.uid)
          .set({
        'id': user.uid,
        'pharmacy_id': null,
        'role': 'admin',
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) return;
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<ProfileModel?> getProfile(String userId) async {
    if (_firestore == null) return null;
    try {
      // 1. Check if user is Super Admin in the dedicated 'admin' collection
      try {
        final adminDoc = await _firestore.collection(FirestoreCollections.admin).doc(userId).get();
        if (adminDoc.exists && adminDoc.data() != null) {
          final data = Map<String, dynamic>.from(adminDoc.data()!);
          data['id'] = adminDoc.id;
          data['role'] = 'super_admin';
          return ProfileModel.fromJson(data);
        }
      } catch (_) {}

      // 2. Fetch from standard profiles collection
      final doc = await _firestore.collection(FirestoreCollections.profiles).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        final pharmacyId = data['pharmacy_id'] as String?;
        if (pharmacyId != null && data['role'] == 'admin') {
          // Backfill owner_id on pharmacy document so security rules and future lookups work
          try {
            await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).set({
              'owner_id': userId,
              if (data['email'] != null) 'owner_email': data['email'],
            }, SetOptions(merge: true));
          } catch (_) {}
        }
        // If this was an old super_admin document in profiles, migrate it to 'admin' and purge from profiles!
        if (data['role'] == 'super_admin') {
          try {
            await _firestore.collection(FirestoreCollections.admin).doc(userId).set(data, SetOptions(merge: true));
            await _firestore.collection(FirestoreCollections.profiles).doc(userId).delete();
          } catch (_) {}
        }
        return ProfileModel.fromJson(data);
      }

      // 3. Fallback: Search in pharmacies subcollections (staff, cashiers, storekeepers, or owner)
      try {
        final pharmSnap = await _firestore.collection(FirestoreCollections.pharmacies).get();
        for (final pDoc in pharmSnap.docs) {
          final pData = pDoc.data();
          final userEmail = _auth?.currentUser?.email?.trim().toLowerCase();
          final isOwner = pData['owner_id'] == userId ||
              (userEmail != null && pData['owner_email'] != null && (pData['owner_email'] as String).toLowerCase() == userEmail);

          if (isOwner) {
            final profileData = {
              'id': userId,
              'pharmacy_id': pDoc.id,
              'role': 'admin',
              'full_name': pData['name'] ?? 'Admin',
              'email': pData['owner_email'] ?? userEmail,
              'phone': pData['phone'],
              'is_active': true,
              'created_at': pData['created_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            try {
              await pDoc.reference.set({'owner_id': userId}, SetOptions(merge: true));
              await _firestore.collection(FirestoreCollections.profiles).doc(userId).set(profileData, SetOptions(merge: true));
            } catch (_) {}
            return ProfileModel.fromJson(profileData);
          }

          // Check staff / cashiers / storekeepers subcollections
          final staffDoc = await pDoc.reference.collection('staff').doc(userId).get();
          if (staffDoc.exists && staffDoc.data() != null) {
            final sData = staffDoc.data()!;
            final role = sData['role'] ?? 'cashier';
            final profileData = {
              'id': userId,
              'pharmacy_id': pDoc.id,
              'role': role,
              'full_name': sData['name'] ?? sData['full_name'] ?? 'Staff',
              'email': sData['email'] ?? userEmail,
              'phone': sData['phone'],
              'is_active': sData['is_active'] ?? true,
              'created_at': sData['created_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            try {
              await _firestore.collection(FirestoreCollections.profiles).doc(userId).set(profileData, SetOptions(merge: true));
            } catch (_) {}
            return ProfileModel.fromJson(profileData);
          }

          final cashierDoc = await pDoc.reference.collection('cashiers').doc(userId).get();
          if (cashierDoc.exists && cashierDoc.data() != null) {
            final cData = cashierDoc.data()!;
            final profileData = {
              'id': userId,
              'pharmacy_id': pDoc.id,
              'role': 'cashier',
              'full_name': cData['name'] ?? 'Cashier',
              'email': cData['email'] ?? userEmail,
              'phone': cData['phone'],
              'is_active': cData['is_active'] ?? true,
              'created_at': cData['created_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            try {
              await _firestore.collection(FirestoreCollections.profiles).doc(userId).set(profileData, SetOptions(merge: true));
            } catch (_) {}
            return ProfileModel.fromJson(profileData);
          }

          final storeDoc = await pDoc.reference.collection('storekeepers').doc(userId).get();
          if (storeDoc.exists && storeDoc.data() != null) {
            final stData = storeDoc.data()!;
            final profileData = {
              'id': userId,
              'pharmacy_id': pDoc.id,
              'role': 'storekeeper',
              'full_name': stData['name'] ?? 'Storekeeper',
              'email': stData['email'] ?? userEmail,
              'phone': stData['phone'],
              'is_active': stData['is_active'] ?? true,
              'created_at': stData['created_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            try {
              await _firestore.collection(FirestoreCollections.profiles).doc(userId).set(profileData, SetOptions(merge: true));
            } catch (_) {}
            return ProfileModel.fromJson(profileData);
          }
        }

        // If only 1 pharmacy exists in total and user has no profile yet, link to it
        if (pharmSnap.docs.length == 1) {
          final pDoc = pharmSnap.docs.first;
          final pData = pDoc.data();
          final userEmail = _auth?.currentUser?.email?.toLowerCase();
          final role = (userEmail != null && userEmail.contains('cashier'))
              ? 'cashier'
              : (userEmail != null && userEmail.contains('store'))
                  ? 'storekeeper'
                  : 'admin';
          final profileData = {
            'id': userId,
            'pharmacy_id': pDoc.id,
            'role': role,
            'full_name': _auth?.currentUser?.displayName ?? pData['name'] ?? 'Staff',
            'email': _auth?.currentUser?.email,
            'phone': pData['phone'],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            await _firestore.collection(FirestoreCollections.profiles).doc(userId).set(profileData, SetOptions(merge: true));
          } catch (_) {}
          return ProfileModel.fromJson(profileData);
        }
      } catch (e) {
        debugPrint('[AuthRepository] Fallback pharmacy lookup note: $e');
      }

      return null;
    } catch (e) {
      debugPrint('[AuthRepository] Failed to get profile for $userId: $e');
      return null;
    }
  }

  Future<PharmacyModel?> getPharmacy(String pharmacyId) async {
    if (_firestore == null) return null;
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return PharmacyModel.fromJson(data);
    } catch (e) {
      debugPrint('[AuthRepository] Failed to get pharmacy for $pharmacyId: $e');
      return null;
    }
  }
}
