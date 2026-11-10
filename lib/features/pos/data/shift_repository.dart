import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/cash_shift_model.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ShiftRepository(firestore);
});

class ShiftRepository {
  final FirebaseFirestore _firestore;

  ShiftRepository(this._firestore);

  /// Real-time stream of the current cashier's active open shift.
  Stream<CashShiftModel?> watchActiveShift({
    required String pharmacyId,
    required String cashierId,
  }) {
    return _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.shifts)
        .where('cashier_id', isEqualTo: cashierId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      data['pharmacy_id'] = pharmacyId;
      return CashShiftModel.fromJson(data);
    });
  }

  /// Real-time stream of all shifts for a pharmacy (for Admin progress tracking & audit).
  Stream<List<CashShiftModel>> watchAllShifts({
    required String pharmacyId,
    String? cashierId,
    String? statusFilter, // 'all', 'open', 'closed'
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.shifts);

    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashier_id', isEqualTo: cashierId);
    }
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['pharmacy_id'] = pharmacyId;
        return CashShiftModel.fromJson(data);
      }).toList();

      list.sort((a, b) => b.openedAt.compareTo(a.openedAt));
      return list;
    });
  }

  /// Fetches the currently open shift for a cashier.
  Future<CashShiftModel?> getActiveShift({
    required String pharmacyId,
    required String cashierId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection(FirestoreCollections.shifts)
          .where('cashier_id', isEqualTo: cashierId)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      data['pharmacy_id'] = pharmacyId;
      return CashShiftModel.fromJson(data);
    } catch (e) {
      debugPrint('[ShiftRepository] getActiveShift error: $e');
      return null;
    }
  }

  /// Cashier opens shift and inputs initial cash in counter drawer (e.g. 4000 PKR).
  Future<CashShiftModel> openShift({
    required String pharmacyId,
    required String cashierId,
    required String cashierName,
    required double openingCash,
    String? openingNote,
  }) async {
    final existing = await getActiveShift(
      pharmacyId: pharmacyId,
      cashierId: cashierId,
    );
    if (existing != null) {
      throw Exception('You already have an open shift (Started at ${existing.openedAt.hour}:${existing.openedAt.minute.toString().padLeft(2, '0')}). Please close your current shift first.');
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final docRef = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.shifts)
        .doc();

    // Look up cashier's scheduled shift timings
    String? scheduledStart;
    String? scheduledEnd;
    String? punctualityStatus;
    int? punctualityMinutes;

    try {
      final profileDoc = await _firestore
          .collection(FirestoreCollections.profiles)
          .doc(cashierId)
          .get();
      if (profileDoc.exists) {
        final pData = profileDoc.data();
        scheduledStart = pData?['shift_start'] as String?;
        scheduledEnd = pData?['shift_end'] as String?;
      }
    } catch (e) {
      debugPrint('[ShiftRepository] Profile lookup for scheduled shift error: $e');
    }

    if (scheduledStart != null && scheduledStart.contains(':')) {
      try {
        final parts = scheduledStart.split(':');
        final schedHour = int.parse(parts[0].trim());
        final schedMinute = int.parse(parts[1].trim());

        final scheduledTimeMinutes = schedHour * 60 + schedMinute;
        final actualTimeMinutes = now.hour * 60 + now.minute;
        final diffMinutes = actualTimeMinutes - scheduledTimeMinutes;

        punctualityMinutes = diffMinutes;
        if (diffMinutes > 10) {
          punctualityStatus = 'late';
        } else if (diffMinutes < -10) {
          punctualityStatus = 'early';
        } else {
          punctualityStatus = 'on_time';
        }
      } catch (e) {
        debugPrint('[ShiftRepository] Punctuality calculation error: $e');
      }
    }

    final shiftData = {
      'id': docRef.id,
      'pharmacy_id': pharmacyId,
      'cashier_id': cashierId,
      'cashier_name': cashierName.trim().isEmpty ? 'Cashier' : cashierName.trim(),
      'status': 'open',
      'opened_at': nowIso,
      'opening_cash': openingCash,
      'expected_closing_cash': openingCash,
      'cash_sales': 0.0,
      'easypaisa_sales': 0.0,
      'jazzcash_sales': 0.0,
      'card_sales': 0.0,
      'other_sales': 0.0,
      'total_sales': 0.0,
      'total_transactions': 0,
      if (openingNote != null && openingNote.trim().isNotEmpty)
        'opening_note': openingNote.trim(),
      if (scheduledStart != null && scheduledStart.trim().isNotEmpty)
        'scheduled_start': scheduledStart.trim(),
      if (scheduledEnd != null && scheduledEnd.trim().isNotEmpty)
        'scheduled_end': scheduledEnd.trim(),
      if (punctualityStatus != null)
        'punctuality_status': punctualityStatus,
      if (punctualityMinutes != null)
        'punctuality_minutes': punctualityMinutes,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    final batch = _firestore.batch();
    // 1. Write to pharmacy's shifts subcollection
    batch.set(docRef, shiftData);

    // 2. Also write to root shifts collection for multi-collection indexing/reporting
    final rootRef = _firestore.collection(FirestoreCollections.shifts).doc(docRef.id);
    batch.set(rootRef, shiftData);

    await batch.commit();
    return CashShiftModel.fromJson(shiftData);
  }

  /// Cashier closes shift, enters counted cash in drawer (e.g. 8000 PKR), and reconciles discrepancy.
  Future<CashShiftModel> closeShift({
    required String shiftId,
    required String pharmacyId,
    required double actualClosingCash,
    String? closingNote,
  }) async {
    final subRef = _firestore
        .collection(FirestoreCollections.pharmacies)
        .doc(pharmacyId)
        .collection(FirestoreCollections.shifts)
        .doc(shiftId);

    final docSnap = await subRef.get();
    if (!docSnap.exists) {
      throw Exception('Shift record #$shiftId not found');
    }

    final data = Map<String, dynamic>.from(docSnap.data()!);
    final opening = (data['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final cashSales = (data['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final expectedClosingCash = (data['expected_closing_cash'] as num?)?.toDouble() ?? (opening + cashSales);
    final discrepancy = actualClosingCash - expectedClosingCash;
    final nowIso = DateTime.now().toIso8601String();

    final updateData = {
      'status': 'closed',
      'closed_at': nowIso,
      'actual_closing_cash': actualClosingCash,
      'expected_closing_cash': expectedClosingCash,
      'cash_discrepancy': discrepancy,
      if (closingNote != null && closingNote.trim().isNotEmpty)
        'closing_note': closingNote.trim(),
      'updated_at': nowIso,
    };

    final batch = _firestore.batch();
    batch.update(subRef, updateData);

    final rootRef = _firestore.collection(FirestoreCollections.shifts).doc(shiftId);
    batch.update(rootRef, updateData);

    await batch.commit();

    data.addAll(updateData);
    data['id'] = shiftId;
    data['pharmacy_id'] = pharmacyId;
    return CashShiftModel.fromJson(data);
  }

  /// Records completed sale into active shift (Cash, EasyPaisa, JazzCash, Card, etc.).
  Future<void> recordSaleToShift({
    required String pharmacyId,
    required String cashierId,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    try {
      final activeShift = await getActiveShift(
        pharmacyId: pharmacyId,
        cashierId: cashierId,
      );
      if (activeShift == null) return;

      final normMethod = paymentMethod.trim().toLowerCase();
      final isCash = normMethod == 'cash';
      final isEasyPaisa = normMethod == 'easypaisa' || normMethod == 'easy paisa';
      final isJazzCash = normMethod == 'jazzcash' || normMethod == 'jazz cash';
      final isCard = normMethod == 'card';

      final Map<String, dynamic> updates = {
        'total_sales': FieldValue.increment(totalAmount),
        'total_transactions': FieldValue.increment(1),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isCash) {
        updates['cash_sales'] = FieldValue.increment(totalAmount);
        updates['expected_closing_cash'] = FieldValue.increment(totalAmount);
      } else if (isEasyPaisa) {
        updates['easypaisa_sales'] = FieldValue.increment(totalAmount);
      } else if (isJazzCash) {
        updates['jazzcash_sales'] = FieldValue.increment(totalAmount);
      } else if (isCard) {
        updates['card_sales'] = FieldValue.increment(totalAmount);
      } else {
        updates['other_sales'] = FieldValue.increment(totalAmount);
      }

      final subRef = _firestore
          .collection(FirestoreCollections.pharmacies)
          .doc(pharmacyId)
          .collection(FirestoreCollections.shifts)
          .doc(activeShift.id);

      final rootRef = _firestore.collection(FirestoreCollections.shifts).doc(activeShift.id);

      final batch = _firestore.batch();
      batch.update(subRef, updates);
      batch.update(rootRef, updates);
      await batch.commit();
    } catch (e) {
      debugPrint('[ShiftRepository] recordSaleToShift error: $e');
    }
  }
}

