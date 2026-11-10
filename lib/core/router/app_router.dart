import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/approval/presentation/screens/approval_status_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/medicine_detail_screen.dart';
import '../../features/inventory/presentation/screens/medicine_form_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/pharmacy_registration/presentation/screens/register_pharmacy_screen.dart';
import '../../features/pos/presentation/screens/medicine_lookup_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/purchases/presentation/screens/new_purchase_screen.dart';
import '../../features/purchases/presentation/screens/purchases_screen.dart';
import '../../features/qr/presentation/screens/qr_setup_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/sales/presentation/screens/sales_history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import '../../features/super_admin/presentation/screens/pending_approvals_screen.dart';
import '../../features/super_admin/presentation/screens/pharmacies_list_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/presentation/widgets/super_admin_scaffold.dart';
import '../../features/suppliers/presentation/screens/suppliers_screen.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/app_scaffold.dart';

final routerKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(currentProfileProvider, (_, __) => notifyListeners());
    _ref.listen(currentPharmacyProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authRepo = _ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final path = state.matchedLocation;

    final isAuthRoute = path == '/login' ||
        path == '/signup' ||
        path == '/forgot-password';

    // Unauthenticated users
    if (user == null) {
      return isAuthRoute ? null : '/login';
    }

    final profileState = _ref.read(currentProfileProvider);
    final profile = profileState.value;

    // Profile still loading
    if (profile == null) {
      return null;
    }

    // Inactive staff
    if (!profile.isActive) {
      return '/login';
    }

    // Super Admin routing
    if (profile.role.isSuperAdmin) {
      if (path.startsWith('/super-admin')) return null;
      return '/super-admin';
    }

    // User must not access super-admin
    if (path.startsWith('/super-admin')) {
      return '/dashboard';
    }

    // Admin without registered pharmacy
    if (profile.pharmacyId == null) {
      if (path == '/register-pharmacy') return null;
      return '/register-pharmacy';
    }

    final pharmacyState = _ref.read(currentPharmacyProvider);
    final pharmacy = pharmacyState.value;

    // If pharmacy details are not yet loaded
    if (pharmacy == null) {
      if (isAuthRoute) {
        switch (profile.role) {
          case UserRole.admin:
            return '/dashboard';
          case UserRole.storekeeper:
            return '/inventory';
          case UserRole.cashier:
            return '/pos';
          case UserRole.superAdmin:
            return '/super-admin';
        }
      }
      return null;
    }

    // Check approval status & subscription
    final isApproved = pharmacy.isEffectivelyApproved;

    if (!isApproved) {
      if (path == '/approval-status') return null;
      return '/approval-status';
    }

    // Pharmacy IS approved
    if (isAuthRoute ||
        path == '/approval-status' ||
        path == '/register-pharmacy') {
      switch (profile.role) {
        case UserRole.admin:
          return '/dashboard';
        case UserRole.storekeeper:
          return '/inventory';
        case UserRole.cashier:
          return '/pos';
        case UserRole.superAdmin:
          return '/super-admin';
      }
    }

    // Role-based restrictions inside approved pharmacy
    if (profile.role.isCashier) {
      // Cashier can view Inventory, search medicines, POS, Sales History, Medicine Lookup, Notifications, Settings
      // But Cashier is denied adding or editing medicines
      if (path == '/inventory/add' || path.endsWith('/edit')) {
        return '/inventory';
      }

      final allowed = [
        '/pos',
        '/sales-history',
        '/inventory',
        '/medicine-lookup',
        '/notifications',
        '/settings',
      ];
      final isAllowed = allowed.any((p) => path.startsWith(p));
      if (!isAllowed) {
        return '/pos';
      }
    } else if (profile.role.isStorekeeper) {
      // Storekeeper can access Inventory, Purchases, Suppliers, QR, Reports (inventory), Notifications, Settings
      final disallowed = [
        '/pos',
        '/staff',
        '/sales-history',
        '/dashboard',
      ];
      final isDisallowed = disallowed.any((p) => path.startsWith(p));
      if (isDisallowed) {
        return '/inventory';
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Public / Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register-pharmacy',
        builder: (context, state) => const RegisterPharmacyScreen(),
      ),
      GoRoute(
        path: '/approval-status',
        builder: (context, state) => const ApprovalStatusScreen(),
      ),

      // Super Admin Portal Shell
      ShellRoute(
        builder: (context, state, child) => SuperAdminScaffold(child: child),
        routes: [
          GoRoute(
            path: '/super-admin',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SuperAdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/approvals',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PendingApprovalsScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/pharmacies',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PharmaciesListScreen(),
            ),
          ),
        ],
      ),

      // Pharmacy App Shell
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PosScreen(),
            ),
          ),
          GoRoute(
            path: '/medicine-lookup',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MedicineLookupScreen(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const InventoryScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const MedicineFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => MedicineDetailScreen(
                  medicineId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => MedicineFormScreen(
                      medicineId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/qr-setup',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const QrSetupScreen(),
            ),
          ),
          GoRoute(
            path: '/purchases',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PurchasesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewPurchaseScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/suppliers',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SuppliersScreen(),
            ),
          ),
          GoRoute(
            path: '/sales-history',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SalesHistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/staff',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StaffScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
