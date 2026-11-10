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

  /// Automatically inspects medicine stocks and batch expiry dates for a pharmacy.
  /// Generates real-time notifications for:
  /// 1. Low stock medicines (available_stock <= min_stock_level)
  /// 2. Batches expiring within 10 days (daysUntilExpiry <= 10)
  /// 3. Batches that have expired (daysUntilExpiry < 0)
  /// Automatically de-duplicates alerts so notifications are not recreated redundantly.
  Future<void> checkAndGenerateInventoryAlerts({
    required String pharmacyId,
    String? ownerUserId,
  }) async {
    if (pharmacyId.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    try {
      // 1. Fetch recent notifications for this pharmacy to deduplicate
      final existingNotifsSnap = await _firestore
          .collection(FirestoreCollections.notifications)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .get();

      final Set<String> existingAlertKeys = {};
      for (final doc in existingNotifsSnap.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final isRead = data['is_read'] as bool? ?? false;
        final createdAtStr = data['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        final isRecent = createdAt != null && createdAt.isAfter(twentyFourHoursAgo);

        // Deduplicate if unread OR generated within last 24 hours
        if (!isRead || isRecent) {
          if (type == 'low_stock') {
            final medId = data['medicine_id'] as String?;
            if (medId != null && medId.isNotEmpty) {
              existingAlertKeys.add('low_stock:$medId');
            }
          } else if (type == 'expiring_soon') {
            final batchId = data['batch_id'] as String?;
            if (batchId != null && batchId.isNotEmpty) {
              existingAlertKeys.add('expiring_soon:$batchId');
            }
          } else if (type == 'expired') {
            final batchId = data['batch_id'] as String?;
            if (batchId != null && batchId.isNotEmpty) {
              existingAlertKeys.add('expired:$batchId');
            }
          }
        }
      }

      final List<Map<String, dynamic>> newNotifications = [];

      // 2. CHECK LOW STOCK MEDICINES
      final Map<String, Map<String, dynamic>> medicineMap = {};
      final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

      try {
        final snap = await pharmacyDoc
            .collection(FirestoreCollections.products)
            .where('is_active', isEqualTo: true)
            .get();
        for (final d in snap.docs) {
          medicineMap[d.id] = d.data();
        }
      } catch (_) {}

      try {
        final snap = await _firestore
            .collection(FirestoreCollections.medicines)
            .where('pharmacy_id', isEqualTo: pharmacyId)
            .where('is_active', isEqualTo: true)
            .get();
        for (final d in snap.docs) {
          if (!medicineMap.containsKey(d.id)) {
            medicineMap[d.id] = d.data();
          }
        }
      } catch (_) {}

      for (final entry in medicineMap.entries) {
        final medId = entry.key;
        final data = entry.value;
        final name = (data['name'] as String?)?.trim() ?? 'Medicine';
        final stock = (data['available_stock'] as num?)?.toInt() ?? 0;
        final minLevel = (data['min_stock_level'] as num?)?.toInt() ?? 10;
        final unit = (data['unit'] as String?)?.trim() ?? 'units';

        if (stock <= minLevel) {
          final alertKey = 'low_stock:$medId';
          if (!existingAlertKeys.contains(alertKey)) {
            existingAlertKeys.add(alertKey);
            newNotifications.add({
              'pharmacy_id': pharmacyId,
              'target_role': 'owner',
              if (ownerUserId != null && ownerUserId.isNotEmpty) 'target_user_id': ownerUserId,
              'type': 'low_stock',
              'title': 'Low Stock Alert: $name',
              'message': '$name has only $stock $unit remaining, which is at or below the minimum threshold of $minLevel $unit.',
              'medicine_id': medId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      // 3. CHECK BATCH EXPIRY DATES (<= 10 days & expired)
      final batchSnap = await _firestore
          .collection(FirestoreCollections.batches)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .get();

      final Map<String, Map<String, dynamic>> allBatches = {};
      for (final doc in batchSnap.docs) {
        allBatches[doc.id] = doc.data();
      }

      try {
        final subBatchSnap = await pharmacyDoc.collection(FirestoreCollections.batches).get();
        for (final doc in subBatchSnap.docs) {
          if (!allBatches.containsKey(doc.id)) {
            allBatches[doc.id] = doc.data();
          }
        }
      } catch (_) {}

      for (final entry in allBatches.entries) {
        final batchId = entry.key;
        final bData = entry.value;
        final qty = (bData['quantity'] as num?)?.toInt() ?? 0;
        final expiryStr = bData['expiry_date'] as String?;
        final medId = bData['medicine_id'] as String?;
        final batchNo = (bData['batch_no'] as String?)?.trim() ?? 'Unknown';

        if (qty <= 0 || expiryStr == null || medId == null) continue;

        final expDate = DateTime.tryParse(expiryStr);
        if (expDate == null) continue;

        final expDay = DateTime(expDate.year, expDate.month, expDate.day);
        final daysUntilExpiry = expDay.difference(today).inDays;
        final medName = (medicineMap[medId]?['name'] as String?) ?? 'Medicine';
        final expiryDateFormatted =
            '${expDay.day.toString().padLeft(2, '0')}/${expDay.month.toString().padLeft(2, '0')}/${expDay.year}';

        // Check expired
        if (daysUntilExpiry < 0) {
          final alertKey = 'expired:$batchId';
          if (!existingAlertKeys.contains(alertKey)) {
            existingAlertKeys.add(alertKey);
            final daysAgo = daysUntilExpiry.abs();
            newNotifications.add({
              'pharmacy_id': pharmacyId,
              'target_role': 'owner',
              if (ownerUserId != null && ownerUserId.isNotEmpty) 'target_user_id': ownerUserId,
              'type': 'expired',
              'title': 'Expired Batch: $medName',
              'message': 'Batch $batchNo of $medName ($qty units) expired $daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago on $expiryDateFormatted. Please remove from active stock immediately.',
              'medicine_id': medId,
              'batch_id': batchId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
        // Check expiring within 10 days
        else if (daysUntilExpiry <= 10) {
          final alertKey = 'expiring_soon:$batchId';
          if (!existingAlertKeys.contains(alertKey)) {
            existingAlertKeys.add(alertKey);
            final daysText = daysUntilExpiry == 0
                ? 'today'
                : 'in $daysUntilExpiry ${daysUntilExpiry == 1 ? 'day' : 'days'}';
            newNotifications.add({
              'pharmacy_id': pharmacyId,
              'target_role': 'owner',
              if (ownerUserId != null && ownerUserId.isNotEmpty) 'target_user_id': ownerUserId,
              'type': 'expiring_soon',
              'title': 'Expiring Soon: $medName',
              'message': 'Batch $batchNo of $medName ($qty units) will expire $daysText on $expiryDateFormatted. Plan to dispense or return to supplier.',
              'medicine_id': medId,
              'batch_id': batchId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      // 4. Batch write all new notifications into Firestore
      if (newNotifications.isNotEmpty) {
        final writeBatch = _firestore.batch();
        for (final notifData in newNotifications) {
          final docRef = _firestore.collection(FirestoreCollections.notifications).doc();
          notifData['id'] = docRef.id;
          writeBatch.set(docRef, notifData);
        }
        await writeBatch.commit();
      }
    } catch (_) {}
  }
}
