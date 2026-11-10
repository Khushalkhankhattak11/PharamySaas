import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/data/auth_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return NotificationsRepository(firestore, auth, authRepo);
});

class NotificationsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthRepository _authRepo;

  NotificationsRepository(this._firestore, this._auth, this._authRepo);

  Future<List<NotificationModel>> getNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final profile = await _authRepo.getProfile(user.uid);
    final pharmacyId = profile?.pharmacyId;
    final isSuperAdmin = profile?.role.isSuperAdmin == true;

    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestoreCollections.notifications);

    if (!isSuperAdmin) {
      if (pharmacyId != null && pharmacyId.isNotEmpty) {
        query = query.where('pharmacy_id', isEqualTo: pharmacyId);
      } else {
        query = query.where('user_id', isEqualTo: user.uid);
      }
    }

    try {
      final snapshot = await query.get();
      final list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return NotificationModel.fromJson(data);
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Stream<List<NotificationModel>> streamNotifications({
    String? pharmacyId,
    String? userId,
    bool isSuperAdmin = false,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestoreCollections.notifications);

    if (!isSuperAdmin) {
      if (pharmacyId != null && pharmacyId.isNotEmpty) {
        query = query.where('pharmacy_id', isEqualTo: pharmacyId);
      } else if (userId != null && userId.isNotEmpty) {
        query = query.where('user_id', isEqualTo: userId);
      } else {
        query = query.where('user_id', isEqualTo: user.uid);
      }
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return NotificationModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <NotificationModel>[]);
  }

  Future<void> markAsRead(String id) async {
    try {
      await _firestore.collection(FirestoreCollections.notifications).doc(id).update({
        'is_read': true,
      });
    } catch (_) {}
  }

  Future<void> markAllAsRead({
    String? pharmacyId,
    String? userId,
    bool isSuperAdmin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.notifications)
        .where('is_read', isEqualTo: false);

    if (!isSuperAdmin) {
      if (pharmacyId != null && pharmacyId.isNotEmpty) {
        query = query.where('pharmacy_id', isEqualTo: pharmacyId);
      } else if (userId != null && userId.isNotEmpty) {
        query = query.where('user_id', isEqualTo: userId);
      } else {
        query = query.where('user_id', isEqualTo: user.uid);
      }
    }

    try {
      final snapshot = await query.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> saveDeviceToken({
    required String fcmToken,
    required String platform,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('device_tokens').doc(user.uid).set({
        'user_id': user.uid,
        'fcm_token': fcmToken,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
