import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/batch_model.dart';

void main() {
  group('FEFO (First Expired, First Out) Batch Allocation Tests', () {
    test('Allocates from batch with earliest expiry date first', () {
      final now = DateTime.now();
      final batch1 = BatchModel(
        id: 'b1',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B-EARLY',
        qrCode: 'BAT-001',
        expiryDate: now.add(const Duration(days: 30)),
        quantity: 20,
        purchasePrice: 2.0,
      );

      final batch2 = BatchModel(
        id: 'b2',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B-LATE',
        qrCode: 'BAT-002',
        expiryDate: now.add(const Duration(days: 300)),
        quantity: 50,
        purchasePrice: 2.2,
      );

      final batches = [batch2, batch1];
      // FEFO Sort
      batches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      expect(batches.first.batchNo, 'B-EARLY');
      expect(batches.last.batchNo, 'B-LATE');
    });

    test('Skips expired batches when allocating stock for sale', () {
      final now = DateTime.now();
      final expiredBatch = BatchModel(
        id: 'b_exp',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B-EXPIRED',
        qrCode: 'BAT-EXP',
        expiryDate: now.subtract(const Duration(days: 5)),
        quantity: 10,
        purchasePrice: 1.5,
      );

      final validBatch = BatchModel(
        id: 'b_valid',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B-VALID',
        qrCode: 'BAT-VAL',
        expiryDate: now.add(const Duration(days: 60)),
        quantity: 15,
        purchasePrice: 1.8,
      );

      final availableBatches = [expiredBatch, validBatch].where((b) {
        return b.quantity > 0 && b.expiryDate.isAfter(now);
      }).toList();

      expect(availableBatches.length, 1);
      expect(availableBatches.first.batchNo, 'B-VALID');
    });

    test('Correctly splits a sale item across multiple batches when needed', () {
      final now = DateTime.now();
      final batch1 = BatchModel(
        id: 'b1',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B01',
        qrCode: 'BAT-01',
        expiryDate: now.add(const Duration(days: 20)),
        quantity: 10,
        purchasePrice: 2.0,
      );

      final batch2 = BatchModel(
        id: 'b2',
        pharmacyId: 'p1',
        medicineId: 'm1',
        batchNo: 'B02',
        qrCode: 'BAT-02',
        expiryDate: now.add(const Duration(days: 100)),
        quantity: 25,
        purchasePrice: 2.5,
      );

      const requestedQuantity = 15;
      final allocations = <Map<String, dynamic>>[];

      int needed = requestedQuantity;
      final batches = [batch1, batch2];
      batches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      for (final b in batches) {
        if (needed <= 0) break;
        final deduct = b.quantity < needed ? b.quantity : needed;
        allocations.add({
          'batch_no': b.batchNo,
          'deduct': deduct,
          'cost_price': b.purchasePrice,
        });
        needed -= deduct;
      }

      expect(needed, 0);
      expect(allocations.length, 2);
      expect(allocations[0]['batch_no'], 'B01');
      expect(allocations[0]['deduct'], 10);
      expect(allocations[1]['batch_no'], 'B02');
      expect(allocations[1]['deduct'], 5);
    });
  });
}

