/// Central collection names for Firestore multi-tenant architecture.
class FirestoreCollections {
  const FirestoreCollections._();

  /// Multi-tenant Pharmacies root collection
  static const String pharmacies = 'pharmacies';

  /// Pharmacy staff subcollection name under pharmacies/{pharmacyId}/staff
  static const String staff = 'staff';

  /// User auth profiles (Admin, Storekeeper, Cashier)
  static const String profiles = 'profiles';

  /// Dedicated collection for Super Admin accounts (separated from profiles collection)
  static const String admin = 'admin';

  /// Dedicated collection for Cashiers
  static const String cashiers = 'cashiers';

  /// Dedicated collection for Storekeepers
  static const String storekeepers = 'storekeepers';

  /// Inventory medicines collection (partitioned by pharmacy_id)
  static const String medicines = 'medicines';

  /// Products alias collection (for backward compatibility and subcollection visibility)
  static const String products = 'products';

  /// Stocks subcollection under pharmacies/{pharmacyId}/stocks
  static const String stocks = 'stocks';

  /// Inventory batches collection (partitioned by pharmacy_id)
  static const String batches = 'batches';

  /// Suppliers collection (partitioned by pharmacy_id)
  static const String suppliers = 'suppliers';

  /// Purchases / Stock-in collection (partitioned by pharmacy_id)
  static const String purchases = 'purchases';

  /// POS sales and invoices (partitioned by pharmacy_id)
  static const String sales = 'sales';

  /// In-app and push notification log (partitioned by pharmacy_id)
  static const String notifications = 'notifications';

  /// Multi-tenant approval and suspension audit logs
  static const String approvalLogs = 'approval_logs';

  /// Pharmacy-specific receipt, tax and layout settings
  static const String settings = 'settings';

  /// Inventory stock adjustment logs
  static const String stockAdjustments = 'stock_adjustments';

  /// Cash register shifts (counter opening/closing cash & payment reconciliations)
  static const String shifts = 'shifts';
}

