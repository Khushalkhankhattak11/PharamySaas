import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/models/profile_model.dart';
import '../../data/auth_repository.dart';

final authStateChangesProvider = StreamProvider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final user = repo.currentUser;
  if (user == null) return null;
  return await repo.getProfile(user.id);
});

final currentPharmacyProvider = FutureProvider<PharmacyModel?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getPharmacy(profile.pharmacyId!);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signIn(email: email, password: password);
      _ref.invalidate(currentProfileProvider);
      _ref.invalidate(currentPharmacyProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpAdmin({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signUpAdmin(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      _ref.invalidate(currentProfileProvider);
      _ref.invalidate(currentPharmacyProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});

