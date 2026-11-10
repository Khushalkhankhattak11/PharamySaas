import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/user_role.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'safe_sign_out_dialog.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isPhone = screenWidth < 600;

    final location = GoRouterState.of(context).matchedLocation;
    final isSuperAdmin = location.startsWith('/super-admin');
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;

    if (profileAsync.isLoading && !isSuperAdmin) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final role = isSuperAdmin
        ? UserRole.superAdmin
        : (profile?.role ?? UserRole.cashier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tokens.colors.bgTop, tokens.colors.bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: !isPhone,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar for desktop (264) or tablet rail (80)
              if (!isPhone) ...[
                AppSidebar(
                  role: role,
                  currentRoute: location,
                  isCollapsed: isTablet,
                ),
              ],

              // Main content area
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(location),
                  padding: EdgeInsetsDirectional.fromSTEB(
                    isDesktop ? 28 : 16,
                    20,
                    isDesktop ? 28 : 16,
                    40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Bar
                          AppTopBar(
                            title: _getTitleFromRoute(location),
                          ),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isPhone ? _buildMobileNavBar(context, ref, role) : null,
    );
  }

  Widget _buildMobileNavBar(BuildContext context, WidgetRef ref, UserRole role) {
    final location = GoRouterState.of(context).matchedLocation;
    final tokens = context.tokens;

    if (role.isSuperAdmin || location.startsWith('/super-admin')) {
      return Container(
        decoration: BoxDecoration(
          color: tokens.colors.card,
          border: Border(top: BorderSide(color: tokens.colors.line, width: 1)),
          boxShadow: [tokens.colors.shadow],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PhoneNavItem(
                icon: LucideIcons.layoutDashboard,
                label: 'Overview',
                isActive: location == '/super-admin',
                onTap: () => context.go('/super-admin'),
              ),
              _PhoneNavItem(
                icon: LucideIcons.checkSquare,
                label: 'Approvals',
                isActive: location.startsWith('/super-admin/approvals'),
                onTap: () => context.go('/super-admin/approvals'),
              ),
              _PhoneNavItem(
                icon: LucideIcons.building,
                label: 'Pharmacies',
                isActive: location.startsWith('/super-admin/pharmacies'),
                onTap: () => context.go('/super-admin/pharmacies'),
              ),
              _PhoneNavItem(
                icon: LucideIcons.logOut,
                label: 'Sign Out',
                isActive: false,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ),
      );
    }

    if (role.isCashier) {
      return Container(
        decoration: BoxDecoration(
          color: tokens.colors.card,
          border: Border(top: BorderSide(color: tokens.colors.line, width: 1)),
          boxShadow: [tokens.colors.shadow],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PhoneNavItem(
                icon: LucideIcons.search,
                label: 'Medicines',
                isActive: location.startsWith('/medicine-lookup'),
                onTap: () => context.go('/medicine-lookup'),
              ),
              _PhoneNavItem(
                icon: LucideIcons.receipt,
                label: 'My Sales',
                isActive: location.startsWith('/sales-history'),
                onTap: () => context.go('/sales-history'),
              ),

              // CENTER HIGHLIGHTED POS (Selling)
              GestureDetector(
                onTap: () => context.go('/pos'),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    gradient: AppColorsTokens.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x660F766E),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.calculator,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              _PhoneNavItem(
                icon: LucideIcons.bell,
                label: 'Alerts',
                isActive: location.startsWith('/notifications'),
                onTap: () => context.go('/notifications'),
              ),
              _PhoneNavItem(
                icon: LucideIcons.logOut,
                label: 'Sign Out',
                isActive: false,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.colors.card,
        border: Border(top: BorderSide(color: tokens.colors.line, width: 1)),
        boxShadow: [tokens.colors.shadow],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _PhoneNavItem(
              icon: LucideIcons.layoutDashboard,
              label: 'Home',
              isActive: location == '/dashboard',
              onTap: () => context.go('/dashboard'),
            ),
            if (role != UserRole.cashier)
              _PhoneNavItem(
                icon: LucideIcons.package2,
                label: 'Inventory',
                isActive: location.startsWith('/inventory'),
                onTap: () => context.go('/inventory'),
              ),

            // Prominent center POS action
            GestureDetector(
              onTap: () => context.go('/pos'),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: AppColorsTokens.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D0F766E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.calculator,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

            _PhoneNavItem(
              icon: LucideIcons.receipt,
              label: 'Sales',
              isActive: location.startsWith('/sales-history'),
              onTap: () => context.go('/sales-history'),
            ),
            _PhoneNavItem(
              icon: LucideIcons.menu,
              label: 'More',
              isActive: location.startsWith('/reports') ||
                  location.startsWith('/staff') ||
                  location.startsWith('/settings') ||
                  location.startsWith('/purchases') ||
                  location.startsWith('/suppliers'),
              onTap: () => _showMoreSheet(context, ref, role),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, WidgetRef ref, UserRole role) {
    final tokens = context.tokens;

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role.canAccessPurchases) ...[
                  ListTile(
                    leading: const Icon(LucideIcons.shoppingCart),
                    title: const Text('Purchases / Stock-In'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/purchases');
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.truck),
                    title: const Text('Suppliers'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/suppliers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.qrCode),
                    title: const Text('QR & Barcode Setup'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/qr-setup');
                    },
                  ),
                ],
                if (role.canAccessReports)
                  ListTile(
                    leading: const Icon(LucideIcons.barChart3),
                    title: const Text('Reports & Analytics'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/reports');
                    },
                  ),
                if (role == UserRole.admin)
                  ListTile(
                    leading: const Icon(LucideIcons.users),
                    title: const Text('Staff Management'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/staff');
                    },
                  ),
                ListTile(
                  leading: const Icon(LucideIcons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: AppColorsTokens.danger),
                  title: const Text('Sign Out', style: TextStyle(color: AppColorsTokens.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmSignOut(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showSafeSignOutDialog(context, ref);
  }

  String _getTitleFromRoute(String location) {
    if (location.startsWith('/dashboard')) return 'Dashboard';
    if (location.startsWith('/inventory')) return 'Inventory';
    if (location.startsWith('/pos')) return 'Point of Sale (POS)';
    if (location.startsWith('/medicine-lookup')) return 'Medicine Price & Stock Lookup';
    if (location.startsWith('/sales-history')) return 'Sales History';
    if (location.startsWith('/purchases')) return 'Purchases';
    if (location.startsWith('/suppliers')) return 'Suppliers';
    if (location.startsWith('/staff')) return 'Staff Management';
    if (location.startsWith('/reports')) return 'Reports & Analytics';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith('/qr-setup')) return 'QR & Barcode Setup';
    if (location.startsWith('/super-admin/approvals')) return 'Pending Approvals';
    if (location.startsWith('/super-admin/pharmacies')) return 'All Pharmacies';
    if (location.startsWith('/super-admin')) return 'Platform Overview';
    return 'PharmaCore';
  }
}

class _PhoneNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PhoneNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = isActive ? AppColorsTokens.brand : tokens.colors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
