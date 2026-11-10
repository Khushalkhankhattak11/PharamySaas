import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/tokens.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../shared/models/user_role.dart';
import 'plan_card.dart';

class NavItemData {
  final String title;
  final IconData icon;
  final String route;
  final String? group;

  const NavItemData({
    required this.title,
    required this.icon,
    required this.route,
    this.group,
  });
}

class AppSidebar extends ConsumerWidget {
  final UserRole role;
  final String currentRoute;
  final bool isCollapsed;
  final VoidCallback? onManagePlan;

  const AppSidebar({
    super.key,
    required this.role,
    required this.currentRoute,
    this.isCollapsed = false,
    this.onManagePlan,
  });

  List<NavItemData> _getNavItems() {
    if (role.isSuperAdmin) {
      return const [
        NavItemData(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/super-admin', group: 'Platform'),
        NavItemData(title: 'Pending approvals', icon: LucideIcons.checkSquare, route: '/super-admin/approvals', group: 'Platform'),
        NavItemData(title: 'All pharmacies', icon: LucideIcons.building, route: '/super-admin/pharmacies', group: 'Platform'),
        NavItemData(title: 'Notifications', icon: LucideIcons.bell, route: '/notifications', group: 'System'),
        NavItemData(title: 'Settings', icon: LucideIcons.settings, route: '/settings', group: 'System'),
      ];
    }

    if (role.isStorekeeper) {
      return const [
        NavItemData(title: 'Inventory', icon: LucideIcons.package, route: '/inventory', group: 'Inventory'),
        NavItemData(title: 'Purchases', icon: LucideIcons.shoppingCart, route: '/purchases', group: 'Inventory'),
        NavItemData(title: 'Suppliers', icon: LucideIcons.truck, route: '/suppliers', group: 'Inventory'),
        NavItemData(title: 'QR labels', icon: LucideIcons.qrCode, route: '/qr-setup', group: 'Inventory'),
        NavItemData(title: 'Reports', icon: LucideIcons.barChart2, route: '/reports', group: 'Inventory'),
        NavItemData(title: 'Notifications', icon: LucideIcons.bell, route: '/notifications', group: 'System'),
        NavItemData(title: 'Settings', icon: LucideIcons.settings, route: '/settings', group: 'System'),
      ];
    }

    if (role.isCashier) {
      return const [
        NavItemData(title: 'Point of sale', icon: LucideIcons.calculator, route: '/pos', group: 'Main menu'),
        NavItemData(title: 'Sales history', icon: LucideIcons.receipt, route: '/sales-history', group: 'Main menu'),
        NavItemData(title: 'Medicines', icon: LucideIcons.package, route: '/inventory', group: 'Inventory'),
        NavItemData(title: 'Medicine lookup', icon: LucideIcons.search, route: '/medicine-lookup', group: 'Inventory'),
        NavItemData(title: 'Notifications', icon: LucideIcons.bell, route: '/notifications', group: 'System'),
        NavItemData(title: 'Settings', icon: LucideIcons.settings, route: '/settings', group: 'System'),
      ];
    }

    // Admin (Pharmacy Owner)
    return const [
      NavItemData(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/dashboard', group: 'Main menu'),
      NavItemData(title: 'Point of sale', icon: LucideIcons.calculator, route: '/pos', group: 'Main menu'),
      NavItemData(title: 'Sales history', icon: LucideIcons.receipt, route: '/sales-history', group: 'Main menu'),
      NavItemData(title: 'Medicines', icon: LucideIcons.package, route: '/inventory', group: 'Inventory'),
      NavItemData(title: 'QR labels', icon: LucideIcons.qrCode, route: '/qr-setup', group: 'Inventory'),
      NavItemData(title: 'Purchases', icon: LucideIcons.shoppingCart, route: '/purchases', group: 'Inventory'),
      NavItemData(title: 'Suppliers', icon: LucideIcons.truck, route: '/suppliers', group: 'Inventory'),
      NavItemData(title: 'Reports', icon: LucideIcons.barChart2, route: '/reports', group: 'Admin'),
      NavItemData(title: 'Staff', icon: LucideIcons.users, route: '/staff', group: 'Admin'),
      NavItemData(title: 'Settings', icon: LucideIcons.settings, route: '/settings', group: 'Admin'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final navItems = _getNavItems();
    final width = isCollapsed ? 80.0 : 260.0;

    return Container(
      width: width,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 24,
        horizontal: isCollapsed ? 10 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Logo row (padding 0 8 18): 42x42 mark, radius 14, gradient 135deg brand1 -> brand2, white bold "+" 22px, shadow 0 8 18 brand1 at 40%. Right of it "PharmaCore" 17/800 and "Smart pharmacy management" 12 muted.
          Padding(
            padding: EdgeInsets.only(bottom: 18, left: isCollapsed ? 0 : 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tokens.colors.brand1, tokens.colors.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.logoMark),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.colors.brand1.withValues(alpha: 0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role.isSuperAdmin ? 'PharmaCore SA' : 'PharmaCore',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: tokens.colors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          role.isSuperAdmin ? 'Super Admin Portal' : 'Smart pharmacy management',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tokens.colors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Nav items list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildNavGroupWidgets(context, navItems),
            ),
          ),
          // Plan Card at the bottom (Admin only, when not collapsed)
          if (role.isAdmin && !isCollapsed) ...[
            const SizedBox(height: 16),
            PlanCard(
              onManage: onManagePlan,
            ),
          ],
          const SizedBox(height: 12),
          // Prominent Logout button
          _buildLogoutButton(context, ref, tokens),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, AppTokens tokens) {
    if (isCollapsed) {
      return Tooltip(
        message: 'Sign Out',
        child: InkWell(
          onTap: () => _confirmSignOut(context, ref),
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColorsTokens.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.logOut,
                size: 20,
                color: AppColorsTokens.danger,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _confirmSignOut(context, ref),
      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColorsTokens.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          border: Border.all(
            color: AppColorsTokens.danger.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: Icon(
                  LucideIcons.logOut,
                  size: 16,
                  color: AppColorsTokens.danger,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColorsTokens.danger,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Text('Sign Out'),
        content: Text('Are you sure you want to sign out${role.isSuperAdmin ? ' from Super Admin' : ''}?'),
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

  List<Widget> _buildNavGroupWidgets(BuildContext context, List<NavItemData> items) {
    final tokens = context.tokens;
    final List<Widget> widgets = [];
    String? currentGroup;

    for (final item in items) {
      if (!isCollapsed && item.group != null && item.group != currentGroup) {
        currentGroup = item.group;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
            child: Text(
              currentGroup!,
              style: tokens.typography.navGroupLabel,
            ),
          ),
        );
      }

      final isActive = currentRoute == item.route ||
          (item.route != '/dashboard' &&
              item.route != '/super-admin' &&
              currentRoute.startsWith(item.route));

      widgets.add(
        _NavTile(
          item: item,
          isActive: isActive,
          isCollapsed: isCollapsed,
          onTap: () {
            if (currentRoute != item.route) {
              context.go(item.route);
            }
          },
        ),
      );
      widgets.add(const SizedBox(height: 4));
    }

    return widgets;
  }
}

class _NavTile extends StatefulWidget {
  final NavItemData item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tokens.colors.brand1, tokens.colors.brand2],
    );
    final activeShadow = BoxShadow(
      color: tokens.colors.brand1.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 8),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.item.title,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: widget.isActive ? activeGradient : null,
              color: widget.isActive
                  ? null
                  : (_isHovered ? tokens.colors.track : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
              boxShadow: widget.isActive ? [activeShadow] : null,
            ),
            child: Center(
              child: Icon(
                widget.item.icon,
                size: 20,
                color: widget.isActive ? Colors.white : tokens.colors.ink,
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: widget.isActive ? activeGradient : null,
              color: widget.isActive
                  ? null
                  : (_isHovered ? tokens.colors.track : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
              boxShadow: widget.isActive ? [activeShadow] : null,
            ),
            child: Row(
              children: [
                // 30px circular icon holder (track color, rgba(255,255,255,0.20) when active)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isActive
                        ? Colors.white.withValues(alpha: 0.20)
                        : tokens.colors.track,
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 16,
                    color: widget.isActive ? Colors.white : tokens.colors.ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isActive ? Colors.white : tokens.colors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}