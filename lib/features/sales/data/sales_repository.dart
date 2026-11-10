import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/sale_model.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SalesRepository(firestore);
});

class SalesRepository {
  final FirebaseFirestore _firestore;

  SalesRepository(this._firestore);

  /// Real-time stream of sales. Emits immediately when a sale is processed.
  Stream<List<SaleModel>> watchSales({
    required String pharmacyId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firestore
        .collection(FirestoreCollections.sales)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) {
      var list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return SaleModel.fromJson(data);
      }).toList();

      if (startDate != null) {
        list = list.where((s) => s.createdAt.isAfter(startDate) || s.createdAt.isAtSameMomentAs(startDate)).toList();
      }
      if (endDate != null) {
        list = list.where((s) => s.createdAt.isBefore(endDate) || s.createdAt.isAtSameMomentAs(endDate)).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((s) {
          final matchesInvoice = s.invoiceNo.toString().contains(q);
          final matchesCustomer = s.customerName.toLowerCase().contains(q);
          final matchesCashier = s.cashierName?.toLowerCase().contains(q) ?? false;
          return matchesInvoice || matchesCustomer || matchesCashier;
        }).toList();
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<SaleModel>> getSales({
    required String pharmacyId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.sales)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    var list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return SaleModel.fromJson(data);
    }).toList();

    // In-memory filtering for dates and search
    if (startDate != null) {
      list = list.where((s) => s.createdAt.isAfter(startDate) || s.createdAt.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((s) => s.createdAt.isBefore(endDate) || s.createdAt.isAtSameMomentAs(endDate)).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final matchesInvoice = s.invoiceNo.toString().contains(q);
        final matchesCustomer = s.customerName.toLowerCase().contains(q);
        final matchesCashier = s.cashierName?.toLowerCase().contains(q) ?? false;
        return matchesInvoice || matchesCustomer || matchesCashier;
      }).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<SaleModel?> getSaleById(String saleId) async {
    final doc = await _firestore.collection(FirestoreCollections.sales).doc(saleId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return SaleModel.fromJson(data);
  }
}
