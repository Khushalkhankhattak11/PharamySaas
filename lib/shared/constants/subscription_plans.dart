import 'package:flutter/material.dart';

class SubscriptionPlanInfo {
  final String id;
  final String name;
  final String tagline;
  final String monthlyPrice;
  final String yearlyPrice;
  final bool isPopular;
  final Color accentColor;
  final List<String> benefits;
  final List<String> limitations;

  const SubscriptionPlanInfo({
    required this.id,
    required this.name,
    required this.tagline,
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
    name: 'Standard Plan',
    tagline: 'Ideal for small retail pharmacies & dispensaries',
    monthlyPrice: '\$19/mo',
    yearlyPrice: '\$190/yr',
    accentColor: Color(0xFF0D9488), // Teal
    benefits: [
      'Up to 2 Staff Accounts (Cashier & Storekeeper)',
      'Point of Sale (POS) with Quick Barcode & QR Scanner',
      'Thermal 58mm/80mm & PDF Invoicing with Receipt Printing',
      'Inventory Tracking & Medicine Catalog Management',
      'Sales History & Daily Revenue Metrics',
      'Offline Persistence & Local Database Cache',
    ],
    limitations: [
      'No custom invoice logo branding',
      'No batch-level expiry forecast alerts',
      'Standard community support',
    ],
  );

  static const professional = SubscriptionPlanInfo(
    id: 'Professional',
    name: 'Professional Plan',
    tagline: 'Best for busy pharmacies seeking automation & growth',
    monthlyPrice: '\$49/mo',
    yearlyPrice: '\$490/yr',
    isPopular: true,
    accentColor: Color(0xFF0284C7), // Sky Blue
    benefits: [
      'Unlimited Staff Accounts (Multiple Cashiers & Storekeepers)',
      'Automated Batch Expiry Date Alerts & Waste Reduction',
      'Low Stock Level Warning Triggers & Restock Reminders',
      'Supplier Management & Purchase Order Invoicing',
      'Comprehensive Profit & Loss, Tax, and Financial Reports',
      'Custom Receipt Logo, Header & Footer Regulatory Notes',
      'Priority Email & Chat Customer Support',
      'Full Offline Mode with Auto Cloud Sync',
    ],
    limitations: [
      'Single Pharmacy Store Location',
    ],
  );

  static const enterprise = SubscriptionPlanInfo(
    id: 'Enterprise',
    name: 'Enterprise Plan',
    tagline: 'For pharmacy chains, hospital dispensaries & multi-stores',
    monthlyPrice: '\$99/mo',
    yearlyPrice: '\$990/yr',
    accentColor: Color(0xFF7C3AED), // Purple
    benefits: [
      'Everything included in Professional',
      'Multi-Branch & Central Warehouse Architecture Ready',
      'Advanced Inventory Audit Logs & Stock Adjustment Tracking',
      'High-Speed Bulk Barcode Generation & Product Label Printing',
      'One-Click Excel & Financial Ledger Data Exports',
      'Dedicated Account Manager & 24/7 Phone Support',
      'Custom Feature Implementation & 99.9% Uptime SLA',
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

