import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/supplier_model.dart';

final suppliersRepositoryProvider = Provider<SuppliersRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SuppliersRepository(firestore);
});

class SuppliersRepository {
  final FirebaseFirestore _firestore;

  SuppliersRepository(this._firestore);

  Future<List<SupplierModel>> getSuppliers(String pharmacyId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.suppliers)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final list = snapshot.docs.map((row) {
      final data = Map<String, dynamic>.from(row.data());
      data['id'] = row.id;
      return SupplierModel.fromJson(data);
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<SupplierModel> createSupplier({
    required String pharmacyId,
    required String name,
    String? phone,
    String? address,
  }) async {
    final docRef = _firestore.collection(FirestoreCollections.suppliers).doc();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': docRef.id,
      'pharmacy_id': pharmacyId,
      'name': name.trim(),
      'phone': phone?.trim(),
      'address': address?.trim(),
      'is_active': true,
      'created_at': now,
    };

    await docRef.set(data);
    return SupplierModel.fromJson(data);
  }

  Future<void> updateSupplier({
    required String supplierId,
    required String name,
    String? phone,
    String? address,
  }) async {
    await _firestore.collection(FirestoreCollections.suppliers).doc(supplierId).update({
      'name': name.trim(),
      'phone': phone?.trim(),
      'address': address?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _firestore.collection(FirestoreCollections.suppliers).doc(supplierId).delete();
  }
}
