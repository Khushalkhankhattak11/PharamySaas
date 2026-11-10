import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/notifications_repository.dart';

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final profile = ref.watch(currentProfileProvider).value;
  final repo = ref.watch(notificationsRepositoryProvider);

  return repo.streamNotifications(
    pharmacyId: profile?.pharmacyId,
    userId: profile?.id,
    isSuperAdmin: profile?.role.isSuperAdmin == true,
  );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncVal = ref.watch(notificationsStreamProvider);
  final notifications = asyncVal.valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationsFilterProvider = StateProvider<String>((ref) => 'all');

final filteredNotificationsProvider =
    Provider<List<NotificationModel>>((ref) {
  final asyncVal = ref.watch(notificationsStreamProvider);
  final list = asyncVal.valueOrNull ?? [];
  final filter = ref.watch(notificationsFilterProvider);

  switch (filter) {
    case 'unread':
      return list.where((n) => !n.isRead).toList();
    case 'stock':
      return list
          .where((n) =>
              n.type == AppNotificationType.lowStock ||
              n.type == AppNotificationType.expiringSoon ||
              n.type == AppNotificationType.expired)
          .toList();
    case 'system':
      return list
          .where((n) =>
              n.type == AppNotificationType.newPharmacy ||
              n.type == AppNotificationType.pharmacyApproved ||
              n.type == AppNotificationType.pharmacyRejected ||
              n.type == AppNotificationType.pharmacySuspended)
          .toList();
    case 'all':
    default:
      return list;
  }
});

class NotificationsActionController extends StateNotifier<AsyncValue<void>> {
  final NotificationsRepository _repository;
  final Ref _ref;

  NotificationsActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      final profile = _ref.read(currentProfileProvider).value;
      await _repository.markAllAsRead(
        pharmacyId: profile?.pharmacyId,
        userId: profile?.id,
        isSuperAdmin: profile?.role.isSuperAdmin == true,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationsActionControllerProvider =
    StateNotifierProvider<NotificationsActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsActionController(repo, ref);
});
