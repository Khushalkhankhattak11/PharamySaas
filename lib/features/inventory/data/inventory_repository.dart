import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/batch_model.dart';
import '../../../shared/models/medicine_model.dart';
import '../../../shared/models/stock_adjustment_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InventoryRepository(firestore);
});

class InventoryRepository {
  final FirebaseFirestore _firestore;

  InventoryRepository(this._firestore);

  /// Real-time stream of medicines. Emits instantly from local cache when offline,
  /// and automatically synchronizes with Firestore in real-time when online.
  Stream<List<MedicineModel>> watchMedicines({
    required String pharmacyId,
    String? search,
    String filter = 'all',
  }) {
    final controller = StreamController<List<MedicineModel>>.broadcast();
    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    final stocksQuery = pharmacyDoc.collection(FirestoreCollections.stocks);
    final productsSubQuery = pharmacyDoc.collection(FirestoreCollections.products);
    final capitalProductsSubQuery = pharmacyDoc.collection('Products');
    final medicinesSubQuery = pharmacyDoc.collection(FirestoreCollections.medicines);

    final rootQuery = _firestore
        .collection(FirestoreCollections.medicines)
        .where('pharmacy_id', isEqualTo: pharmacyId);

    final rootProductsQuery = _firestore
        .collection(FirestoreCollections.products)
        .where('pharmacy_id', isEqualTo: pharmacyId);

    final rootCapitalProductsQuery = _firestore
        .collection('Products')
        .where('pharmacy_id', isEqualTo: pharmacyId);

    final Map<String, MedicineModel> stocksMap = {};
    final Map<String, MedicineModel> productsSubMap = {};
    final Map<String, MedicineModel> capitalProductsSubMap = {};
    final Map<String, MedicineModel> medicinesSubMap = {};
    final Map<String, MedicineModel> rootMap = {};
    final Map<String, MedicineModel> rootProductsMap = {};
    final Map<String, MedicineModel> rootCapitalProductsMap = {};

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, MedicineModel> combined = {};

      void addAllMerged(Map<String, MedicineModel> source) {
        for (final entry in source.entries) {
          if (!combined.containsKey(entry.key)) {
            combined[entry.key] = entry.value;
          } else {
            combined[entry.key] = _mergeMedicineModels(combined[entry.key]!, entry.value);
          }
        }
      }

      addAllMerged(rootMap);
      addAllMerged(rootProductsMap);
      addAllMerged(rootCapitalProductsMap);
      addAllMerged(stocksMap);
      addAllMerged(medicinesSubMap);
      addAllMerged(capitalProductsSubMap);
      addAllMerged(productsSubMap);

      var list = combined.values.toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        list = list.where((m) {
          final name = m.name.toLowerCase();
          final generic = m.genericName?.toLowerCase() ?? '';
          final barcode = m.barcode?.toLowerCase() ?? '';
          final brand = m.brandName?.toLowerCase() ?? '';
          final reg = m.registrationNumber?.toLowerCase() ?? '';
          final qr = m.qrCode.toLowerCase();
          return name.contains(s) ||
              generic.contains(s) ||
              barcode.contains(s) ||
              brand.contains(s) ||
              reg.contains(s) ||
              qr.contains(s);
        }).toList();
      }

      final now = DateTime.now();
      if (filter == 'inactive') {
        list = list.where((m) => !m.isActive).toList();
      } else if (filter == 'low_stock') {
        list = list.where((m) => m.isActive && m.availableStock <= m.minStockLevel).toList();
      } else if (filter == 'expiring') {
        final threshold = now.add(const Duration(days: 10));
        list = list.where((m) =>
            m.isActive &&
            m.nearestExpiry != null &&
            m.nearestExpiry!.isBefore(threshold) &&
            m.nearestExpiry!.isAfter(now)).toList();
      } else if (filter == 'expired') {
        list = list.where((m) => m.isActive && m.nearestExpiry != null && m.nearestExpiry!.isBefore(now)).toList();
      } else if (filter != 'all') {
        list = list.where((m) => m.isActive).toList();
      }

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      controller.add(list);
    }

    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;
    StreamSubscription? sub4;
    StreamSubscription? sub5;
    StreamSubscription? sub6;
    StreamSubscription? sub7;

    controller.onListen = () {
      // Immediately emit any existing medicines from Firestore so POS and inventory don't show empty
      getMedicines(pharmacyId: pharmacyId, search: search, filter: filter).then((initialList) {
        if (!controller.isClosed) {
          controller.add(initialList);
        }
      }).catchError((err) {
        debugPrint('[InventoryRepository] initial getMedicines error: $err');
        if (!controller.isClosed) {
          controller.add([]);
        }
      });

      sub1 = stocksQuery.snapshots().listen(
        (snap) {
          stocksMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              data['pharmacy_id'] = pharmacyId;
              stocksMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing stock doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] stocksQuery sub1 error: $e'),
      );

      sub2 = productsSubQuery.snapshots().listen(
        (snap) {
          productsSubMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              data['pharmacy_id'] = pharmacyId;
              productsSubMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing products doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] productsSubQuery sub2 error: $e'),
      );

      sub3 = capitalProductsSubQuery.snapshots().listen(
        (snap) {
          capitalProductsSubMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              data['pharmacy_id'] = pharmacyId;
              capitalProductsSubMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing Products doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] capitalProductsSubQuery sub3 error: $e'),
      );

      sub4 = medicinesSubQuery.snapshots().listen(
        (snap) {
          medicinesSubMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              data['pharmacy_id'] = pharmacyId;
              medicinesSubMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing medicines doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] medicinesSubQuery sub4 error: $e'),
      );

      sub5 = rootQuery.snapshots().listen(
        (snap) {
          rootMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              rootMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing root medicine doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] rootQuery sub5 error: $e'),
      );

      sub6 = rootProductsQuery.snapshots().listen(
        (snap) {
          rootProductsMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              rootProductsMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing root products doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] rootProductsQuery sub6 error: $e'),
      );

      sub7 = rootCapitalProductsQuery.snapshots().listen(
        (snap) {
          rootCapitalProductsMap.clear();
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              rootCapitalProductsMap[doc.id] = MedicineModel.fromJson(data);
            } catch (e) {
              debugPrint('[InventoryRepository] Error parsing root Products doc ${doc.id}: $e');
            }
          }
          emitMerged();
        },
        onError: (e) => debugPrint('[InventoryRepository] rootCapitalProductsQuery sub7 error: $e'),
      );
    };

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
      sub3?.cancel();
      sub4?.cancel();
      sub5?.cancel();
      sub6?.cancel();
      sub7?.cancel();
    };

    return controller.stream;
  }

  static MedicineModel _mergeMedicineModels(MedicineModel existing, MedicineModel incoming) {
    int authoritativeStock;
    DateTime? effectiveUpdatedAt;

    if (existing.updatedAt != null && incoming.updatedAt != null) {
      if (incoming.updatedAt!.isAfter(existing.updatedAt!)) {
        authoritativeStock = incoming.availableStock;
        effectiveUpdatedAt = incoming.updatedAt;
      } else if (existing.updatedAt!.isAfter(incoming.updatedAt!)) {
        authoritativeStock = existing.availableStock;
        effectiveUpdatedAt = existing.updatedAt;
      } else {
        // Same timestamp, take the lower stock (reflects recent sale deductions)
        authoritativeStock = (incoming.availableStock <= existing.availableStock)
            ? incoming.availableStock
            : existing.availableStock;
        effectiveUpdatedAt = incoming.updatedAt;
      }
    } else if (incoming.updatedAt != null) {
      authoritativeStock = incoming.availableStock;
      effectiveUpdatedAt = incoming.updatedAt;
    } else if (existing.updatedAt != null) {
      authoritativeStock = existing.availableStock;
      effectiveUpdatedAt = existing.updatedAt;
    } else {
      // Neither has updatedAt: take the lower stock (sales decrement stock)
      authoritativeStock = (incoming.availableStock <= existing.availableStock)
          ? incoming.availableStock
          : existing.availableStock;
    }

    if (authoritativeStock < 0) authoritativeStock = 0;

    return incoming.copyWith(
      availableStock: authoritativeStock,
      updatedAt: effectiveUpdatedAt,
      imageUrl: (incoming.imageUrl != null && incoming.imageUrl!.trim().isNotEmpty)
          ? incoming.imageUrl
          : existing.imageUrl,
      brandName: (incoming.brandName != null && incoming.brandName!.trim().isNotEmpty)
          ? incoming.brandName
          : existing.brandName,
      registrationNumber: (incoming.registrationNumber != null && incoming.registrationNumber!.trim().isNotEmpty)
          ? incoming.registrationNumber
          : existing.registrationNumber,
      genericName: (incoming.genericName != null && incoming.genericName!.trim().isNotEmpty)
          ? incoming.genericName
          : existing.genericName,
      category: (incoming.category != null && incoming.category!.trim().isNotEmpty)
          ? incoming.category
          : existing.category,
      manufacturer: (incoming.manufacturer != null && incoming.manufacturer!.trim().isNotEmpty)
          ? incoming.manufacturer
          : existing.manufacturer,
      barcode: (incoming.barcode != null && incoming.barcode!.trim().isNotEmpty)
          ? incoming.barcode
          : existing.barcode,
      salePrice: incoming.salePrice > 0 ? incoming.salePrice : existing.salePrice,
      nearestExpiry: incoming.nearestExpiry ?? existing.nearestExpiry,
      createdAt: existing.createdAt ?? incoming.createdAt,
    );
  }

  Future<List<MedicineModel>> getMedicines({
    required String pharmacyId,
    String? search,
    String filter = 'all', // 'all', 'low_stock', 'expiring', 'expired', 'inactive'
  }) async {
    final Map<String, MedicineModel> resultMap = {};
    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    void addDocToResultMap(String docId, MedicineModel model) {
      if (!resultMap.containsKey(docId)) {
        resultMap[docId] = model;
      } else {
        resultMap[docId] = _mergeMedicineModels(resultMap[docId]!, model);
      }
    }

    // 1. Fetch from pharmacy products subcollection: pharmacies/{pharmacyId}/products
    try {
      Query<Map<String, dynamic>> prodSub = pharmacyDoc.collection(FirestoreCollections.products);
      if (filter == 'inactive') {
        prodSub = prodSub.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        prodSub = prodSub.where('is_active', isEqualTo: true);
      }
      final prodSnap = await prodSub.get();
      for (final doc in prodSnap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['pharmacy_id'] = pharmacyId;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (e) {
          debugPrint('[InventoryRepository] Error parsing products doc ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[InventoryRepository] products get error: $e');
    }

    // 1b. Fetch from pharmacy Products subcollection (uppercase): pharmacies/{pharmacyId}/Products
    try {
      Query<Map<String, dynamic>> prodCapSub = pharmacyDoc.collection('Products');
      if (filter == 'inactive') {
        prodCapSub = prodCapSub.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        prodCapSub = prodCapSub.where('is_active', isEqualTo: true);
      }
      final prodCapSnap = await prodCapSub.get();
      for (final doc in prodCapSnap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['pharmacy_id'] = pharmacyId;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (e) {
          debugPrint('[InventoryRepository] Error parsing Products doc ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[InventoryRepository] Products (uppercase) get error: $e');
    }

    // 2. Fetch from pharmacy medicines subcollection: pharmacies/{pharmacyId}/medicines
    try {
      Query<Map<String, dynamic>> medSub = pharmacyDoc.collection(FirestoreCollections.medicines);
      if (filter == 'inactive') {
        medSub = medSub.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        medSub = medSub.where('is_active', isEqualTo: true);
      }
      final medSnap = await medSub.get();
      for (final doc in medSnap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['pharmacy_id'] = pharmacyId;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (e) {
          debugPrint('[InventoryRepository] Error parsing medicines doc ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[InventoryRepository] medicines get error: $e');
    }

    // 3. Fetch from pharmacy stocks subcollection: pharmacies/{pharmacyId}/stocks
    try {
      Query<Map<String, dynamic>> subQuery = pharmacyDoc.collection(FirestoreCollections.stocks);
      if (filter == 'inactive') {
        subQuery = subQuery.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        subQuery = subQuery.where('is_active', isEqualTo: true);
      }

      final subSnap = await subQuery.get();
      for (final doc in subSnap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['pharmacy_id'] = pharmacyId;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (e) {
          debugPrint('[InventoryRepository] Error parsing stocks doc ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[InventoryRepository] stocks get error: $e');
    }

    // 4. Also fetch from root medicines, products, Products, and stocks collections and merge
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestoreCollections.medicines)
          .where('pharmacy_id', isEqualTo: pharmacyId);

      if (filter == 'inactive') {
        query = query.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        query = query.where('is_active', isEqualTo: true);
      }

      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (_) {}
      }
    } catch (_) {}

    try {
      Query<Map<String, dynamic>> prodQuery = _firestore
          .collection(FirestoreCollections.products)
          .where('pharmacy_id', isEqualTo: pharmacyId);

      if (filter == 'inactive') {
        prodQuery = prodQuery.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        prodQuery = prodQuery.where('is_active', isEqualTo: true);
      }

      final prodSnapshot = await prodQuery.get();
      for (final doc in prodSnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (_) {}
      }
    } catch (_) {}

    try {
      Query<Map<String, dynamic>> capProdQuery = _firestore
          .collection('Products')
          .where('pharmacy_id', isEqualTo: pharmacyId);

      if (filter == 'inactive') {
        capProdQuery = capProdQuery.where('is_active', isEqualTo: false);
      } else if (filter != 'all') {
        capProdQuery = capProdQuery.where('is_active', isEqualTo: true);
      }

      final capProdSnapshot = await capProdQuery.get();
      for (final doc in capProdSnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          addDocToResultMap(doc.id, MedicineModel.fromJson(data));
        } catch (_) {}
      }
    } catch (_) {}

    var list = resultMap.values.toList();

    // Client-side text search (case-insensitive substring)
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      list = list.where((m) {
        final name = m.name.toLowerCase();
        final generic = m.genericName?.toLowerCase() ?? '';
        final barcode = m.barcode?.toLowerCase() ?? '';
        final qr = m.qrCode.toLowerCase();
        return name.contains(s) || generic.contains(s) || barcode.contains(s) || qr.contains(s);
      }).toList();
    }

    // Filter evaluations
    final now = DateTime.now();
    if (filter == 'low_stock') {
      list = list.where((m) => m.availableStock <= m.minStockLevel).toList();
    } else if (filter == 'expiring') {
      final threshold = now.add(const Duration(days: 10));
      list = list.where((m) =>
          m.nearestExpiry != null &&
          m.nearestExpiry!.isBefore(threshold) &&
          m.nearestExpiry!.isAfter(now)).toList();
    } else if (filter == 'expired') {
      list = list.where((m) => m.nearestExpiry != null && m.nearestExpiry!.isBefore(now)).toList();
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<MedicineModel?> getMedicineById(String id, [String? pharmacyId]) async {
    if (pharmacyId != null && pharmacyId.isNotEmpty) {
      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);
      try {
        final prodDoc = await pharmacyDoc.collection(FirestoreCollections.products).doc(id).get();
        if (prodDoc.exists && prodDoc.data() != null) {
          final data = Map<String, dynamic>.from(prodDoc.data()!);
          data['id'] = prodDoc.id;
          data['pharmacy_id'] = pharmacyId;
          return MedicineModel.fromJson(data);
        }
      } catch (_) {}

      try {
        final medDoc = await pharmacyDoc.collection(FirestoreCollections.medicines).doc(id).get();
        if (medDoc.exists && medDoc.data() != null) {
          final data = Map<String, dynamic>.from(medDoc.data()!);
          data['id'] = medDoc.id;
          data['pharmacy_id'] = pharmacyId;
          return MedicineModel.fromJson(data);
        }
      } catch (_) {}

      try {
        final subDoc = await pharmacyDoc.collection(FirestoreCollections.stocks).doc(id).get();
        if (subDoc.exists && subDoc.data() != null) {
          final data = Map<String, dynamic>.from(subDoc.data()!);
          data['id'] = subDoc.id;
          data['pharmacy_id'] = pharmacyId;
          return MedicineModel.fromJson(data);
        }
      } catch (_) {}
    }

    try {
      final prodDoc = await _firestore.collection(FirestoreCollections.products).doc(id).get();
      if (prodDoc.exists && prodDoc.data() != null) {
        final data = Map<String, dynamic>.from(prodDoc.data()!);
        data['id'] = prodDoc.id;
        return MedicineModel.fromJson(data);
      }
    } catch (_) {}

    final doc = await _firestore.collection(FirestoreCollections.medicines).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return MedicineModel.fromJson(data);
  }

  Future<List<BatchModel>> getBatches(String medicineId, [String? pharmacyId]) async {
    final Map<String, BatchModel> batchMap = {};

    if (pharmacyId != null && pharmacyId.isNotEmpty) {
      try {
        final subSnap = await _firestore
            .collection(FirestoreCollections.pharmacies)
            .doc(pharmacyId)
            .collection(FirestoreCollections.batches)
            .where('medicine_id', isEqualTo: medicineId)
            .get();
        for (final doc in subSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          batchMap[doc.id] = BatchModel.fromJson(data);
        }
      } catch (_) {}
    }

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.batches)
          .where('medicine_id', isEqualTo: medicineId)
          .get();

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        if (!batchMap.containsKey(doc.id)) {
          batchMap[doc.id] = BatchModel.fromJson(data);
        }
      }
    } catch (_) {}

    final list = batchMap.values.toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  Future<MedicineModel?> findDuplicateMedicine({
    required String pharmacyId,
    String? name,
    String? brandName,
    String? registrationNumber,
    String? barcode,
  }) async {
    final allMedicines = await getMedicines(pharmacyId: pharmacyId);

    final cleanReg = registrationNumber?.trim().toLowerCase();
    final cleanBarcode = barcode?.trim().toLowerCase();
    final cleanName = name?.trim().toLowerCase();
    final cleanBrand = brandName?.trim().toLowerCase();

    for (final med in allMedicines) {
      // 1. Exact match on Registration Number (DRAP Reg No)
      if (cleanReg != null && cleanReg.isNotEmpty && med.registrationNumber != null) {
        if (med.registrationNumber!.trim().toLowerCase() == cleanReg) {
          return med;
        }
      }

      // 2. Exact match on Manufacturer Barcode
      if (cleanBarcode != null && cleanBarcode.isNotEmpty && med.barcode != null) {
        if (med.barcode!.trim().toLowerCase() == cleanBarcode) {
          return med;
        }
      }

      // 3. Match on Name or Brand Name
      if (cleanName != null && cleanName.isNotEmpty) {
        if (med.name.trim().toLowerCase() == cleanName) {
          return med;
        }
        if (med.brandName != null && med.brandName!.trim().toLowerCase() == cleanName) {
          return med;
        }
      }

      if (cleanBrand != null && cleanBrand.isNotEmpty) {
        if (med.brandName != null && med.brandName!.trim().toLowerCase() == cleanBrand) {
          return med;
        }
        if (med.name.trim().toLowerCase() == cleanBrand) {
          return med;
        }
      }
    }

    return null;
  }

  Future<MedicineModel> createMedicine({
    required String pharmacyId,
    required String name,
    String? brandName,
    String? registrationNumber,
    String? genericName,
    String? category,
    String? manufacturer,
    String? barcode,
    String? customQrCode,
    String unit = 'Strip',
    required double salePrice,
    double discountPercent = 0.0,
    int minStockLevel = 10,
    int initialStock = 0,
    double? purchasePrice,
    DateTime? expiryDate,
    String? imageUrl,
  }) async {
    // Check if an existing medicine in this pharmacy matches (Prevent duplicates!)
    final existing = await findDuplicateMedicine(
      pharmacyId: pharmacyId,
      name: name,
      brandName: brandName,
      registrationNumber: registrationNumber,
      barcode: barcode,
    );

    final now = DateTime.now().toIso8601String();
    final exp = expiryDate ?? DateTime.now().add(const Duration(days: 365));

    if (existing != null) {
      // Medicine already present: Update stock and details instead of creating a duplicate
      final updatedStock = existing.availableStock + initialStock;

      final completeData = <String, dynamic>{
        'id': existing.id,
        'pharmacy_id': pharmacyId,
        'name': existing.name,
        'brand_name': (brandName != null && brandName.trim().isNotEmpty) ? brandName.trim() : existing.brandName,
        'registration_number': (registrationNumber != null && registrationNumber.trim().isNotEmpty)
            ? registrationNumber.trim()
            : existing.registrationNumber,
        'generic_name': (genericName != null && genericName.trim().isNotEmpty) ? genericName.trim() : existing.genericName,
        'category': (category != null && category.trim().isNotEmpty) ? category.trim() : existing.category,
        'manufacturer': (manufacturer != null && manufacturer.trim().isNotEmpty) ? manufacturer.trim() : existing.manufacturer,
        'barcode': (barcode != null && barcode.trim().isNotEmpty) ? barcode.trim() : existing.barcode,
        'qr_code': existing.qrCode,
        'unit': unit.isNotEmpty ? unit : existing.unit,
        'sale_price': salePrice > 0 ? salePrice : existing.salePrice,
        'discount_percent': discountPercent > 0 ? discountPercent : existing.discountPercent,
        'min_stock_level': minStockLevel > 0 ? minStockLevel : existing.minStockLevel,
        'available_stock': updatedStock,
        'nearest_expiry': initialStock > 0 ? exp.toIso8601String() : existing.nearestExpiry?.toIso8601String(),
        'is_active': true,
        'image_url': (imageUrl != null && imageUrl.trim().isNotEmpty) ? imageUrl.trim() : existing.imageUrl,
        'created_at': existing.createdAt?.toIso8601String() ?? now,
        'updated_at': now,
      };

      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

      // 1. Write to pharmacy's products subcollection: pharmacies/{pharmacyId}/products
      await pharmacyDoc.collection(FirestoreCollections.products).doc(existing.id).set(completeData, SetOptions(merge: true));

      // 1b. Also write to uppercase Products subcollection
      try {
        await pharmacyDoc.collection('Products').doc(existing.id).set(completeData, SetOptions(merge: true));
      } catch (_) {}

      // 2. Write to pharmacy's medicines subcollection: pharmacies/{pharmacyId}/medicines
      await pharmacyDoc.collection(FirestoreCollections.medicines).doc(existing.id).set(completeData, SetOptions(merge: true));

      // 3. Write to pharmacy's stocks subcollection: pharmacies/{pharmacyId}/stocks
      await pharmacyDoc.collection(FirestoreCollections.stocks).doc(existing.id).set(completeData, SetOptions(merge: true));

      // 4. Add batch entry for new stock under pharmacy subcollection
      Map<String, dynamic>? batchData;
      DocumentReference? batchDocRef;
      if (initialStock > 0) {
        batchDocRef = _firestore.collection(FirestoreCollections.batches).doc();
        final batchQr = 'BATCH-${batchDocRef.id.substring(0, 8).toUpperCase()}';
        final buyPrice = purchasePrice ?? (salePrice * 0.7);

        batchData = {
          'id': batchDocRef.id,
          'pharmacy_id': pharmacyId,
          'medicine_id': existing.id,
          'batch_no': 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          'qr_code': batchQr,
          'expiry_date': exp.toIso8601String(),
          'quantity': initialStock,
          'purchase_price': buyPrice,
          'created_at': now,
          'updated_at': now,
        };

        await pharmacyDoc.collection(FirestoreCollections.batches).doc(batchDocRef.id).set(batchData);
      }

      // 5. Also sync to root medicines, products, and stocks collections
      try {
        final rootMedRef = _firestore.collection(FirestoreCollections.medicines).doc(existing.id);
        await rootMedRef.set(completeData, SetOptions(merge: true));
        final rootProdRef = _firestore.collection(FirestoreCollections.products).doc(existing.id);
        await rootProdRef.set(completeData, SetOptions(merge: true));
        final rootCapProdRef = _firestore.collection('Products').doc(existing.id);
        await rootCapProdRef.set(completeData, SetOptions(merge: true));
        final rootStockRef = _firestore.collection(FirestoreCollections.stocks).doc(existing.id);
        await rootStockRef.set(completeData, SetOptions(merge: true));
        if (batchDocRef != null && batchData != null) {
          await batchDocRef.set(batchData);
        }
      } catch (e) {
        debugPrint('[InventoryRepository] Root sync note: $e');
      }

      return existing.copyWith(
        availableStock: updatedStock,
        salePrice: salePrice > 0 ? salePrice : existing.salePrice,
        discountPercent: discountPercent > 0 ? discountPercent : existing.discountPercent,
        brandName: (brandName != null && brandName.trim().isNotEmpty) ? brandName.trim() : existing.brandName,
        registrationNumber: (registrationNumber != null && registrationNumber.trim().isNotEmpty)
            ? registrationNumber.trim()
            : existing.registrationNumber,
        imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty) ? imageUrl.trim() : existing.imageUrl,
        nearestExpiry: initialStock > 0 ? exp : existing.nearestExpiry,
      );
    }

    // Medicine not present: Create brand new document
    final docRef = _firestore.collection(FirestoreCollections.medicines).doc();
    final medId = docRef.id;
    final qrCode = customQrCode != null && customQrCode.trim().isNotEmpty
        ? customQrCode.trim()
        : 'MED-${medId.substring(0, 8).toUpperCase()}';

    final data = {
      'id': medId,
      'pharmacy_id': pharmacyId,
      'name': name.trim(),
      if (brandName != null && brandName.trim().isNotEmpty) 'brand_name': brandName.trim(),
      if (registrationNumber != null && registrationNumber.trim().isNotEmpty)
        'registration_number': registrationNumber.trim(),
      'generic_name': genericName?.trim(),
      'category': category?.trim(),
      'manufacturer': manufacturer?.trim(),
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'qr_code': qrCode,
      'unit': unit,
      'sale_price': salePrice,
      'discount_percent': discountPercent,
      'min_stock_level': minStockLevel,
      'available_stock': initialStock,
      'nearest_expiry': initialStock > 0 ? exp.toIso8601String() : null,
      'is_active': true,
      'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'created_at': now,
      'updated_at': now,
    };

    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    // 1. Write to pharmacy's products subcollection: pharmacies/{pharmacyId}/products/{medId}
    await pharmacyDoc.collection(FirestoreCollections.products).doc(medId).set(data);

    // 1b. Also write to uppercase Products subcollection
    try {
      await pharmacyDoc.collection('Products').doc(medId).set(data);
    } catch (_) {}

    // 2. Write to pharmacy's medicines subcollection: pharmacies/{pharmacyId}/medicines/{medId}
    await pharmacyDoc.collection(FirestoreCollections.medicines).doc(medId).set(data);

    // 3. Write to pharmacy's stocks subcollection: pharmacies/{pharmacyId}/stocks/{medId}
    await pharmacyDoc.collection(FirestoreCollections.stocks).doc(medId).set(data);

    // 4. If initial stock units are entered, create the first batch automatically in pharmacy
    Map<String, dynamic>? batchData;
    DocumentReference? batchDocRef;
    if (initialStock > 0) {
      batchDocRef = _firestore.collection(FirestoreCollections.batches).doc();
      final batchQr = 'BATCH-${batchDocRef.id.substring(0, 8).toUpperCase()}';
      final buyPrice = purchasePrice ?? (salePrice * 0.7);

      batchData = {
        'id': batchDocRef.id,
        'pharmacy_id': pharmacyId,
        'medicine_id': medId,
        'batch_no': 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'qr_code': batchQr,
        'expiry_date': exp.toIso8601String(),
        'quantity': initialStock,
        'purchase_price': buyPrice,
        'created_at': now,
        'updated_at': now,
      };

      await pharmacyDoc.collection(FirestoreCollections.batches).doc(batchDocRef.id).set(batchData);
    }

    // 5. Also sync to root collections
    try {
      await docRef.set(data);
      await _firestore.collection(FirestoreCollections.products).doc(medId).set(data);
      await _firestore.collection('Products').doc(medId).set(data);
      await _firestore.collection(FirestoreCollections.stocks).doc(medId).set(data);
      if (batchDocRef != null && batchData != null) {
        await batchDocRef.set(batchData);
      }
    } catch (e) {
      debugPrint('[InventoryRepository] Root sync note: $e');
    }

    return MedicineModel.fromJson(data);
  }

  Future<void> updateMedicine({
    required String medicineId,
    required String name,
    String? pharmacyId,
    String? brandName,
    String? registrationNumber,
    String? genericName,
    String? category,
    String? manufacturer,
    String? barcode,
    String? qrCode,
    String unit = 'Strip',
    required double salePrice,
    double discountPercent = 0.0,
    int minStockLevel = 10,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> updateData = {
      'name': name.trim(),
      if (brandName != null && brandName.trim().isNotEmpty) 'brand_name': brandName.trim(),
      if (registrationNumber != null && registrationNumber.trim().isNotEmpty)
        'registration_number': registrationNumber.trim(),
      'generic_name': genericName?.trim(),
      'category': category?.trim(),
      'manufacturer': manufacturer?.trim(),
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'unit': unit,
      'sale_price': salePrice,
      'discount_percent': discountPercent,
      'min_stock_level': minStockLevel,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (imageUrl != null) {
      updateData['image_url'] = imageUrl.trim().isEmpty ? null : imageUrl.trim();
    }

    String? targetPharmacyId = pharmacyId;
    if (targetPharmacyId == null || targetPharmacyId.isEmpty) {
      try {
        final medDoc = await _firestore.collection(FirestoreCollections.medicines).doc(medicineId).get();
        targetPharmacyId = medDoc.data()?['pharmacy_id'] as String?;
      } catch (_) {}
    }

    if (targetPharmacyId != null && targetPharmacyId.isNotEmpty) {
      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(targetPharmacyId);
      await pharmacyDoc.collection(FirestoreCollections.products).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.medicines).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.stocks).doc(medicineId).set(updateData, SetOptions(merge: true));
    }

    try {
      final medRef = _firestore.collection(FirestoreCollections.medicines).doc(medicineId);
      await medRef.set(updateData, SetOptions(merge: true));
      final prodRef = _firestore.collection(FirestoreCollections.products).doc(medicineId);
      await prodRef.set(updateData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> setMedicineActive({
    required String medicineId,
    required bool isActive,
    String? pharmacyId,
  }) async {
    final updateData = {
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    String? targetPharmacyId = pharmacyId;
    if (targetPharmacyId == null || targetPharmacyId.isEmpty) {
      try {
        final medDoc = await _firestore.collection(FirestoreCollections.medicines).doc(medicineId).get();
        targetPharmacyId = medDoc.data()?['pharmacy_id'] as String?;
      } catch (_) {}
    }

    if (targetPharmacyId != null && targetPharmacyId.isNotEmpty) {
      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(targetPharmacyId);
      await pharmacyDoc.collection(FirestoreCollections.products).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.medicines).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.stocks).doc(medicineId).set(updateData, SetOptions(merge: true));
    }

    try {
      final medRef = _firestore.collection(FirestoreCollections.medicines).doc(medicineId);
      await medRef.set(updateData, SetOptions(merge: true));
      final prodRef = _firestore.collection(FirestoreCollections.products).doc(medicineId);
      await prodRef.set(updateData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> assignBarcodeToMedicine({
    required String medicineId,
    required String barcode,
    String? pharmacyId,
  }) async {
    final updateData = {
      'barcode': barcode.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    String? targetPharmacyId = pharmacyId;
    if (targetPharmacyId == null || targetPharmacyId.isEmpty) {
      try {
        final medDoc = await _firestore.collection(FirestoreCollections.medicines).doc(medicineId).get();
        targetPharmacyId = medDoc.data()?['pharmacy_id'] as String?;
      } catch (_) {}
    }

    if (targetPharmacyId != null && targetPharmacyId.isNotEmpty) {
      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(targetPharmacyId);
      await pharmacyDoc.collection(FirestoreCollections.products).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.medicines).doc(medicineId).set(updateData, SetOptions(merge: true));
      await pharmacyDoc.collection(FirestoreCollections.stocks).doc(medicineId).set(updateData, SetOptions(merge: true));
    }

    try {
      final medRef = _firestore.collection(FirestoreCollections.medicines).doc(medicineId);
      await medRef.set(updateData, SetOptions(merge: true));
      final prodRef = _firestore.collection(FirestoreCollections.products).doc(medicineId);
      await prodRef.set(updateData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> lookupByCode(String code) async {
    final trimmed = code.trim();
    final medSnap = await _firestore
        .collection(FirestoreCollections.medicines)
        .where('barcode', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (medSnap.docs.isNotEmpty) {
      return {'found': true, 'medicine_id': medSnap.docs.first.id};
    }

    final qrSnap = await _firestore
        .collection(FirestoreCollections.medicines)
        .where('qr_code', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (qrSnap.docs.isNotEmpty) {
      return {'found': true, 'medicine_id': qrSnap.docs.first.id};
    }

    final batchSnap = await _firestore
        .collection(FirestoreCollections.batches)
        .where('qr_code', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (batchSnap.docs.isNotEmpty) {
      final medId = batchSnap.docs.first.data()['medicine_id'] as String?;
      if (medId != null) {
        return {'found': true, 'medicine_id': medId};
      }
    }

    return {'found': false};
  }

  Future<void> createStockAdjustment({
    required String pharmacyId,
    required String batchId,
    required int quantityChange,
    required String reason,
  }) async {
    final batchDoc = await _firestore.collection(FirestoreCollections.batches).doc(batchId).get();
    if (!batchDoc.exists) throw Exception('Batch not found');
    final batchData = batchDoc.data()!;
    final medicineId = batchData['medicine_id'] as String;
    final currentBatchQty = (batchData['quantity'] as num?)?.toInt() ?? 0;
    final newBatchQty = (currentBatchQty + quantityChange).clamp(0, 999999);

    final firestoreBatch = _firestore.batch();

    // 1. Log adjustment in stock_adjustments collection
    final adjRef = _firestore.collection(FirestoreCollections.stockAdjustments).doc();
    firestoreBatch.set(adjRef, {
      'id': adjRef.id,
      'pharmacy_id': pharmacyId,
      'batch_id': batchId,
      'medicine_id': medicineId,
      'quantity_change': quantityChange,
      'reason': reason.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Update batch quantity
    firestoreBatch.update(batchDoc.reference, {
      'quantity': newBatchQty,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 3. Update medicine total available stock on products, medicines, and stocks
    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    final prodRef = pharmacyDoc.collection(FirestoreCollections.products).doc(medicineId);
    firestoreBatch.set(prodRef, {
      'available_stock': FieldValue.increment(quantityChange),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final medSubRef = pharmacyDoc.collection(FirestoreCollections.medicines).doc(medicineId);
    firestoreBatch.set(medSubRef, {
      'available_stock': FieldValue.increment(quantityChange),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final stockRef = pharmacyDoc.collection(FirestoreCollections.stocks).doc(medicineId);
    firestoreBatch.set(stockRef, {
      'available_stock': FieldValue.increment(quantityChange),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final pharmacyBatchRef = pharmacyDoc.collection(FirestoreCollections.batches).doc(batchId);
    firestoreBatch.set(pharmacyBatchRef, {
      'quantity': newBatchQty,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final medRef = _firestore.collection(FirestoreCollections.medicines).doc(medicineId);
    firestoreBatch.set(medRef, {
      'available_stock': FieldValue.increment(quantityChange),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final rootProdRef = _firestore.collection(FirestoreCollections.products).doc(medicineId);
    firestoreBatch.set(rootProdRef, {
      'available_stock': FieldValue.increment(quantityChange),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await firestoreBatch.commit();
  }

  Future<List<StockAdjustmentModel>> getStockAdjustments(String pharmacyId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.stockAdjustments)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return StockAdjustmentModel.fromJson(data);
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
