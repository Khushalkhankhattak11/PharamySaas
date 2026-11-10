import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';
import 'firestore_collections.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreService(firestore);
});

/// Core Firestore multi-tenant service.
/// Enforces partition by `pharmacy_id` on all tenant collections.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  FirebaseFirestore get raw => _firestore;

  /// Returns collection reference
  CollectionReference<Map<String, dynamic>> collection(String name) {
    return _firestore.collection(name);
  }

  /// Tenant-filtered query
  Query<Map<String, dynamic>> tenantQuery(String collectionName, String pharmacyId) {
    return _firestore
        .collection(collectionName)
        .where('pharmacy_id', isEqualTo: pharmacyId);
  }

  /// Cashier collection query (isolated multi-tenant subcollection under pharmacy)
  Query<Map<String, dynamic>> cashiersQuery(String pharmacyId) {
    return _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.cashiers);
  }

  /// Storekeeper collection query (isolated multi-tenant subcollection under pharmacy)
  Query<Map<String, dynamic>> storekeepersQuery(String pharmacyId) {
    return _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.storekeepers);
  }

  /// Converts Timestamp or String to DateTime
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Converts DateTime to Firestore serializable ISO string
  static String? toIsoString(DateTime? dt) {
    return dt?.toIso8601String();
  }
}

