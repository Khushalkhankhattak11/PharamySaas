import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/pharmacy_registration_repository.dart';

class PharmacyRegistrationController extends StateNotifier<AsyncValue<void>> {
  final PharmacyRegistrationRepository _repository;
  final Ref _ref;

  PharmacyRegistrationController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> registerPharmacy({
    required String name,
    required String registrationNumber,
    required String drugSaleLicense,
    required String ownerName,
    required String pharmacistName,
    required String pharmacistRegistration,
    required String cnic,
    required String phone,
    required String email,
    required String province,
    required String city,
    required String address,
    required DateTime licenseIssueDate,
    required DateTime licenseExpiryDate,
    Uint8List? licenseDocBytes,
    String? licenseDocName,
    Uint8List? logoBytes,
    String? logoName,
    String currency = 'Rs',
  }) async {
    state = const AsyncValue.loading();
    try {
      String? licenseDocUrl;
      if (licenseDocBytes != null && licenseDocName != null) {
        final path = 'licenses/${DateTime.now().millisecondsSinceEpoch}_$licenseDocName';
        licenseDocUrl = await _repository.uploadFile(
          bucket: 'pharmacy-docs',
          path: path,
          bytes: licenseDocBytes,
          contentType: 'application/octet-stream',
        );
      }

      String? logoUrl;
      if (logoBytes != null && logoName != null) {
        final path = 'logos/${DateTime.now().millisecondsSinceEpoch}_$logoName';
        logoUrl = await _repository.uploadFile(
          bucket: 'pharmacy-logos',
          path: path,
          bytes: logoBytes,
          contentType: 'image/png',
        );
      }

      await _repository.registerPharmacy(
        name: name,
        registrationNumber: registrationNumber,
        drugSaleLicense: drugSaleLicense,
        ownerName: ownerName,
        pharmacistName: pharmacistName,
        pharmacistRegistration: pharmacistRegistration,
        cnic: cnic,
        phone: phone,
        email: email,
        province: province,
        city: city,
        address: address,
        licenseIssueDate: licenseIssueDate,
        licenseExpiryDate: licenseExpiryDate,
        licenseDocUrl: licenseDocUrl,
        logoUrl: logoUrl,
        currency: currency,
      );

      _ref.invalidate(currentProfileProvider);
      _ref.invalidate(currentPharmacyProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final pharmacyRegistrationControllerProvider =
    StateNotifierProvider<PharmacyRegistrationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(pharmacyRegistrationRepositoryProvider);
  return PharmacyRegistrationController(repo, ref);
});
