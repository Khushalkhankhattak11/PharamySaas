import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/profile_model.dart';
import '../../../../shared/models/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/staff_repository.dart';

final staffListProvider = StreamProvider<List<ProfileModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }
  final repo = ref.watch(staffRepositoryProvider);
  yield* repo.watchStaff(profile.pharmacyId!);
});

class StaffActionController extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repository;
  final Ref _ref;

  StaffActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createStaff({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required UserRole role,
    String? shiftStart,
    String? shiftEnd,
    String? shiftLabel,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createStaff(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        shiftLabel: shiftLabel,
      );
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStaff({
    required String staffId,
    required String fullName,
    String? phone,
    required UserRole role,
    String? shiftStart,
    String? shiftEnd,
    String? shiftLabel,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateStaff(
        staffId: staffId,
        fullName: fullName,
        phone: phone,
        role: role,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        shiftLabel: shiftLabel,
      );
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleStaffStatus({
    required String staffId,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleStaffStatus(staffId: staffId, isActive: isActive);
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteStaff({
    required String staffId,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteStaff(staffId: staffId, role: role);
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetStaffPassword(
        staffId: staffId,
        newPassword: newPassword,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final staffActionControllerProvider =
    StateNotifierProvider<StaffActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(staffRepositoryProvider);
  return StaffActionController(repo, ref);
});
