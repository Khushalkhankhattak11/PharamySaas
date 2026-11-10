enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  admin('admin', 'Admin (Owner)'),
  cashier('cashier', 'Cashier'),
  storekeeper('storekeeper', 'Storekeeper');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'cashier':
        return UserRole.cashier;
      case 'storekeeper':
        return UserRole.storekeeper;
      default:
        return UserRole.cashier;
    }
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isAdmin => this == UserRole.admin;
  bool get isCashier => this == UserRole.cashier;
  bool get isStorekeeper => this == UserRole.storekeeper;

  // Inventory Permissions
  bool get canViewInventory => true; // Cashier, Storekeeper, and Admin can view
  bool get canSearchMedicines => true;
  bool get canViewAvailableStock => true;
  bool get canViewMedicinePrice => true; // Retail / Sale price
  bool get canViewBatchNumber => true;
  bool get canViewExpiryDate => true;
  bool get canScanBarcode => true;

  // Management & Modification Permissions (Admin & Storekeeper only)
  bool get canModifyInventory => isAdmin || isStorekeeper;
  bool get canAddMedicine => isAdmin || isStorekeeper;
  bool get canEditMedicine => isAdmin || isStorekeeper;
  bool get canChangeStock => isAdmin || isStorekeeper;
  bool get canChangePurchasePrice => isAdmin || isStorekeeper;
  bool get canManageBatches => isAdmin || isStorekeeper;
  bool get canDeleteBatches => isAdmin || isStorekeeper;

  // Financial / Cost visibility (Cost price hidden from Cashier)
  bool get canViewCostPrice => isAdmin || isStorekeeper;

  // Operation / Module Permissions
  bool get canAccessInventory => true; // All pharmacy staff can view inventory
  bool get canAccessPurchases => isAdmin || isStorekeeper;
  bool get canManageSuppliers => isAdmin || isStorekeeper;
  bool get canAccessPos => isAdmin || isCashier;
  bool get canAccessReports => isAdmin || isStorekeeper;
  bool get canManageStaff => isAdmin;
}

