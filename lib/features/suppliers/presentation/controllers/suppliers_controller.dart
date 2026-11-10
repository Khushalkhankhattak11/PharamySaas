import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/supplier_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/suppliers_repository.dart';

final suppliersListProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) return [];

  final repo = ref.watch(suppliersRepositoryProvider);
  return await repo.getSuppliers(profile.pharmacyId!);
});

class SuppliersActionController extends StateNotifier<AsyncValue<void>> {
  final SuppliersRepository _repository;
  final Ref _ref;

  SuppliersActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createSupplier({
    required String name,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('No active pharmacy');
      }

      await _repository.createSupplier(
        pharmacyId: profile.pharmacyId!,
        name: name,
        phone: phone,
        address: address,
      );

      _ref.invalidate(suppliersListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateSupplier({
    required String supplierId,
    required String name,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSupplier(
        supplierId: supplierId,
        name: name,
        phone: phone,
        address: address,
      );

      _ref.invalidate(suppliersListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSupplier(supplierId);
      _ref.invalidate(suppliersListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final suppliersActionControllerProvider =
    StateNotifierProvider<SuppliersActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(suppliersRepositoryProvider);
  return SuppliersActionController(repo, ref);
});

