import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'app_search_field.dart';
import 'avatar_menu.dart';
import 'notification_bell.dart';
import 'theme_picker_pill.dart';

class AppTopBar extends ConsumerWidget {
  final String title;
  final Widget? customSearchField;
  final VoidCallback? onSearchTap;
  final int unreadNotificationsCount;

  const AppTopBar({
    super.key,
    required this.title,
    this.customSearchField,
    this.onSearchTap,
    this.unreadNotificationsCount = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final location = GoRouterState.of(context).matchedLocation;
    final currentProfile = ref.watch(currentProfileProvider).valueOrNull;
    final isSuperAdmin = location.startsWith('/super-admin') ||
        (currentProfile?.role.isSuperAdmin ?? false);
    final themeMode = ref.watch(themeModeProvider);

    final fullName = isSuperAdmin
        ? (currentProfile?.fullName ?? 'Platform Super Admin')
        : (currentProfile?.fullName ?? 'Pharmacy Owner');
    final roleName = isSuperAdmin
        ? 'Super Admin'
        : (currentProfile?.role.label ?? 'Administrator');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Page title: 26/800
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isPhone ? 22 : 26,
                fontWeight: FontWeight.w800,
                color: tokens.colors.ink,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Search Field (desktop & tablet only, not shown on super-admin)
          if (!isPhone && !isSuperAdmin) ...[
            customSearchField ??
                AppSearchField(
                  maxWidth: isTablet ? 260 : 460,
                  placeholder: 'Search medicines, invoices, batches...',
                ),
            const SizedBox(width: 12),
          ],
          // Theme Picker pill group on desktop/tablet
          if (!isPhone) ...[
            const ThemePickerPill(),
            const SizedBox(width: 8),
          ],
          // 44px circular notification button with 9px red dot (pharmacy roles)
          if (!isSuperAdmin) ...[
            NotificationBell(
              unreadCount: unreadNotificationsCount,
              onTap: () => context.go('/notifications'),
            ),
            const SizedBox(width: 8),
          ],
          // 44px circular theme toggle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.colors.line, width: 1),
              boxShadow: [tokens.colors.shadow],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
                child: Icon(
                  themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
                  size: 18,
                  color: tokens.colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // User block: 42px avatar + name 14/700 + role 12 muted
          AvatarMenu(
            fullName: fullName,
            role: roleName,
            showText: !isPhone,
            onTap: () {
              if (isSuperAdmin) {
                _confirmSignOut(context, ref);
              } else {
                context.go('/settings');
              }
            },
          ),
          // Dedicated Sign Out button for Super Admin
          if (isSuperAdmin) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'Sign Out',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                onTap: () => _confirmSignOut(context, ref),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 10 : 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsTokens.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    border: Border.all(
                      color: AppColorsTokens.danger.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.logOut,
                        size: 16,
                        color: AppColorsTokens.danger,
                      ),
                      if (!isPhone) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColorsTokens.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Super Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColorsTokens.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}