import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../controllers/super_admin_controller.dart';

class PharmaciesListScreen extends ConsumerStatefulWidget {
  const PharmaciesListScreen({super.key});

  @override
  ConsumerState<PharmaciesListScreen> createState() =>
      _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends ConsumerState<PharmaciesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<String> _provincesList = [
    'Khyber Pakhtunkhwa',
    'Punjab',
    'Sindh',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu & Kashmir',
  ];

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showAddPharmacyDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final regNumberCtrl = TextEditingController();
    final dslCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final pharmacistNameCtrl = TextEditingController();
    final pharmacistRegCtrl = TextEditingController();
    final cnicCtrl = TextEditingController();
    final ownerEmailCtrl = TextEditingController();
    final ownerPasswordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    String province = 'Khyber Pakhtunkhwa';
    DateTime? licenseIssueDate;
    DateTime? licenseExpiryDate;

    bool obscurePassword = true;
    String currency = 'Rs';
    String plan = 'Standard';
    int planDays = 365;
    String status = 'approved';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
          ),
          title: const Text('Add New Pharmacy (Super Admin)'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Pharmacy & Licenses
                    const Text(
                      'Pharmacy & Pakistani Regulatory Licenses',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pharmacy Name *',
                        hintText: 'e.g. City Central Pharmacy',
                        prefixIcon: Icon(LucideIcons.building2, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pharmacy name is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: regNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reg Number',
                              hintText: 'e.g. PC-2026-78452',
                              prefixIcon: Icon(LucideIcons.hash, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: dslCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Drug Sale License',
                              hintText: 'e.g. DSL-KP-458921',
                              prefixIcon:
                                  Icon(LucideIcons.shieldCheck, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Owner & Login Credentials
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColorsTokens.mint.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadiusTokens.tile),
                        border: Border.all(
                            color:
                                AppColorsTokens.brand.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.userCheck,
                                  size: 16, color: AppColorsTokens.brand),
                              SizedBox(width: 6),
                              Text(
                                'Pharmacy Owner & Login Account',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColorsTokens.brand,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ownerNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Owner Name',
                                    hintText: 'e.g. Khushal Khan',
                                    prefixIcon:
                                        Icon(LucideIcons.user, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: cnicCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Owner CNIC',
                                    hintText: '14xxx-xxxxxxx-x',
                                    prefixIcon:
                                        Icon(LucideIcons.creditCard, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: ownerEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Owner Login Email *',
                              hintText: 'e.g. owner@pharmacy.com',
                              prefixIcon: Icon(LucideIcons.mail, size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Owner login email is required';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: ownerPasswordCtrl,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Owner Login Password *',
                              hintText: 'Min 6 characters',
                              prefixIcon:
                                  const Icon(LucideIcons.lock, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  size: 18,
                                ),
                                onPressed: () => setDialogState(
                                    () => obscurePassword = !obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Password is required for login';
                              }
                              if (v.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Pharmacist Info
                    const Text(
                      'Qualified Pharmacist Details',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: pharmacistNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pharmacist Name',
                              hintText: 'Dr. Ahmad Jan',
                              prefixIcon:
                                  Icon(LucideIcons.stethoscope, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: pharmacistRegCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pharmacist Reg #',
                              hintText: 'PHA-12345',
                              prefixIcon:
                                  Icon(LucideIcons.fileSignature, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 4: Location & Contact
                    const Text(
                      'Location & Contact Information',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: province,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                              prefixIcon: Icon(LucideIcons.map, size: 18),
                            ),
                            items: _provincesList
                                .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => province = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'e.g. Peshawar',
                              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Street Address',
                              hintText: 'Shop #, Street, Area',
                              prefixIcon: Icon(LucideIcons.home, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Official Phone',
                              hintText: '+923001234567',
                              prefixIcon: Icon(LucideIcons.phone, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 5: License Dates
                    const Text(
                      'License Validity Dates',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: licenseIssueDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2045),
                              );
                              if (picked != null) {
                                setDialogState(() => licenseIssueDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'License Issue Date',
                                prefixIcon:
                                    Icon(LucideIcons.calendar, size: 18),
                              ),
                              child: Text(
                                _formatDate(licenseIssueDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: licenseIssueDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: licenseExpiryDate ??
                                    DateTime.now()
                                        .add(const Duration(days: 365 * 2)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2045),
                              );
                              if (picked != null) {
                                setDialogState(
                                    () => licenseExpiryDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'License Expiry Date',
                                prefixIcon:
                                    Icon(LucideIcons.calendarCheck, size: 18),
                              ),
                              child: Text(
                                _formatDate(licenseExpiryDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: licenseExpiryDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 6: Plan & Currency
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currency,
                            decoration:
                                const InputDecoration(labelText: 'Currency'),
                            items: const [
                              DropdownMenuItem(value: 'Rs', child: Text('Rs')),
                              DropdownMenuItem(
                                  value: 'USD', child: Text('USD (\$)')),
                              DropdownMenuItem(
                                  value: 'EUR', child: Text('EUR (€)')),
                              DropdownMenuItem(
                                  value: 'GBP', child: Text('GBP (£)')),
                              DropdownMenuItem(
                                  value: 'AED', child: Text('AED')),
                              DropdownMenuItem(
                                  value: 'SAR', child: Text('SAR')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => currency = v ?? 'Rs'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: plan,
                            decoration:
                                const InputDecoration(labelText: 'Plan'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Standard', child: Text('Standard')),
                              DropdownMenuItem(
                                  value: 'Professional',
                                  child: Text('Professional')),
                              DropdownMenuItem(
                                  value: 'Enterprise',
                                  child: Text('Enterprise')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => plan = v ?? 'Standard'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                                labelText: 'Approval Status'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Approved (Active)')),
                              DropdownMenuItem(
                                  value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(
                                  value: 'suspended', child: Text('Suspended')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => status = v ?? 'approved'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: planDays,
                            decoration:
                                const InputDecoration(labelText: 'Validity'),
                            items: const [
                              DropdownMenuItem(
                                  value: 30, child: Text('30 Days')),
                              DropdownMenuItem(
                                  value: 90, child: Text('3 Months')),
                              DropdownMenuItem(
                                  value: 180, child: Text('6 Months')),
                              DropdownMenuItem(
                                  value: 365, child: Text('1 Year')),
                              DropdownMenuItem(
                                  value: 730, child: Text('2 Years')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => planDays = v ?? 365),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Create Pharmacy',
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(superAdminActionControllerProvider.notifier)
                      .addPharmacy(
                        name: nameCtrl.text,
                        registrationNumber: regNumberCtrl.text.trim().isEmpty
                            ? null
                            : regNumberCtrl.text.trim(),
                        drugSaleLicense: dslCtrl.text.trim().isEmpty
                            ? null
                            : dslCtrl.text.trim(),
                        ownerName: ownerNameCtrl.text.trim().isEmpty
                            ? null
                            : ownerNameCtrl.text.trim(),
                        pharmacistName: pharmacistNameCtrl.text.trim().isEmpty
                            ? null
                            : pharmacistNameCtrl.text.trim(),
                        pharmacistRegistration:
                            pharmacistRegCtrl.text.trim().isEmpty
                                ? null
                                : pharmacistRegCtrl.text.trim(),
                        cnic: cnicCtrl.text.trim().isEmpty
                            ? null
                            : cnicCtrl.text.trim(),
                        province: province,
                        licenseIssueDate: licenseIssueDate,
                        licenseExpiryDate: licenseExpiryDate,
                        ownerEmail: ownerEmailCtrl.text.trim(),
                        ownerPassword: ownerPasswordCtrl.text.trim(),
                        ownerFullName: ownerNameCtrl.text.trim().isEmpty
                            ? null
                            : ownerNameCtrl.text.trim(),
                        city: cityCtrl.text.isEmpty ? null : cityCtrl.text,
                        address:
                            addressCtrl.text.isEmpty ? null : addressCtrl.text,
                        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                        licenseNo: dslCtrl.text.trim().isEmpty
                            ? null
                            : dslCtrl.text.trim(),
                        currency: currency,
                        plan: plan,
                        planDays: planDays,
                        approvalStatus: status,
                      );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Pharmacy "${nameCtrl.text}" created! Owner can login with ${ownerEmailCtrl.text.trim()}'),
                      backgroundColor: AppColorsTokens.success,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to add pharmacy: $e'),
                      backgroundColor: AppColorsTokens.danger,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPharmacyDialog(PharmacyModel pharmacy) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: pharmacy.name);
    final regNumberCtrl =
        TextEditingController(text: pharmacy.registrationNumber ?? '');
    final dslCtrl = TextEditingController(
        text: pharmacy.drugSaleLicense ?? pharmacy.licenseNo ?? '');
    final ownerNameCtrl =
        TextEditingController(text: pharmacy.ownerName ?? '');
    final pharmacistNameCtrl =
        TextEditingController(text: pharmacy.pharmacistName ?? '');
    final pharmacistRegCtrl =
        TextEditingController(text: pharmacy.pharmacistRegistration ?? '');
    final cnicCtrl = TextEditingController(text: pharmacy.cnic ?? '');
    final emailCtrl = TextEditingController(
        text: pharmacy.email ?? pharmacy.ownerEmail ?? '');
    final addressCtrl = TextEditingController(text: pharmacy.address ?? '');
    final cityCtrl = TextEditingController(text: pharmacy.city ?? '');
    final phoneCtrl = TextEditingController(text: pharmacy.phone ?? '');

    String province = pharmacy.province ?? 'Khyber Pakhtunkhwa';
    DateTime? licenseIssueDate = pharmacy.licenseIssueDate;
    DateTime? licenseExpiryDate = pharmacy.licenseExpiryDate;

    String currency =
        pharmacy.currency.isNotEmpty ? pharmacy.currency : 'Rs';
    String plan = pharmacy.plan ?? 'Standard';
    String status = pharmacy.approvalStatus.value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
          ),
          title: Text('Edit "${pharmacy.name}" (Super Admin)'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Pharmacy Name & Reg
                    const Text(
                      'Pharmacy & Pakistani Regulatory Licenses',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pharmacy Name *',
                        prefixIcon: Icon(LucideIcons.building2, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: regNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reg Number',
                              hintText: 'e.g. PC-2026-78452',
                              prefixIcon: Icon(LucideIcons.hash, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: dslCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Drug Sale License',
                              hintText: 'e.g. DSL-KP-458921',
                              prefixIcon:
                                  Icon(LucideIcons.shieldCheck, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Owner & Pharmacist
                    const Text(
                      'Personnel & CNIC',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ownerNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              prefixIcon: Icon(LucideIcons.user, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cnicCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner CNIC',
                              hintText: '14xxx-xxxxxxx-x',
                              prefixIcon:
                                  Icon(LucideIcons.creditCard, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: pharmacistNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pharmacist Name',
                              prefixIcon:
                                  Icon(LucideIcons.stethoscope, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: pharmacistRegCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pharmacist Reg #',
                              hintText: 'PHA-12345',
                              prefixIcon:
                                  Icon(LucideIcons.fileSignature, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Contact & Location
                    const Text(
                      'Contact & Location',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: province,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                              prefixIcon: Icon(LucideIcons.map, size: 18),
                            ),
                            items: _provincesList
                                .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => province = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(LucideIcons.home, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(LucideIcons.phone, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Owner / Pharmacy Email',
                        prefixIcon: Icon(LucideIcons.mail, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 4: License Dates
                    const Text(
                      'License Validity Dates',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsTokens.brand),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: licenseIssueDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2045),
                              );
                              if (picked != null) {
                                setDialogState(() => licenseIssueDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'License Issue Date',
                                prefixIcon:
                                    Icon(LucideIcons.calendar, size: 18),
                              ),
                              child: Text(
                                _formatDate(licenseIssueDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: licenseIssueDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: licenseExpiryDate ??
                                    DateTime.now()
                                        .add(const Duration(days: 365 * 2)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2045),
                              );
                              if (picked != null) {
                                setDialogState(
                                    () => licenseExpiryDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'License Expiry Date',
                                prefixIcon:
                                    Icon(LucideIcons.calendarCheck, size: 18),
                              ),
                              child: Text(
                                _formatDate(licenseExpiryDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: licenseExpiryDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 5: Plan, Status & Currency
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currency,
                            decoration:
                                const InputDecoration(labelText: 'Currency'),
                            items: const [
                              DropdownMenuItem(value: 'Rs', child: Text('Rs')),
                              DropdownMenuItem(
                                  value: 'USD', child: Text('USD (\$)')),
                              DropdownMenuItem(
                                  value: 'EUR', child: Text('EUR (€)')),
                              DropdownMenuItem(
                                  value: 'GBP', child: Text('GBP (£)')),
                              DropdownMenuItem(
                                  value: 'AED', child: Text('AED')),
                              DropdownMenuItem(
                                  value: 'SAR', child: Text('SAR')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => currency = v ?? 'Rs'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: plan,
                            decoration:
                                const InputDecoration(labelText: 'Plan Tier'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Standard', child: Text('Standard')),
                              DropdownMenuItem(
                                  value: 'Professional',
                                  child: Text('Professional')),
                              DropdownMenuItem(
                                  value: 'Enterprise',
                                  child: Text('Enterprise')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => plan = v ?? 'Standard'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'suspended', child: Text('Suspended')),
                        DropdownMenuItem(
                            value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => status = v ?? 'approved'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Save Changes',
              icon:
                  const Icon(LucideIcons.check, size: 16, color: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(superAdminActionControllerProvider.notifier)
                      .updatePharmacy(
                        pharmacyId: pharmacy.id,
                        name: nameCtrl.text,
                        registrationNumber: regNumberCtrl.text.trim().isEmpty
                            ? null
                            : regNumberCtrl.text.trim(),
                        drugSaleLicense: dslCtrl.text.trim().isEmpty
                            ? null
                            : dslCtrl.text.trim(),
                        ownerName: ownerNameCtrl.text.trim().isEmpty
                            ? null
                            : ownerNameCtrl.text.trim(),
                        pharmacistName: pharmacistNameCtrl.text.trim().isEmpty
                            ? null
                            : pharmacistNameCtrl.text.trim(),
                        pharmacistRegistration:
                            pharmacistRegCtrl.text.trim().isEmpty
                                ? null
                                : pharmacistRegCtrl.text.trim(),
                        cnic: cnicCtrl.text.trim().isEmpty
                            ? null
                            : cnicCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty
                            ? null
                            : emailCtrl.text.trim(),
                        province: province,
                        licenseIssueDate: licenseIssueDate,
                        licenseExpiryDate: licenseExpiryDate,
                        city: cityCtrl.text.isEmpty ? null : cityCtrl.text,
                        address:
                            addressCtrl.text.isEmpty ? null : addressCtrl.text,
                        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                        licenseNo: dslCtrl.text.trim().isEmpty
                            ? null
                            : dslCtrl.text.trim(),
                        currency: currency,
                        plan: plan,
                        approvalStatus: status,
                      );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Pharmacy "${nameCtrl.text}" updated successfully!'),
                      backgroundColor: AppColorsTokens.success,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update: $e'),
                      backgroundColor: AppColorsTokens.danger,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePharmacyDialog(PharmacyModel pharmacy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.triangleAlert,
                color: AppColorsTokens.danger, size: 24),
            SizedBox(width: 8),
            Text('Delete Pharmacy?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${pharmacy.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Delete',
            variant: AppButtonVariant.danger,
            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(superAdminActionControllerProvider.notifier)
                    .deletePharmacy(pharmacy.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pharmacy "${pharmacy.name}" deleted.'),
                      backgroundColor: AppColorsTokens.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: AppColorsTokens.danger,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(PharmacyModel pharmacy) {
    String selectedPlan = pharmacy.requestedPlan ?? pharmacy.plan ?? 'Standard';
    int extendDays = pharmacy.requestedPlanDays ?? 365;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Subscription: ${pharmacy.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pharmacy.isPlanUpgradePending) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles,
                          size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pharmacy requested upgrade to ${pharmacy.requestedPlan} (${pharmacy.requestedPlanDays ?? 365} Days)!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Current Status: ${pharmacy.approvalStatus.label.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (pharmacy.planExpiresAt != null)
                Text(
                  'Expires At: ${pharmacy.planExpiresAt!.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: pharmacy.isSubscriptionExpired
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPlan,
                decoration: const InputDecoration(labelText: 'Plan Tier'),
                items: const [
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(
                      value: 'Professional', child: Text('Professional')),
                  DropdownMenuItem(
                      value: 'Enterprise', child: Text('Enterprise')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlan = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: extendDays,
                decoration:
                    const InputDecoration(labelText: 'Extend Validity By'),
                items: const [
                  DropdownMenuItem(
                      value: 30, child: Text('+30 Days (1 Month)')),
                  DropdownMenuItem(
                      value: 90, child: Text('+90 Days (3 Months)')),
                  DropdownMenuItem(
                      value: 180, child: Text('+180 Days (6 Months)')),
                  DropdownMenuItem(
                      value: 365, child: Text('+365 Days (1 Year)')),
                  DropdownMenuItem(
                      value: -1,
                      child: Text('Expire Immediately (Suspend access)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => extendDays = val);
                },
              ),
            ],
          ),
          actions: [
            if (pharmacy.isPlanUpgradePending)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(superAdminActionControllerProvider.notifier)
                        .rejectPlanUpgrade(pharmacyId: pharmacy.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan upgrade request rejected.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to reject request: $e'),
                          backgroundColor: AppColorsTokens.danger,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Reject Upgrade',
                    style: TextStyle(color: AppColorsTokens.danger)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final newExpiry = extendDays == -1
                    ? DateTime.now().subtract(const Duration(days: 1))
                    : DateTime.now().add(Duration(days: extendDays));

                try {
                  await ref
                      .read(superAdminActionControllerProvider.notifier)
                      .updateSubscription(
                        pharmacyId: pharmacy.id,
                        plan: selectedPlan,
                        expiresAt: newExpiry,
                      );
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Subscription updated for "${pharmacy.name}".'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error updating subscription: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspendDialog(PharmacyModel pharmacy) {
    final reasonController = TextEditingController();
    final isSuspended = pharmacy.approvalStatus.isSuspended;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSuspended
            ? 'Reactivate "${pharmacy.name}"?'
            : 'Suspend "${pharmacy.name}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuspended
                  ? 'Reactivating will restore full access for all staff members of this pharmacy.'
                  : 'Suspending will immediately lock this pharmacy into the status screen. Staff will not be able to sell or manage inventory.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            if (!isSuspended) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Suspension *',
                  hintText:
                      'e.g. Non-payment of subscription or audit investigation',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(superAdminActionControllerProvider.notifier)
                    .reviewPharmacy(
                      pharmacyId: pharmacy.id,
                      action: isSuspended ? 'reactivated' : 'suspended',
                      reason: isSuspended ? null : reasonController.text,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSuspended
                            ? 'Pharmacy "${pharmacy.name}" reactivated.'
                            : 'Pharmacy "${pharmacy.name}" suspended.',
                      ),
                      backgroundColor:
                          isSuspended ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Action failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSuspended ? AppColors.success : AppColors.error,
            ),
            child: Text(isSuspended ? 'Reactivate' : 'Suspend Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final statusFilter = ref.watch(pharmacyFilterStatusProvider);
    final pharmaciesAsync = ref.watch(allPharmaciesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Title & Refresh
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('All Tenant Pharmacies', style: tokens.typography.pageTitle),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(allPharmaciesProvider),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: 'Add Pharmacy',
                  icon: const Icon(LucideIcons.plus,
                      size: 16, color: Colors.white),
                  onPressed: _showAddPharmacyDialog,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter & Search Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
            border: Border.all(color: tokens.colors.line),
            boxShadow: [tokens.colors.shadow],
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by pharmacy name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(pharmacySearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(pharmacySearchQueryProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('All', 'all', statusFilter),
                    const SizedBox(width: 8),
                    _statusChip('Pending', 'pending', statusFilter),
                    const SizedBox(width: 8),
                    _statusChip('Approved', 'approved', statusFilter),
                    const SizedBox(width: 8),
                    _statusChip('Suspended', 'suspended', statusFilter),
                    const SizedBox(width: 8),
                    _statusChip('Rejected', 'rejected', statusFilter),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        pharmaciesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text('Error: $err'),
            ),
          ),
          data: (pharmacies) {
            if (pharmacies.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('No pharmacies found matching the criteria.'),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pharmacies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ph = pharmacies[index];
                final isExpired = ph.isSubscriptionExpired;

                Color statusColor = AppColors.warning;
                if (ph.approvalStatus.isApproved) {
                  statusColor = isExpired ? AppColors.error : AppColors.success;
                } else if (ph.approvalStatus.isRejected ||
                    ph.approvalStatus.isSuspended) {
                  statusColor = AppColors.error;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                    border: Border.all(color: tokens.colors.line),
                    boxShadow: [tokens.colors.shadow],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.local_pharmacy,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    ph.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isExpired
                                        ? 'EXPIRED'
                                        : ph.approvalStatus.label.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ph.city ?? 'No city'}${ph.province != null ? ' (${ph.province})' : ''} • Owner: ${ph.ownerName ?? 'N/A'} • Reg: ${ph.registrationNumber ?? 'N/A'} • DSL: ${ph.drugSaleLicense ?? ph.licenseNo ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  'Plan: ${ph.plan ?? 'Standard'} • Expires: ${ph.planExpiresAt != null ? ph.planExpiresAt!.toLocal().toString().split(' ')[0] : 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                if (ph.isPlanUpgradePending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Text(
                                      'Upgrade Requested: ${ph.requestedPlan}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (ph.ownerEmail != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(LucideIcons.user,
                                      size: 13, color: AppColorsTokens.brand),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Owner: ${ph.ownerEmail!}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColorsTokens.brand,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditPharmacyDialog(ph);
                          } else if (val == 'plan') {
                            _showSubscriptionDialog(ph);
                          } else if (val == 'suspend') {
                            _showSuspendDialog(ph);
                          } else if (val == 'delete') {
                            _showDeletePharmacyDialog(ph);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(LucideIcons.filePen, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'plan',
                            child: Row(
                              children: [
                                Icon(LucideIcons.creditCard, size: 18),
                                SizedBox(width: 8),
                                Text('Subscription Plan'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'suspend',
                            child: Row(
                              children: [
                                Icon(
                                  ph.approvalStatus.isSuspended
                                      ? LucideIcons.play
                                      : LucideIcons.pause,
                                  size: 18,
                                  color: ph.approvalStatus.isSuspended
                                      ? AppColorsTokens.success
                                      : AppColorsTokens.amber,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ph.approvalStatus.isSuspended
                                      ? 'Reactivate'
                                      : 'Suspend',
                                  style: TextStyle(
                                    color: ph.approvalStatus.isSuspended
                                        ? AppColorsTokens.success
                                        : AppColorsTokens.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: AppColorsTokens.danger,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Pharmacy',
                                  style:
                                      TextStyle(color: AppColorsTokens.danger),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statusChip(String label, String value, String current) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) {
          ref.read(pharmacyFilterStatusProvider.notifier).state = value;
        }
      },
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color:
            isSelected ? AppColors.primaryDark : AppColors.textSecondaryLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
