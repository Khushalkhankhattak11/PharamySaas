import 'package:flutter/material.dart';

class SubscriptionPlanInfo {
  final String id;
  final String name;
  final String badge;
  final String tagline;
  final String staffSubtitle;
  final String staffNote;
  final String monthlyPrice;
  final String yearlyPrice;
  final bool isPopular;
  final Color accentColor;
  final List<String> benefits;
  final List<String> limitations;

  const SubscriptionPlanInfo({
    required this.id,
    required this.name,
    required this.badge,
    required this.tagline,
    required this.staffSubtitle,
    required this.staffNote,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.isPopular = false,
    required this.accentColor,
    required this.benefits,
    this.limitations = const [],
  });
}

class SubscriptionPlans {
  SubscriptionPlans._();

  static const standard = SubscriptionPlanInfo(
    id: 'Standard',
    name: 'Standard',
    badge: 'Starter',
    tagline: 'For small pharmacies',
    staffSubtitle: '1 staff member',
    staffNote: 'Staff limit: 1 total, not 1 of each role.',
    monthlyPrice: '\$19/mo',
    yearlyPrice: '\$190/yr',
    accentColor: Color(0xFF0D9488), // Teal
    benefits: [
      '1 Cashier OR 1 Storekeeper',
      'Owner/Admin account',
      'Light and Dark mode',
      '1 active theme preset',
      'Medicine management',
      'Inventory and batch management',
      'POS and billing',
      'Basic sales reports',
      'Expiry and low-stock alerts',
      'Single pharmacy branch',
    ],
    limitations: [
      'Staff limit: 1 total, not 1 of each role',
      'No customer credit / Udhaar management',
      'No cashier shift management',
    ],
  );

  static const professional = SubscriptionPlanInfo(
    id: 'Professional',
    name: 'Professional',
    badge: 'Popular',
    tagline: 'For growing pharmacies',
    staffSubtitle: '6 staff members',
    staffNote: 'Staff limit: 3 Cashiers + 3 Storekeepers.',
    monthlyPrice: '\$49/mo',
    yearlyPrice: '\$490/yr',
    isPopular: true,
    accentColor: Color(0xFF0284C7), // Sky Blue
    benefits: [
      'Up to 3 Cashiers',
      'Up to 3 Storekeepers',
      'Owner/Admin account',
      '3 selectable theme presets',
      'Light and Dark mode for each theme',
      'Advanced inventory management',
      'Advanced sales and purchase reports',
      'Customer credit / Udhaar management',
      'Supplier management',
      'Cashier shift management',
      'Returns and refund approvals',
      'Staff permissions',
      'Single pharmacy branch',
    ],
    limitations: [
      'Single pharmacy branch only',
      'Staff limit: 3 Cashiers + 3 Storekeepers',
    ],
  );

  static const enterprise = SubscriptionPlanInfo(
    id: 'Enterprise',
    name: 'Enterprise',
    badge: 'Premium',
    tagline: 'For large pharmacies and pharmacy chains',
    staffSubtitle: 'Unlimited staff*',
    staffNote: '*Subject to fair-use limits and infrastructure policy.',
    monthlyPrice: '\$99/mo',
    yearlyPrice: '\$990/yr',
    accentColor: Color(0xFF7C3AED), // Purple
    benefits: [
      'Unlimited Cashiers*',
      'Unlimited Storekeepers*',
      'Owner/Admin account',
      '10+ theme presets',
      'Custom themes and branding',
      'Custom primary and secondary colors',
      'Advanced role and permission management',
      'Multi-branch pharmacy management',
      'Branch-wise inventory and reports',
      'Inter-branch stock transfers',
      'Advanced financial analytics',
      'Detailed audit logs',
      'Priority support',
      'Custom business reports',
    ],
    limitations: [],
  );

  static const List<SubscriptionPlanInfo> all = [
    standard,
    professional,
    enterprise,
  ];

  static SubscriptionPlanInfo fromId(String? id) {
    if (id == null) return standard;
    final clean = id.trim().toLowerCase();
    if (clean.contains('pro')) return professional;
    if (clean.contains('enter')) return enterprise;
    return standard;
  }
}
