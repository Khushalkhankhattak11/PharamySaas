import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final streamAsync = ref.watch(notificationsStreamProvider);
    final notifications = ref.watch(filteredNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final filter = ref.watch(notificationsFilterProvider);

    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'unread', 'label': 'Unread ($unreadCount)'},
      {'id': 'stock', 'label': 'Stock & Expiry'},
      {'id': 'system', 'label': 'System Alerts'},
    ];

    if (streamAsync.isLoading && notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Row (flexible to prevent overflow on mobile)
        Row(
          children: [
            // Filter Pills
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isSelected = filter == f['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(notificationsFilterProvider.notifier)
                            .state = f['id']!,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppColorsTokens.brandGradient : null,
                            color: isSelected ? null : tokens.colors.card,
                            borderRadius:
                                BorderRadius.circular(AppRadiusTokens.pill),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : tokens.colors.line,
                            ),
                          ),
                          child: Text(
                            f['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  isSelected ? Colors.white : tokens.colors.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              AppButton.white(
                text: 'Mark All Read',
                icon: const Icon(LucideIcons.checkCheck, size: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                height: 36,
                onPressed: () {
                  ref
                      .read(notificationsActionControllerProvider.notifier)
                      .markAllAsRead();
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        if (notifications.isEmpty)
          const EmptyState(
            title: 'No Notifications',
            subtitle:
                'You are all caught up! Automated alerts will appear here.',
            icon: LucideIcons.bellOff,
          )
        else
          SectionCard(
            title: 'Alert Feed',
            subtitle: '${notifications.length} notifications in this view',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final notif = notifications[idx];
                return _NotificationTile(notif: notif);
              },
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notif;

  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    Color iconColor;
    IconData icon;

    switch (notif.type) {
      case AppNotificationType.lowStock:
        iconColor = AppColorsTokens.amber;
        icon = LucideIcons.alertTriangle;
        break;
      case AppNotificationType.expiringSoon:
        iconColor = AppColorsTokens.orange;
        icon = LucideIcons.clock;
        break;
      case AppNotificationType.expired:
        iconColor = AppColorsTokens.danger;
        icon = LucideIcons.alertOctagon;
        break;
      case AppNotificationType.pharmacyApproved:
        iconColor = AppColorsTokens.success;
        icon = LucideIcons.checkCircle2;
        break;
      case AppNotificationType.newPharmacy:
        iconColor = AppColorsTokens.info;
        icon = LucideIcons.store;
        break;
      default:
        iconColor = tokens.colors.muted;
        icon = LucideIcons.info;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        onTap: () {
          if (!notif.isRead) {
            ref
                .read(notificationsActionControllerProvider.notifier)
                .markAsRead(notif.id);
          }
          if (notif.medicineId != null && notif.medicineId!.isNotEmpty) {
            context.push('/inventory/${notif.medicineId}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? tokens.colors.card : tokens.colors.track,
            borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
            border: Border.all(
              color: notif.isRead
                  ? tokens.colors.line
                  : iconColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: tokens.colors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif.createdAt.toString().split(' ').first,
                          style:
                              TextStyle(fontSize: 11, color: tokens.colors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                          fontSize: 13, color: tokens.colors.muted, height: 1.4),
                    ),
                    if (notif.medicineId != null && notif.medicineId!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.arrowUpRight, size: 13, color: tokens.colors.brand1),
                          const SizedBox(width: 4),
                          Text(
                            'View medicine inventory & batches',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.colors.brand1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.check, size: 16),
                  color: tokens.colors.muted,
                  tooltip: 'Mark as read',
                  onPressed: () {
                    ref
                        .read(notificationsActionControllerProvider.notifier)
                        .markAsRead(notif.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
