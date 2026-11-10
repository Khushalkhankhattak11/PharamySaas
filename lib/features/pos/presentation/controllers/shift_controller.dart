import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/cash_shift_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/shift_repository.dart';

final shiftFilterCashierIdProvider = StateProvider<String?>((ref) => null);
final shiftFilterStatusProvider = StateProvider<String>((ref) => 'all');

/// Real-time stream of the current cashier's active open shift
final currentCashierShiftProvider = StreamProvider<CashShiftModel?>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield null;
    return;
  }

  final repo = ref.watch(shiftRepositoryProvider);
  yield* repo.watchActiveShift(
    pharmacyId: profile.pharmacyId!,
    cashierId: profile.id,
  );
});

/// Real-time stream of all shifts for Admin review and staff progress
final pharmacyShiftsStreamProvider = StreamProvider<List<CashShiftModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }

  final cashierId = ref.watch(shiftFilterCashierIdProvider);
  final status = ref.watch(shiftFilterStatusProvider);
  final repo = ref.watch(shiftRepositoryProvider);

  yield* repo.watchAllShifts(
    pharmacyId: profile.pharmacyId!,
    cashierId: cashierId,
    statusFilter: status,
  );
});

class ShiftActionController extends StateNotifier<AsyncValue<void>> {
  final ShiftRepository _repository;
  final Ref _ref;

  ShiftActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<CashShiftModel> openShift({
    required double openingCash,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('User profile or pharmacy not found');
      }

      final shift = await _repository.openShift(
        pharmacyId: profile.pharmacyId!,
        cashierId: profile.id,
        cashierName: profile.fullName,
        openingCash: openingCash,
        openingNote: note,
      );

      _ref.invalidate(currentCashierShiftProvider);
      _ref.invalidate(pharmacyShiftsStreamProvider);
      state = const AsyncValue.data(null);
      return shift;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<CashShiftModel> closeShift({
    required String shiftId,
    required double actualClosingCash,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile == null || profile.pharmacyId == null) {
        throw Exception('User profile or pharmacy not found');
      }

      final shift = await _repository.closeShift(
        shiftId: shiftId,
        pharmacyId: profile.pharmacyId!,
        actualClosingCash: actualClosingCash,
        closingNote: note,
      );

      _ref.invalidate(currentCashierShiftProvider);
      _ref.invalidate(pharmacyShiftsStreamProvider);
      state = const AsyncValue.data(null);
      return shift;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final shiftActionControllerProvider =
    StateNotifierProvider<ShiftActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  return ShiftActionController(repo, ref);
});

