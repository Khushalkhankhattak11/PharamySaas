import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/purchase_model.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PurchasesRepository(firestore, auth);
});

class PurchasesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PurchasesRepository(this._firestore, this._auth);

  /// Real-time stream of purchases/stock-in records.
  Stream<List<PurchaseModel>> watchPurchases(String pharmacyId) {
    return _firestore
        .collection(FirestoreCollections.purchases)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return PurchaseModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<PurchaseModel>> getPurchases(String pharmacyId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.purchases)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return PurchaseModel.fromJson(data);
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<PurchaseModel> recordStockInPurchase({
    required String pharmacyId,
    String? supplierId,
    String? invoiceNo,
    required List<PurchaseLineItem> items,
  }) async {
    final double grandTotal = items.fold(0.0, (acc, i) => acc + i.lineTotal);
    final purchaseRef =
        _firestore.collection(FirestoreCollections.purchases).doc();
    final purchaseId = purchaseRef.id;
    final now = DateTime.now().toIso8601String();
    final currentUserId = _auth.currentUser?.uid;

    // Fetch supplier name if supplierId provided
    String? supplierName;
    if (supplierId != null && supplierId.isNotEmpty) {
      final supDoc = await _firestore
          .collection(FirestoreCollections.suppliers)
          .doc(supplierId)
          .get();
      supplierName = supDoc.data()?['name'] as String?;
    }

    final purchaseData = {
      'id': purchaseId,
      'pharmacy_id': pharmacyId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'invoice_no': invoiceNo?.trim(),
      'total': grandTotal,
      'status': 'received',
      'created_by': currentUserId,
      'created_at': now,
      'items': items.map((i) => i.toJson()).toList(),
    };

    final batch = _firestore.batch();
    batch.set(purchaseRef, purchaseData);

    // 2. Insert Batches in batches collection and update medicines stock
    for (final item in items) {
      final batchRef =
          _firestore.collection(FirestoreCollections.batches).doc();
      final batchId = batchRef.id;
      final qrCode = 'BAT-${batchId.substring(0, 8).toUpperCase()}';

      batch.set(batchRef, {
        'id': batchId,
        'pharmacy_id': pharmacyId,
        'medicine_id': item.medicineId,
        'purchase_id': purchaseId,
        'batch_no': item.batchNo.trim(),
        'qr_code': qrCode,
        'expiry_date': item.expiryDate.toIso8601String().split('T')[0],
        'quantity': item.quantity,
        'purchase_price': item.purchasePrice,
        'created_at': now,
      });

      // Increment medicine available stock on both root medicines and pharmacy stocks subcollection
      final medRef = _firestore
          .collection(FirestoreCollections.medicines)
          .doc(item.medicineId);
      batch.update(medRef, {
        'available_stock': FieldValue.increment(item.quantity),
        'updated_at': now,
      });

      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

      final stockRef = pharmacyDoc.collection(FirestoreCollections.stocks).doc(item.medicineId);
      batch.set(stockRef, {
        'available_stock': FieldValue.increment(item.quantity),
        'updated_at': now,
      }, SetOptions(merge: true));

      final prodRef = pharmacyDoc.collection(FirestoreCollections.products).doc(item.medicineId);
      batch.set(prodRef, {
        'available_stock': FieldValue.increment(item.quantity),
        'updated_at': now,
      }, SetOptions(merge: true));

      final medSubRef = pharmacyDoc.collection(FirestoreCollections.medicines).doc(item.medicineId);
      batch.set(medSubRef, {
        'available_stock': FieldValue.increment(item.quantity),
        'updated_at': now,
      }, SetOptions(merge: true));

      final rootProdRef = _firestore.collection(FirestoreCollections.products).doc(item.medicineId);
      batch.set(rootProdRef, {
        'available_stock': FieldValue.increment(item.quantity),
        'updated_at': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return PurchaseModel.fromJson(purchaseData);
  }
}
