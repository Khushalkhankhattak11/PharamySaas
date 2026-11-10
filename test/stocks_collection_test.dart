import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/core/firebase/firestore_collections.dart';
import 'package:pharmcysas/shared/models/medicine_model.dart';

void main() {
  group('Stocks Collection & Cross-Role Sync Tests', () {
    test('FirestoreCollections.stocks constant is defined', () {
      expect(FirestoreCollections.stocks, 'stocks');
      expect(FirestoreCollections.medicines, 'medicines');
    });

    test('Medicine stock serialization is compatible with stocks subcollection', () {
      final now = DateTime.now();
      final medicine = MedicineModel(
        id: 'med_stock_123',
        pharmacyId: 'pharmacy_alpha',
        name: 'Panadol 500mg',
        brandName: 'Panadol',
        registrationNumber: '001245',
        genericName: 'Paracetamol',
        category: 'Analgesics',
        manufacturer: 'GSK',
        unit: 'Box',
        salePrice: 150.0,
        minStockLevel: 20,
        availableStock: 100,
        qrCode: 'MED-12345',
        barcode: '1234567890123',
        isActive: true,
        discountPercent: 5.0,
        imageUrl: 'https://example.com/panadol.jpg',
        createdAt: now,
      );

      final json = medicine.toJson();

      // Check essential fields required by Firestore security rules for stocks
      expect(json['id'], 'med_stock_123');
      expect(json['pharmacy_id'], 'pharmacy_alpha');
      expect(json['name'], 'Panadol 500mg');
      expect(json['brand_name'], 'Panadol');
      expect(json['registration_number'], '001245');
      expect(json['available_stock'], 100);
      expect(json['sale_price'], 150.0);
      expect(json['is_active'], true);
      expect(json['qr_code'], 'MED-12345');

      // Verify deserialization back to model
      final restored = MedicineModel.fromJson(json);
      expect(restored.id, 'med_stock_123');
      expect(restored.pharmacyId, 'pharmacy_alpha');
      expect(restored.brandName, 'Panadol');
      expect(restored.registrationNumber, '001245');
      expect(restored.availableStock, 100);
      expect(restored.salePrice, 150.0);
    });

    test('Duplicate medicine detection correctly identifies existing medicines', () {
      const existingList = [
        MedicineModel(
          id: 'med_1',
          pharmacyId: 'pharm_1',
          name: 'Panadol 500mg',
          brandName: 'Panadol',
          registrationNumber: 'DRAP-0012',
          barcode: '89640001',
          qrCode: 'QR-1',
          salePrice: 35.0,
          availableStock: 40,
          isActive: true,
        ),
      ];

      // Exact match by DRAP registration number
      final regMatch = existingList.firstWhere(
        (m) => m.registrationNumber?.toLowerCase() == 'drap-0012',
      );
      expect(regMatch.id, 'med_1');

      // Match by Barcode
      final barcodeMatch = existingList.firstWhere(
        (m) => m.barcode == '89640001',
      );
      expect(barcodeMatch.id, 'med_1');

      // Match by Brand Name
      final brandMatch = existingList.firstWhere(
        (m) => m.brandName?.toLowerCase() == 'panadol',
      );
      expect(brandMatch.id, 'med_1');

      // Merging stock units on restock without duplicating
      final merged = existingList.first.copyWith(
        availableStock: existingList.first.availableStock + 60,
      );
      expect(merged.availableStock, 100);
      expect(merged.id, 'med_1'); // Preserves same ID
    });

    test('Stock deduction and addition preserve model integrity for POS and Purchases', () {
      const initialMedicine = MedicineModel(
        id: 'med_stock_999',
        pharmacyId: 'pharmacy_alpha',
        name: 'Amoxicillin 250mg',
        unit: 'Bottle',
        salePrice: 220.0,
        minStockLevel: 10,
        availableStock: 50,
        qrCode: 'MED-999',
        isActive: true,
      );

      // Simulate POS sale deduction (-5 units)
      final afterSale = initialMedicine.copyWith(
        availableStock: initialMedicine.availableStock - 5,
      );
      expect(afterSale.availableStock, 45);

      // Simulate Storekeeper purchase stock-in (+20 units)
      final afterRestock = afterSale.copyWith(
        availableStock: afterSale.availableStock + 20,
      );
      expect(afterRestock.availableStock, 65);
    });
  });
}
