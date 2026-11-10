import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_cache_helper.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/batch_model.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../shared/models/sale_model.dart';
import '../../auth/data/auth_repository.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return PosRepository(firestore, auth, authRepo);
});

class PosRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthRepository _authRepo;

  PosRepository(this._firestore, this._auth, this._authRepo);

  Future<SaleModel> createSale({
    required List<CartItemModel> items,
    required double discount,
    required String paymentMethod,
    required String customerName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Cashier must be authenticated to create a sale');
    }

    final profile = await _authRepo.getProfile(user.uid);
    final pharmacyId = profile?.pharmacyId;
    if (pharmacyId == null) {
      throw Exception('No pharmacy associated with current user');
    }

    final cashierName = profile?.fullName ?? 'Cashier';
    final cashierId = user.uid;

    final double subtotal = items.fold(0.0, (acc, i) => acc + i.lineTotal);
    final double grandTotal = (subtotal - discount).clamp(0.0, double.infinity);
    final int invoiceNo = DateTime.now().millisecondsSinceEpoch % 10000000;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final saleRef = _firestore.collection(FirestoreCollections.sales).doc();
    final saleId = saleRef.id;

    final List<Map<String, dynamic>> recordedItems = [];
    final firestoreBatch = _firestore.batch();

    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    // 1. FEFO Batch allocation and stock decrement for each medicine
    for (final cartItem in items) {
      // Query batches from both pharmacy subcollection and root collection
      List<BatchModel> availableBatches = [];

      try {
        final subBatchesSnap = await pharmacyDoc
            .collection(FirestoreCollections.batches)
            .where('medicine_id', isEqualTo: cartItem.medicineId)
            .getFast();
        for (final d in subBatchesSnap.docs) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          availableBatches.add(BatchModel.fromJson(data));
        }
      } catch (_) {}

      if (availableBatches.isEmpty) {
        try {
          final rootBatchesSnap = await _firestore
              .collection(FirestoreCollections.batches)
              .where('pharmacy_id', isEqualTo: pharmacyId)
              .where('medicine_id', isEqualTo: cartItem.medicineId)
              .getFast();
          for (final d in rootBatchesSnap.docs) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            availableBatches.add(BatchModel.fromJson(data));
          }
        } catch (_) {}
      }

      availableBatches = availableBatches
          .where((b) => b.quantity > 0)
          .toList();

      // Sort FEFO (earliest expiry first)
      availableBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      int remainingToDeduct = cartItem.quantity;
      String? usedBatchNo;
      double? unitCost;

      for (final b in availableBatches) {
        if (remainingToDeduct <= 0) break;
        final deduct =
            remainingToDeduct <= b.quantity ? remainingToDeduct : b.quantity;
        remainingToDeduct -= deduct;
        usedBatchNo = b.batchNo;
        unitCost = b.purchasePrice;

        final batchDecrement = {
          'pharmacy_id': pharmacyId,
          'quantity': FieldValue.increment(-deduct),
          'updated_at': nowIso,
        };

        firestoreBatch.set(
          _firestore.collection(FirestoreCollections.batches).doc(b.id),
          batchDecrement,
          SetOptions(merge: true),
        );
        firestoreBatch.set(
          pharmacyDoc.collection(FirestoreCollections.batches).doc(b.id),
          batchDecrement,
          SetOptions(merge: true),
        );
      }

      // Decrement available stock on medicine across all pharmacy subcollections and root collections
      // e.g. Panadol Extra 50 in stock - 10 sales = 40 in stock
      final stockDecrement = {
        'pharmacy_id': pharmacyId,
        'available_stock': FieldValue.increment(-cartItem.quantity),
        'updated_at': nowIso,
      };

      // 1. Pharmacy subcollections (products, medicines, stocks, Products)
      firestoreBatch.set(
        pharmacyDoc.collection(FirestoreCollections.products).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        pharmacyDoc.collection(FirestoreCollections.medicines).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        pharmacyDoc.collection(FirestoreCollections.stocks).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        pharmacyDoc.collection('Products').doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );

      // 2. Root collections (medicines, products, Products, stocks)
      firestoreBatch.set(
        _firestore.collection(FirestoreCollections.medicines).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        _firestore.collection(FirestoreCollections.products).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        _firestore.collection(FirestoreCollections.stocks).doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );
      firestoreBatch.set(
        _firestore.collection('Products').doc(cartItem.medicineId),
        stockDecrement,
        SetOptions(merge: true),
      );

      // 3. Record stock adjustment audit log for the sale
      final adjRef = _firestore.collection(FirestoreCollections.stockAdjustments).doc();
      firestoreBatch.set(adjRef, {
        'id': adjRef.id,
        'pharmacy_id': pharmacyId,
        'medicine_id': cartItem.medicineId,
        'batch_id': usedBatchNo ?? 'POS-SALE',
        'quantity_change': -cartItem.quantity,
        'reason': 'POS Sale Invoice #$invoiceNo',
        'created_by': cashierId,
        'created_at': nowIso,
      });

      recordedItems.add({
        'id': saleRef.collection('sale_items').doc().id,
        'medicine_id': cartItem.medicineId,
        'medicine_name': cartItem.name,
        'batch_no': usedBatchNo,
        'quantity': cartItem.quantity,
        'unit_price': cartItem.unitPrice,
        'cost_price': unitCost,
        'total': cartItem.lineTotal,
      });
    }

    // 2. Record in sales collection
    final saleData = {
      'id': saleId,
      'pharmacy_id': pharmacyId,
      'invoice_no': invoiceNo,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'customer_name': customerName.trim().isEmpty
          ? 'Walk-in Customer'
          : customerName.trim(),
      'subtotal': subtotal,
      'discount': discount,
      'total': grandTotal,
      'payment_method': paymentMethod,
      'created_at': nowIso,
      'items': recordedItems,
    };

    firestoreBatch.set(saleRef, saleData);

    // 3. Update dedicated Cashiers subcollection metrics inside the pharmacy
    final cashierDocRef = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.cashiers)
        .doc(cashierId);
    firestoreBatch.set(
        cashierDocRef,
        {
          'id': cashierId,
          'pharmacy_id': pharmacyId,
          'name': cashierName,
          'total_sales_count': FieldValue.increment(1),
          'total_sales_amount': FieldValue.increment(grandTotal),
          'updated_at': nowIso,
        },
        SetOptions(merge: true));

    await firestoreBatch.commit();

    // 4. Update Cashier's Active Shift metrics in real time
    try {
      final shiftSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection(FirestoreCollections.shifts)
          .where('cashier_id', isEqualTo: cashierId)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (shiftSnap.docs.isNotEmpty) {
        final shiftDoc = shiftSnap.docs.first;
        final normMethod = paymentMethod.trim().toLowerCase();
        final isCash = normMethod == 'cash';
        final isEasyPaisa =
            normMethod == 'easypaisa' || normMethod == 'easy paisa';
        final isJazzCash =
            normMethod == 'jazzcash' || normMethod == 'jazz cash';
        final isCard = normMethod == 'card';

        final Map<String, dynamic> shiftUpdates = {
          'total_sales': FieldValue.increment(grandTotal),
          'total_transactions': FieldValue.increment(1),
          'updated_at': nowIso,
        };

        if (isCash) {
          shiftUpdates['cash_sales'] = FieldValue.increment(grandTotal);
          shiftUpdates['expected_closing_cash'] =
              FieldValue.increment(grandTotal);
        } else if (isEasyPaisa) {
          shiftUpdates['easypaisa_sales'] = FieldValue.increment(grandTotal);
        } else if (isJazzCash) {
          shiftUpdates['jazzcash_sales'] = FieldValue.increment(grandTotal);
        } else if (isCard) {
          shiftUpdates['card_sales'] = FieldValue.increment(grandTotal);
        } else {
          shiftUpdates['other_sales'] = FieldValue.increment(grandTotal);
        }

        final subRef = _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection(FirestoreCollections.shifts)
            .doc(shiftDoc.id);

        final rootRef =
            _firestore.collection(FirestoreCollections.shifts).doc(shiftDoc.id);

        final shiftBatch = _firestore.batch();
        shiftBatch.update(subRef, shiftUpdates);
        shiftBatch.update(rootRef, shiftUpdates);
        await shiftBatch.commit();
      }
    } catch (e) {
      debugPrint('[PosRepository] Updating shift on sale error: $e');
    }

    return SaleModel.fromJson(saleData);
  }

  Future<Map<String, dynamic>> lookupByCode(String code) async {
    final user = _auth.currentUser;
    final profile = user != null ? await _authRepo.getProfile(user.uid) : null;
    final pharmacyId = profile?.pharmacyId;

    if (pharmacyId == null) {
      return {'found': false, 'type': 'unknown'};
    }

    final trimmed = code.trim();

    // 1. Check pharmacy stocks subcollection first: pharmacies/{pharmacyId}/stocks
    try {
      final stockBarcodeSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection(FirestoreCollections.stocks)
          .where('barcode', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (stockBarcodeSnap.docs.isNotEmpty) {
        final d = stockBarcodeSnap.docs.first;
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return {
          'found': true,
          'type': 'medicine',
          'medicine_id': d.id,
          'medicine_name': data['name'] ?? '',
          'unit': data['unit'] ?? 'Strip',
          'sale_price': (data['sale_price'] as num?)?.toDouble() ?? 0.0,
          'available_stock': (data['available_stock'] as num?)?.toInt() ?? 0,
          'data': data,
        };
      }

      final stockQrSnap = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection(FirestoreCollections.stocks)
          .where('qr_code', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (stockQrSnap.docs.isNotEmpty) {
        final d = stockQrSnap.docs.first;
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return {
          'found': true,
          'type': 'medicine',
          'medicine_id': d.id,
          'medicine_name': data['name'] ?? '',
          'unit': data['unit'] ?? 'Strip',
          'sale_price': (data['sale_price'] as num?)?.toDouble() ?? 0.0,
          'available_stock': (data['available_stock'] as num?)?.toInt() ?? 0,
          'data': data,
        };
      }
    } catch (_) {}

    // 2. Check root medicines collection by barcode or qr_code
    final medSnapshot = await _firestore
        .collection(FirestoreCollections.medicines)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .where('barcode', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (medSnapshot.docs.isNotEmpty) {
      final d = medSnapshot.docs.first;
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return {
        'found': true,
        'type': 'medicine',
        'medicine_id': d.id,
        'medicine_name': data['name'] ?? '',
        'unit': data['unit'] ?? 'Strip',
        'sale_price': (data['sale_price'] as num?)?.toDouble() ?? 0.0,
        'available_stock': (data['available_stock'] as num?)?.toInt() ?? 0,
        'data': data,
      };
    }

    final qrSnapshot = await _firestore
        .collection(FirestoreCollections.medicines)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .where('qr_code', isEqualTo: trimmed)
        .limit(1)
        .getFast();

    if (qrSnapshot.docs.isNotEmpty) {
      final d = qrSnapshot.docs.first;
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return {
        'found': true,
        'type': 'medicine',
        'medicine_id': d.id,
        'medicine_name': data['name'] ?? '',
        'unit': data['unit'] ?? 'Strip',
        'sale_price': (data['sale_price'] as num?)?.toDouble() ?? 0.0,
        'available_stock': (data['available_stock'] as num?)?.toInt() ?? 0,
        'data': data,
      };
    }

    // 3. Check batches by qr_code
    final batchSnapshot = await _firestore
        .collection(FirestoreCollections.batches)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .where('qr_code', isEqualTo: trimmed)
        .limit(1)
        .getFast();

    if (batchSnapshot.docs.isNotEmpty) {
      final bData = Map<String, dynamic>.from(batchSnapshot.docs.first.data());
      bData['id'] = batchSnapshot.docs.first.id;
      final medId = bData['medicine_id'] as String?;
      if (medId != null) {
        final mDoc = await _firestore
            .collection(FirestoreCollections.medicines)
            .doc(medId)
            .getFast();
        if (mDoc.exists && mDoc.data() != null) {
          final mData = Map<String, dynamic>.from(mDoc.data()!);
          mData['id'] = mDoc.id;
          return {
            'found': true,
            'type': 'batch',
            'medicine_id': medId,
            'medicine_name': mData['name'] ?? '',
            'unit': mData['unit'] ?? 'Strip',
            'sale_price': (mData['sale_price'] as num?)?.toDouble() ?? 0.0,
            'available_stock': (mData['available_stock'] as num?)?.toInt() ?? 0,
            'batch': bData,
            'medicine': mData,
          };
        }
      }
      return {'found': true, 'type': 'batch', 'batch': bData};
    }

    return {'found': false, 'type': 'unknown'};
  }
}
