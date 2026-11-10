import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../data/super_admin_repository.dart';

final platformStatsProvider = FutureProvider<PlatformStatsModel>((ref) async {
  final repo = ref.watch(superAdminRepositoryProvider);
  return await repo.getPlatformStats();
});

final pendingApprovalsProvider = StreamProvider<List<PharmacyModel>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.watchPendingPharmacies();
});

final planUpgradeRequestsProvider = StreamProvider<List<PharmacyModel>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.watchPlanUpgradeRequests();
});

final pharmacyFilterStatusProvider = StateProvider<String>((ref) => 'all');
final pharmacySearchQueryProvider = StateProvider<String>((ref) => '');

final allPharmaciesProvider = StreamProvider<List<PharmacyModel>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  final status = ref.watch(pharmacyFilterStatusProvider);
  final query = ref.watch(pharmacySearchQueryProvider);
  return repo.watchAllPharmacies(status: status, search: query);
});

class SuperAdminActionController extends StateNotifier<AsyncValue<void>> {
  final SuperAdminRepository _repository;
  final Ref _ref;

  SuperAdminActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> reviewPharmacy({
    required String pharmacyId,
    required String action,
    String? reason,
    String? plan,
    int extendDays = 365,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.reviewPharmacy(
        pharmacyId: pharmacyId,
        action: action,
        reason: reason,
        plan: plan,
        extendDays: extendDays,
      );
      _ref.invalidate(platformStatsProvider);
      _ref.invalidate(pendingApprovalsProvider);
      _ref.invalidate(allPharmaciesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateSubscription({
    required String pharmacyId,
    required String plan,
    required DateTime expiresAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSubscriptionPlan(
        pharmacyId: pharmacyId,
        plan: plan,
        expiresAt: expiresAt,
      );
      _ref.invalidate(platformStatsProvider);
      _ref.invalidate(allPharmaciesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addPharmacy({
    required String name,
    required String ownerEmail,
    required String ownerPassword,
    String? ownerFullName,
    String? ownerName,
    String? registrationNumber,
    String? drugSaleLicense,
    String? pharmacistName,
    String? pharmacistRegistration,
    String? cnic,
    String? province,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? address,
    String? city,
    String? phone,
    String? licenseNo,
    String currency = 'Rs',
    String plan = 'Standard',
    int planDays = 365,
    String approvalStatus = 'approved',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addPharmacy(
        name: name,
        ownerEmail: ownerEmail,
        ownerPassword: ownerPassword,
        ownerFullName: ownerFullName,
        ownerName: ownerName,
        registrationNumber: registrationNumber,
        drugSaleLicense: drugSaleLicense,
        pharmacistName: pharmacistName,
        pharmacistRegistration: pharmacistRegistration,
        cnic: cnic,
        province: province,
        licenseIssueDate: licenseIssueDate,
        licenseExpiryDate: licenseExpiryDate,
        address: address,
        city: city,
        phone: phone,
        licenseNo: licenseNo,
        currency: currency,
        plan: plan,
        planDays: planDays,
        approvalStatus: approvalStatus,
      );
      _ref.invalidate(platformStatsProvider);
      _ref.invalidate(pendingApprovalsProvider);
      _ref.invalidate(allPharmaciesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePharmacy({
    required String pharmacyId,
    required String name,
    String? ownerName,
    String? registrationNumber,
    String? drugSaleLicense,
    String? pharmacistName,
    String? pharmacistRegistration,
    String? cnic,
    String? email,
    String? province,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? address,
    String? city,
    String? phone,
    String? licenseNo,
    required String currency,
    String? plan,
    DateTime? planExpiresAt,
    String? approvalStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePharmacy(
        pharmacyId: pharmacyId,
        name: name,
        ownerName: ownerName,
        registrationNumber: registrationNumber,
        drugSaleLicense: drugSaleLicense,
        pharmacistName: pharmacistName,
        pharmacistRegistration: pharmacistRegistration,
        cnic: cnic,
        email: email,
        province: province,
        licenseIssueDate: licenseIssueDate,
        licenseExpiryDate: licenseExpiryDate,
        address: address,
        city: city,
        phone: phone,
        licenseNo: licenseNo,
        currency: currency,
        plan: plan,
        planExpiresAt: planExpiresAt,
        approvalStatus: approvalStatus,
      );
      _ref.invalidate(platformStatsProvider);
      _ref.invalidate(pendingApprovalsProvider);
      _ref.invalidate(allPharmaciesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> acceptPlanUpgrade({
    required String pharmacyId,
    required String plan,
    int planDays = 365,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptPlanUpgrade(
        pharmacyId: pharmacyId,
        plan: plan,
        planDays: planDays,
      );
      _ref.invalidate(allPharmaciesProvider);
      _ref.invalidate(pendingApprovalsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> rejectPlanUpgrade({
    required String pharmacyId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectPlanUpgrade(pharmacyId: pharmacyId);
      _ref.invalidate(allPharmaciesProvider);
      _ref.invalidate(pendingApprovalsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePharmacy(pharmacyId);
      _ref.invalidate(platformStatsProvider);
      _ref.invalidate(pendingApprovalsProvider);
      _ref.invalidate(allPharmaciesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final superAdminActionControllerProvider =
    StateNotifierProvider<SuperAdminActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return SuperAdminActionController(repo, ref);
});
