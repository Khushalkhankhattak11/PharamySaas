import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/batch_model.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/inventory_repository.dart';

final inventorySearchProvider = StateProvider<String>((ref) => '');
final inventoryFilterProvider = StateProvider<String>((ref) => 'all');

final medicinesListProvider = StreamProvider<List<MedicineModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(inventoryRepositoryProvider);
  final search = ref.watch(inventorySearchProvider);
  final filter = ref.watch(inventoryFilterProvider);

  yield* repo.watchMedicines(
    pharmacyId: profile.pharmacyId!,
    search: search,
    filter: filter,
  );
});

final medicineDetailProvider =
    FutureProvider.family<MedicineModel?, String>((ref, id) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return await repo.getMedicineById(id);
});

final medicineBatchesProvider =
    FutureProvider.family<List<BatchModel>, String>((ref, medicineId) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return await repo.getBatches(medicineId);
});

class InventoryActionController extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  InventoryActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<MedicineModel> createMedicine({
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
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('No active pharmacy');
      }

      final created = await _repository.createMedicine(
        pharmacyId: profile.pharmacyId!,
        name: name,
        brandName: brandName,
        registrationNumber: registrationNumber,
        genericName: genericName,
        category: category,
        manufacturer: manufacturer,
        barcode: barcode,
        customQrCode: customQrCode,
        unit: unit,
        salePrice: salePrice,
        discountPercent: discountPercent,
        minStockLevel: minStockLevel,
        initialStock: initialStock,
        purchasePrice: purchasePrice,
        expiryDate: expiryDate,
        imageUrl: imageUrl,
      );

      _ref.invalidate(medicinesListProvider);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMedicine({
    required String medicineId,
    required String name,
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
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      await _repository.updateMedicine(
        medicineId: medicineId,
        pharmacyId: profile?.pharmacyId,
        name: name,
        brandName: brandName,
        registrationNumber: registrationNumber,
        genericName: genericName,
        category: category,
        manufacturer: manufacturer,
        barcode: barcode,
        qrCode: qrCode,
        unit: unit,
        salePrice: salePrice,
        discountPercent: discountPercent,
        minStockLevel: minStockLevel,
        imageUrl: imageUrl,
      );

      _ref.invalidate(medicinesListProvider);
      _ref.invalidate(medicineDetailProvider(medicineId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleMedicineActive({
    required String medicineId,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      await _repository.setMedicineActive(
        medicineId: medicineId,
        isActive: isActive,
        pharmacyId: profile?.pharmacyId,
      );
      _ref.invalidate(medicinesListProvider);
      _ref.invalidate(medicineDetailProvider(medicineId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> adjustStock({
    required String batchId,
    required String medicineId,
    required int quantityChange,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('No active pharmacy');
      }

      await _repository.createStockAdjustment(
        pharmacyId: profile.pharmacyId!,
        batchId: batchId,
        quantityChange: quantityChange,
        reason: reason,
      );

      _ref.invalidate(medicinesListProvider);
      _ref.invalidate(medicineDetailProvider(medicineId));
      _ref.invalidate(medicineBatchesProvider(medicineId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> assignBarcode({
    required String medicineId,
    required String barcode,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignBarcodeToMedicine(
        medicineId: medicineId,
        barcode: barcode,
      );
      _ref.invalidate(medicinesListProvider);
      _ref.invalidate(medicineDetailProvider(medicineId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final inventoryActionControllerProvider =
    StateNotifierProvider<InventoryActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventoryActionController(repo, ref);
});
