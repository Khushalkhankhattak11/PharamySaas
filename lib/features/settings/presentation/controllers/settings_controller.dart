import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/settings_repository.dart';

final defaultPrinterProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getPrinterType();
});

class SettingsActionController extends StateNotifier<AsyncValue<void>> {
  final SettingsRepository _repository;
  final Ref _ref;

  SettingsActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updatePharmacy({
    required String name,
    String? address,
    String? city,
    String? phone,
    required String currency,
    String? receiptHeader,
    String? receiptFooter,
    String? ownerFullName,
    String? ownerPhone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final pharmacy = await _ref.read(currentPharmacyProvider.future);
      if (pharmacy == null) throw Exception('No active pharmacy');

      await _repository.updatePharmacySettings(
        pharmacyId: pharmacy.id,
        name: name,
        address: address,
        city: city,
        phone: phone,
        currency: currency,
        receiptHeader: receiptHeader,
        receiptFooter: receiptFooter,
      );

      final profile = await _ref.read(currentProfileProvider.future);
      if (profile != null && ownerFullName != null && ownerFullName.trim().isNotEmpty) {
        await _repository.updateUserProfile(
          userId: profile.id,
          fullName: ownerFullName,
          phone: ownerPhone,
        );
      }

      _ref.invalidate(currentPharmacyProvider);
      _ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> requestPlanUpgrade({
    required String plan,
    int planDays = 365,
  }) async {
    state = const AsyncValue.loading();
    try {
      final pharmacy = await _ref.read(currentPharmacyProvider.future);
      if (pharmacy == null) throw Exception('No active pharmacy');

      await _repository.requestPlanUpgrade(
        pharmacyId: pharmacy.id,
        plan: plan,
        planDays: planDays,
      );

      _ref.invalidate(currentPharmacyProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelPlanUpgradeRequest() async {
    state = const AsyncValue.loading();
    try {
      final pharmacy = await _ref.read(currentPharmacyProvider.future);
      if (pharmacy == null) throw Exception('No active pharmacy');

      await _repository.cancelPlanUpgradeRequest(
        pharmacyId: pharmacy.id,
      );

      _ref.invalidate(currentPharmacyProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setPrinterType(String printerType) async {
    await _repository.savePrinterType(printerType);
    _ref.invalidate(defaultPrinterProvider);
  }
}

final settingsActionControllerProvider =
    StateNotifierProvider<SettingsActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsActionController(repo, ref);
});
