import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/constants/standard_medicine_catalog.dart';
import 'package:pharmcysas/shared/models/medicine_model.dart';

void main() {
  group('Standard Pakistan Medicine Catalog Tests', () {
    test('Contains standard Pakistani medicines across all categories', () {
      expect(StandardMedicineCatalog.items.isNotEmpty, true);
      expect(StandardMedicineCatalog.categories.contains('Injections'), true);
      expect(StandardMedicineCatalog.categories.contains('Syrups & Liquids'), true);
      expect(StandardMedicineCatalog.categories.contains('Pain & Fever'), true);
      expect(StandardMedicineCatalog.categories.contains('Antibiotics'), true);

      // Verify specific Pakistani favorites
      final panadol = StandardMedicineCatalog.items.firstWhere((m) => m.name.contains('Panadol 500mg'));
      expect(panadol.genericName, 'Paracetamol');
      expect(panadol.manufacturer, 'GSK');
      expect(panadol.imageUrl, isNotNull);

      final rocephin = StandardMedicineCatalog.items.firstWhere((m) => m.name.contains('Rocephin'));
      expect(rocephin.category, 'Injections');
      expect(rocephin.genericName, contains('Ceftriaxone'));

      final calpol = StandardMedicineCatalog.items.firstWhere((m) => m.name.contains('Calpol'));
      expect(calpol.category, 'Syrups & Liquids');
    });

    test('MedicineModel serializes and deserializes imageUrl correctly', () {
      const med = MedicineModel(
        id: 'med_test_1',
        pharmacyId: 'pharm_1',
        name: 'Panadol 500mg',
        genericName: 'Paracetamol',
        category: 'Pain & Fever',
        manufacturer: 'GSK',
        barcode: '896400012011',
        qrCode: 'MED-12345678',
        unit: 'Strip',
        salePrice: 35.0,
        discountPercent: 5.0,
        isActive: true,
        imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
      );

      final json = med.toJson();
      expect(json['image_url'], 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300');
      expect(med.effectivePrice, closeTo(33.25, 0.01));

      final fromJson = MedicineModel.fromJson(json);
      expect(fromJson.imageUrl, 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300');
      expect(fromJson.name, 'Panadol 500mg');
    });
  });
}

