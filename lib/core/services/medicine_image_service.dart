import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/firebase_providers.dart';

final medicineImageServiceProvider = Provider<MedicineImageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return MedicineImageService(storage);
});

class MedicineImageService {
  final FirebaseStorage? _storage;
  final ImagePicker _picker = ImagePicker();

  MedicineImageService([this._storage]);

  Future<XFile?> captureMedicinePhoto({ImageSource source = ImageSource.camera}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadOrEncodeImage({
    required String pharmacyId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // 1. Try Firebase Storage upload if storage is initialized
    if (_storage != null) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_');
        final ref = _storage.ref('pharmacies/$pharmacyId/medicines/${timestamp}_$sanitized');
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } catch (_) {
        // Fall through to Base64 data URL fallback
      }
    }

    // 2. Base64 fallback (safe for offline or unconfigured Firebase Storage)
    if (bytes.lengthInBytes <= 2 * 1024 * 1024) {
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }

    return null;
  }
}

