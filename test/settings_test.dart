import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/profile_model.dart';
import 'package:pharmcysas/shared/models/user_role.dart';
import 'package:pharmcysas/shared/models/pharmacy_model.dart';
import 'package:pharmcysas/shared/models/approval_status.dart';

void main() {
  group('Pharmacy Owner Profile & Details Update Tests', () {
    test('ProfileModel updates fullName and phone correctly via copyWith and JSON', () {
      const initialProfile = ProfileModel(
        id: 'owner_123',
        pharmacyId: 'pharm_abc',
        role: UserRole.admin,
        fullName: 'Original Name',
        phone: '111-222-3333',
        isActive: true,
      );

      final updatedProfile = initialProfile.copyWith(
        fullName: 'Dr. Jane Smith',
        phone: '+92 300 9876543',
      );

      expect(updatedProfile.id, 'owner_123');
      expect(updatedProfile.pharmacyId, 'pharm_abc');
      expect(updatedProfile.role, UserRole.admin);
      expect(updatedProfile.fullName, 'Dr. Jane Smith');
      expect(updatedProfile.phone, '+92 300 9876543');

      final json = updatedProfile.toJson();
      expect(json['full_name'], 'Dr. Jane Smith');
      expect(json['phone'], '+92 300 9876543');
      expect(json['role'], 'admin');

      final deserialized = ProfileModel.fromJson(json);
      expect(deserialized.fullName, 'Dr. Jane Smith');
      expect(deserialized.phone, '+92 300 9876543');
    });

    test('PharmacyModel updates store details and receipt customization correctly', () {
      const initialPharmacy = PharmacyModel(
        id: 'pharm_abc',
        name: 'Initial Pharmacy',
        ownerEmail: 'owner@med.com',
        ownerId: 'owner_123',
        approvalStatus: ApprovalStatus.approved,
        currency: 'USD',
      );

      final updated = initialPharmacy.copyWith(
        name: 'Apex Health Pharmacy',
        address: '456 Healthcare Blvd',
        city: 'Metropolis',
        phone: '+1 555 987 6543',
        currency: 'Rs',
        receiptHeader: 'Welcome to Apex Health!',
        receiptFooter: 'Thank you for your patronage.',
      );

      expect(updated.name, 'Apex Health Pharmacy');
      expect(updated.address, '456 Healthcare Blvd');
      expect(updated.city, 'Metropolis');
      expect(updated.phone, '+1 555 987 6543');
      expect(updated.currency, 'Rs');
      expect(updated.receiptHeader, 'Welcome to Apex Health!');
      expect(updated.receiptFooter, 'Thank you for your patronage.');

      final json = updated.toJson();
      expect(json['name'], 'Apex Health Pharmacy');
      expect(json['currency'], 'Rs');
      expect(json['receipt_header'], 'Welcome to Apex Health!');
      expect(json['receipt_footer'], 'Thank you for your patronage.');
    });
  });
}

