import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return SettingsRepository(firestore, auth);
});

class SettingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettingsRepository(this._firestore, this._auth);

  Future<void> updatePharmacySettings({
    required String pharmacyId,
    required String name,
    String? address,
    String? city,
    String? phone,
    required String currency,
    String? receiptHeader,
    String? receiptFooter,
  }) async {
    await _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId).update({
      'name': name.trim(),
      'address': address?.trim(),
      'city': city?.trim(),
      'phone': phone?.trim(),
      'currency': currency,
      'receipt_header': receiptHeader?.trim(),
      'receipt_footer': receiptFooter?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> requestPlanUpgrade({
    required String pharmacyId,
    required String plan,
    int planDays = 365,
  }) async {
    await _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .update({
      'requested_plan': plan,
      'requested_plan_at': DateTime.now().toIso8601String(),
      'requested_plan_days': planDays,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> cancelPlanUpgradeRequest({
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

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    final updateData = {
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final adminDoc = await _firestore.collection(FirestoreCollections.admin).doc(userId).get();
      if (adminDoc.exists) {
        await _firestore.collection(FirestoreCollections.admin).doc(userId).update(updateData);
        return;
      }
    } catch (_) {}

    await _firestore.collection(FirestoreCollections.profiles).doc(userId).update(updateData);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User is not currently signed in.');
    }
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Current password is incorrect.');
      } else if (e.code == 'weak-password') {
        throw Exception('The new password is too weak. Please use at least 6 characters.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please sign out and sign in again before changing your password.');
      }
      throw Exception(e.message ?? 'Failed to change password.');
    }
  }

  Future<void> savePrinterType(String printerType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_printer_type', printerType);
  }

  Future<String> getPrinterType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_printer_type') ?? '80mm';
  }
}
