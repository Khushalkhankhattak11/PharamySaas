import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pharmcysas/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:pharmcysas/features/pos/data/pos_repository.dart';
import 'package:pharmcysas/features/pos/presentation/screens/pos_screen.dart';
import 'package:pharmcysas/shared/models/approval_status.dart';
import 'package:pharmcysas/shared/models/cart_item_model.dart';
import 'package:pharmcysas/shared/models/medicine_model.dart';
import 'package:pharmcysas/shared/models/pharmacy_model.dart';
import 'package:pharmcysas/shared/models/sale_model.dart';

class FakePosRepository implements PosRepository {
  @override
  Future<SaleModel> createSale({
    required List<CartItemModel> items,
    required double discount,
    required String paymentMethod,
    required String customerName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> lookupByCode(String code) async {
    return {'found': false};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('POS Screen renders search bar, scan button, and empty cart correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sampleMedicine = MedicineModel(
      id: 'med_test_1',
      pharmacyId: 'ph_test',
      name: 'Paracetamol 500mg',
      qrCode: 'MED-PAN500',
      salePrice: 2.50,
      availableStock: 50,
      isActive: true,
    );

    const samplePharmacy = PharmacyModel(
      id: 'ph_test',
      name: 'Test Pharmacy',
      currency: 'USD',
      approvalStatus: ApprovalStatus.approved,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posRepositoryProvider.overrideWithValue(FakePosRepository()),
          currentPharmacyProvider.overrideWith((ref) => Future.value(samplePharmacy)),
          medicinesListProvider.overrideWith((ref) => Stream.value([sampleMedicine])),
        ],
        child: const MaterialApp(
          home: PosScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Search Bar
    expect(find.text('Point of Sale (POS)'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Scan'), findsOneWidget);

    // Verify medicine rendered
    expect(find.text('Paracetamol 500mg'), findsOneWidget);

    // Verify cart panel
    expect(find.text('Active Cart'), findsOneWidget);
    expect(find.text('Cart is empty'), findsOneWidget);
  });
}
