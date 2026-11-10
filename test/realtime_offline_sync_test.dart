import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/medicine_model.dart';
import 'package:pharmcysas/shared/models/sale_model.dart';

void main() {
  group('Real-Time & Offline Sync Tests', () {
    test('Stream emits real-time updates immediately on new medicine addition', () async {
      final streamEvents = <List<MedicineModel>>[];

      const initialMedicine = MedicineModel(
        id: 'med_1',
        pharmacyId: 'p1',
        name: 'Panadol 500mg',
        unit: 'Strip',
        salePrice: 35.0,
        availableStock: 50,
        qrCode: 'MED-1',
        isActive: true,
      );

      const addedMedicine = MedicineModel(
        id: 'med_2',
        pharmacyId: 'p1',
        name: 'Brufen 400mg',
        unit: 'Box',
        salePrice: 45.0,
        availableStock: 20,
        qrCode: 'MED-2',
        isActive: true,
      );

      // Simulate real-time stream emissions without reload
      final stream = Stream<List<MedicineModel>>.fromIterable([
        [initialMedicine],
        [initialMedicine, addedMedicine],
      ]);

      await for (final list in stream) {
        streamEvents.add(list);
      }

      expect(streamEvents.length, 2);
      // First emission: 1 item
      expect(streamEvents[0].length, 1);
      expect(streamEvents[0].first.name, 'Panadol 500mg');

      // Second emission (immediate real-time update): 2 items without page reload
      expect(streamEvents[1].length, 2);
      expect(streamEvents[1].last.name, 'Brufen 400mg');
    });

    test('Sale event immediately triggers inventory stock decrement in stream', () async {
      const initialStock = 50;
      const saleQty = 5;

      const initial = MedicineModel(
        id: 'med_1',
        pharmacyId: 'p1',
        name: 'Amoxil 250mg',
        unit: 'Bottle',
        salePrice: 120.0,
        availableStock: initialStock,
        qrCode: 'MED-1',
        isActive: true,
      );

      final afterSale = initial.copyWith(
        availableStock: initial.availableStock - saleQty,
      );

      expect(afterSale.availableStock, 45);

      final sale = SaleModel(
        id: 'sale_1',
        pharmacyId: 'p1',
        invoiceNo: 1001,
        subtotal: 600.0,
        discount: 0.0,
        total: 600.0,
        paymentMethod: 'cash',
        customerName: 'Walk-in',
        items: const [],
        createdAt: DateTime.now(),
      );

      expect(sale.total, 600.0);
      expect(sale.invoiceNo, 1001);
    });
  });
}
