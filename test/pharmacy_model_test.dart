import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/approval_status.dart';
import 'package:pharmcysas/shared/models/pharmacy_model.dart';

void main() {
  group('PharmacyModel Owner Mapping Tests', () {
    test('Serializes and deserializes ownerEmail and ownerId correctly', () {
      const pharmacy = PharmacyModel(
        id: 'pharm_123',
        name: 'Central City Pharmacy',
        ownerId: 'owner_user_456',
        ownerEmail: 'owner@citypharmacy.com',
        approvalStatus: ApprovalStatus.approved,
        currency: 'USD',
        plan: 'Standard',
      );

      final json = pharmacy.toJson();
      expect(json['owner_id'], 'owner_user_456');
      expect(json['owner_email'], 'owner@citypharmacy.com');
      expect(json['approval_status'], 'approved');

      final deserialized = PharmacyModel.fromJson(json);
      expect(deserialized.id, 'pharm_123');
      expect(deserialized.name, 'Central City Pharmacy');
      expect(deserialized.ownerId, 'owner_user_456');
      expect(deserialized.ownerEmail, 'owner@citypharmacy.com');
      expect(deserialized.approvalStatus, ApprovalStatus.approved);
      expect(deserialized.domain, 'centralcitypharmacy.com');
    });

    test('Generates correct pharmacy email domain from name', () {
      const p1 = PharmacyModel(id: '1', name: 'Khan Pharmacy', approvalStatus: ApprovalStatus.approved);
      expect(p1.domain, 'khanpharmacy.com');

      const p2 = PharmacyModel(id: '2', name: 'Al-Shifa & Med Care 24', approvalStatus: ApprovalStatus.approved);
      expect(p2.domain, 'alshifamedcare24.com');

      const p3 = PharmacyModel(id: '3', name: '', approvalStatus: ApprovalStatus.approved);
      expect(p3.domain, 'pharmacy.com');
    });

    test('Handles plan upgrade request serialization and isPlanUpgradePending', () {
      final now = DateTime.now();
      final pharmacy = PharmacyModel(
        id: 'pharm_upgrade_1',
        name: 'Metro Pharmacy',
        approvalStatus: ApprovalStatus.approved,
        plan: 'Standard',
        requestedPlan: 'Professional',
        requestedPlanAt: now,
        requestedPlanDays: 180,
      );

      expect(pharmacy.isPlanUpgradePending, isTrue);

      final json = pharmacy.toJson();
      expect(json['requested_plan'], 'Professional');
      expect(json['requested_plan_days'], 180);
      expect(json['requested_plan_at'], isNotNull);

      final deserialized = PharmacyModel.fromJson(json);
      expect(deserialized.requestedPlan, 'Professional');
      expect(deserialized.requestedPlanDays, 180);
      expect(deserialized.isPlanUpgradePending, isTrue);

      // Same plan requested should not be pending
      final samePlan = pharmacy.copyWith(requestedPlan: 'Standard');
      expect(samePlan.isPlanUpgradePending, isFalse);

      // No requested plan should not be pending
      final noRequest = pharmacy.copyWith(requestedPlan: null);
      expect(noRequest.isPlanUpgradePending, isFalse);
    });
  });
}
