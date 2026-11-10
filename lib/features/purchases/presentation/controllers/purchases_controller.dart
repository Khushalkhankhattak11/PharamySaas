import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/purchase_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/purchases_repository.dart';

final purchasesListProvider = StreamProvider<List<PurchaseModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(purchasesRepositoryProvider);
  yield* repo.watchPurchases(profile.pharmacyId!);
});

class PurchasesActionController extends StateNotifier<AsyncValue<void>> {
  final PurchasesRepository _repository;
  final Ref _ref;

  PurchasesActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<PurchaseModel> recordPurchase({
    String? supplierId,
    String? invoiceNo,
    required List<PurchaseLineItem> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('No active pharmacy');
      }

      final purchase = await _repository.recordStockInPurchase(
        pharmacyId: profile.pharmacyId!,
        supplierId: supplierId,
        invoiceNo: invoiceNo,
        items: items,
      );

      _ref.invalidate(purchasesListProvider);
      _ref.invalidate(medicinesListProvider);
      state = const AsyncValue.data(null);
      return purchase;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final purchasesActionControllerProvider =
    StateNotifierProvider<PurchasesActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(purchasesRepositoryProvider);
  return PurchasesActionController(repo, ref);
});

