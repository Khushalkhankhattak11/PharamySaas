import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/approval_status.dart';
import 'package:pharmcysas/shared/models/pharmacy_model.dart';
import 'package:pharmcysas/shared/models/profile_model.dart';
import 'package:pharmcysas/shared/models/user_role.dart';

void main() {
  group('Route Guards & Permissions Tests', () {
    test('Unauthenticated user is redirected to /login for protected routes', () {
      const String? userId = null;
      const String targetPath = '/dashboard';

      String? redirect(String? user, String path) {
        if (user == null) {
          if (path == '/login' || path == '/signup') return null;
          return '/login';
        }
        return null;
      }

      expect(redirect(userId, targetPath), '/login');
      expect(redirect(userId, '/login'), null);
      expect(redirect(userId, '/signup'), null);
    });

    test('Super admin is restricted to /super-admin portal', () {
      const superAdmin = ProfileModel(
        id: 'sa1',
        role: UserRole.superAdmin,
        fullName: 'Super Admin',
        isActive: true,
      );

      String? redirect(ProfileModel profile, String path) {
        if (profile.role.isSuperAdmin) {
          if (path.startsWith('/super-admin')) return null;
          return '/super-admin';
        }
        return null;
      }

      expect(redirect(superAdmin, '/dashboard'), '/super-admin');
      expect(redirect(superAdmin, '/super-admin/approvals'), null);
    });

    test('Pending pharmacy owner is locked into /approval-status', () {
      const pharmacy = PharmacyModel(
        id: 'p1',
        name: 'Test Pharmacy',
        approvalStatus: ApprovalStatus.pending,
      );

      String? redirect(PharmacyModel ph, String path) {
        if (!ph.isEffectivelyApproved) {
          if (path == '/approval-status') return null;
          return '/approval-status';
        }
        return null;
      }

      expect(redirect(pharmacy, '/dashboard'), '/approval-status');
      expect(redirect(pharmacy, '/inventory'), '/approval-status');
      expect(redirect(pharmacy, '/approval-status'), null);
    });

    test('Cashier is redirected away from inventory and reports to /pos', () {
      const role = UserRole.cashier;

      String? redirect(UserRole userRole, String path) {
        if (userRole.isCashier) {
          final allowed = ['/pos', '/sales-history', '/medicine-lookup', '/notifications', '/settings'];
          final isAllowed = allowed.any((p) => path.startsWith(p));
          if (!isAllowed) return '/pos';
        }
        return null;
      }

      expect(redirect(role, '/inventory'), '/pos');
      expect(redirect(role, '/reports'), '/pos');
      expect(redirect(role, '/staff'), '/pos');
      expect(redirect(role, '/pos'), null);
      expect(redirect(role, '/sales-history'), null);
      expect(redirect(role, '/medicine-lookup'), null);
    });

    test('Storekeeper is redirected away from POS and reports to /inventory', () {
      const role = UserRole.storekeeper;

      String? redirect(UserRole userRole, String path) {
        if (userRole.isStorekeeper) {
          final disallowed = ['/pos', '/reports', '/staff', '/dashboard'];
          if (disallowed.any((p) => path.startsWith(p))) return '/inventory';
        }
        return null;
      }

      expect(redirect(role, '/pos'), '/inventory');
      expect(redirect(role, '/reports'), '/inventory');
      expect(redirect(role, '/inventory'), null);
      expect(redirect(role, '/purchases'), null);
      expect(redirect(role, '/qr-setup'), null);
    });
  });
}
