import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/medicine_model.dart';

void main() {
  group('QR & Barcode Code Lookup Matching Tests', () {
    const sampleMedicine = MedicineModel(
      id: 'med_001',
      pharmacyId: 'ph_001',
      name: 'Amoxicillin 500mg',
      barcode: '8901234567890',
      qrCode: 'MED-AMX500',
      salePrice: 6.0,
      isActive: true,
    );

    test('Matches medicine by system-generated unique QR code', () {
      const scannedCode = 'MED-AMX500';
      final matches = (sampleMedicine.qrCode == scannedCode) ||
          (sampleMedicine.barcode == scannedCode);

      expect(matches, true);
    });

    test('Matches medicine by manufacturer barcode', () {
      const scannedCode = '8901234567890';
      final matches = (sampleMedicine.qrCode == scannedCode) ||
          (sampleMedicine.barcode == scannedCode);

      expect(matches, true);
    });

    test('Trims whitespace when scanning codes', () {
      const scannedWithWhitespace = '  MED-AMX500 \n';
      final trimmed = scannedWithWhitespace.trim();

      expect(trimmed, 'MED-AMX500');
      expect(sampleMedicine.qrCode, trimmed);
    });
  });
}

