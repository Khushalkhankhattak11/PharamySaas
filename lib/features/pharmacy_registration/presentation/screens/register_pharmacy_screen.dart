import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/pharmacy_registration_controller.dart';

class RegisterPharmacyScreen extends ConsumerStatefulWidget {
  const RegisterPharmacyScreen({super.key});

  @override
  ConsumerState<RegisterPharmacyScreen> createState() =>
      _RegisterPharmacyScreenState();
}

class _RegisterPharmacyScreenState
    extends ConsumerState<RegisterPharmacyScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // 14 Required Pakistani Pharmacy Regulatory Fields
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _dslController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _pharmacistNameController = TextEditingController();
  final _pharmacistRegController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedProvince = 'Khyber Pakhtunkhwa';
  final List<String> _provinces = [
    'Khyber Pakhtunkhwa',
    'Punjab',
    'Sindh',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu & Kashmir',
  ];

  DateTime? _licenseIssueDate;
  DateTime? _licenseExpiryDate;

  String _selectedCurrency = 'Rs';
  final List<String> _currencies = [
    'Rs',
    'USD',
    'EUR',
    'GBP',
    'SAR',
    'AED',
  ];

  Uint8List? _licenseDocBytes;
  String? _licenseDocName;
  Uint8List? _logoBytes;
  String? _logoName;

  static final _phoneRegex = RegExp(r'^\+92\d{10}$');
  static final _cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
  static final _dslRegex =
      RegExp(r'^DSL-[A-Za-z]{2,4}-\d{4,8}$', caseSensitive: false);
  static final _regNumberRegex =
      RegExp(r'^PC-\d{4}-\d{4,7}$', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    // Pre-fill email and user name from auth state if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email != null && _emailController.text.isEmpty) {
          _emailController.text = user.email!;
        }
        if (user.displayName != null && _ownerNameController.text.isEmpty) {
          _ownerNameController.text = user.displayName!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _dslController.dispose();
    _ownerNameController.dispose();
    _pharmacistNameController.dispose();
    _pharmacistRegController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _cleanPhone(String raw) => raw.replaceAll(RegExp(r'[\s\-]'), '');

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_licenseIssueDate == null || _licenseExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both License Issue and Expiry Dates'),
          backgroundColor: AppColorsTokens.danger,
        ),
      );
      return;
    }

    if (_licenseExpiryDate!.isBefore(_licenseIssueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('License Expiry Date must be after Issue Date'),
          backgroundColor: AppColorsTokens.danger,
        ),
      );
      return;
    }

    try {
      final cleanedPhone = _cleanPhone(_phoneController.text.trim());

      await ref
          .read(pharmacyRegistrationControllerProvider.notifier)
          .registerPharmacy(
            name: _nameController.text.trim(),
            registrationNumber: _regNumberController.text.trim().toUpperCase(),
            drugSaleLicense: _dslController.text.trim().toUpperCase(),
            ownerName: _ownerNameController.text.trim(),
            pharmacistName: _pharmacistNameController.text.trim(),
            pharmacistRegistration:
                _pharmacistRegController.text.trim().toUpperCase(),
            cnic: _cnicController.text.trim(),
            phone: cleanedPhone,
            email: _emailController.text.trim(),
            province: _selectedProvince,
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            licenseIssueDate: _licenseIssueDate!,
            licenseExpiryDate: _licenseExpiryDate!,
            currency: _selectedCurrency,
            licenseDocBytes: _licenseDocBytes,
            licenseDocName: _licenseDocName,
            logoBytes: _logoBytes,
            logoName: _logoName,
          );

      if (mounted) {
        context.go('/approval-status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString()}'),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showToast('Please enter Pharmacy Name');
        return;
      }
      final regNo = _regNumberController.text.trim();
      if (regNo.isEmpty || !_regNumberRegex.hasMatch(regNo)) {
        _showToast(
            'Invalid Registration Number. Expected format: PC-2026-78452');
        return;
      }
      final dsl = _dslController.text.trim();
      if (dsl.isEmpty || !_dslRegex.hasMatch(dsl)) {
        _showToast(
            'Invalid Drug Sale License. Expected format: DSL-KP-458921');
        return;
      }
    } else if (_currentStep == 1) {
      if (_ownerNameController.text.trim().isEmpty) {
        _showToast('Please enter Owner Name');
        return;
      }
      if (_pharmacistNameController.text.trim().isEmpty) {
        _showToast('Please enter Pharmacist Name');
        return;
      }
      if (_pharmacistRegController.text.trim().isEmpty) {
        _showToast('Please enter Pharmacist Registration Number');
        return;
      }
      final cnic = _cnicController.text.trim();
      if (cnic.isEmpty || !_cnicRegex.hasMatch(cnic)) {
        _showToast('Invalid CNIC format. Expected format: 14xxx-xxxxxxx-x');
        return;
      }
    } else if (_currentStep == 2) {
      final phone = _cleanPhone(_phoneController.text.trim());
      if (phone.isEmpty || !_phoneRegex.hasMatch(phone)) {
        _showToast(
            'Invalid Phone number. Format must be +92 followed by 10 digits (e.g. +923001234567)');
        return;
      }
      if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        _showToast('Please enter a valid official Email address');
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        _showToast('Please enter City');
        return;
      }
      if (_addressController.text.trim().isEmpty) {
        _showToast('Please enter Street Address');
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _handleSubmit();
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsTokens.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseIssueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _licenseIssueDate = picked);
    }
  }

  Future<void> _pickExpiryDate() async {
    final base = _licenseIssueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? base.add(const Duration(days: 365 * 2)),
      firstDate: base,
      lastDate: DateTime(2045),
    );
    if (picked != null) {
      setState(() => _licenseExpiryDate = picked);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not selected';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final regState = ref.watch(pharmacyRegistrationControllerProvider);
    final isLoading = regState.isLoading;

    final steps = [
      'Pharmacy & Licenses',
      'Personnel & CNIC',
      'Location & Contact',
      'Dates & Verification',
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: tokens.colors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: tokens.colors.card,
                    borderRadius:
                        BorderRadius.circular(AppRadiusTokens.largeCard),
                    border: Border.all(color: tokens.colors.line, width: 1),
                    boxShadow: [tokens.colors.shadow],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Register Pharmacy',
                                  style: tokens.typography.pageTitle
                                      .copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Step ${_currentStep + 1} of 4: ${steps[_currentStep]}',
                                  style: tokens.typography.cardSubtitle,
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signOut();
                                context.go('/login');
                              },
                              icon: const Icon(LucideIcons.logOut, size: 16),
                              label: const Text('Logout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 4-step progress tracker
                        Row(
                          children: List.generate(4, (index) {
                            final isDone = index < _currentStep;
                            final isCurrent = index == _currentStep;

                            return Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isDone || isCurrent
                                            ? AppColorsTokens.brand
                                            : tokens.colors.track,
                                        borderRadius: BorderRadius.circular(
                                            AppRadiusTokens.pill),
                                      ),
                                    ),
                                  ),
                                  if (index < 3) const SizedBox(width: 6),
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),

                        // Stepper content
                        if (_currentStep == 0) _buildStep1(tokens),
                        if (_currentStep == 1) _buildStep2(tokens),
                        if (_currentStep == 2) _buildStep3(tokens),
                        if (_currentStep == 3) _buildStep4(tokens),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            if (_currentStep > 0) ...[
                              AppButton.ghost(
                                text: 'Back',
                                onPressed: isLoading ? null : _prevStep,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: AppButton(
                                text: _currentStep == 3
                                    ? 'Submit Pharmacy Registration'
                                    : 'Next Step',
                                isLoading: isLoading,
                                radius: 12,
                                height: 48,
                                onPressed: isLoading ? null : _nextStep,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 1: Pharmacy Name, Registration Number, Drug Sale License, Currency
  Widget _buildStep1(AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Pharmacy Name', tokens),
        TextFormField(
          controller: _nameController,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, 'e.g. City Central Pharmacy', LucideIcons.building),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Pharmacy name is required'
              : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Registration Number (Format: PC-YYYY-NNNNN)', tokens),
        TextFormField(
          controller: _regNumberController,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, 'e.g. PC-2026-78452', LucideIcons.hash),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Registration number is required';
            }
            if (!_regNumberRegex.hasMatch(v.trim())) {
              return 'Format must be PC-YYYY-NNNNN (e.g. PC-2026-78452)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Drug Sale License (Format: DSL-KP-458921)', tokens),
        TextFormField(
          controller: _dslController,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, 'e.g. DSL-KP-458921', LucideIcons.shieldCheck),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Drug sale license number is required';
            }
            if (!_dslRegex.hasMatch(v.trim())) {
              return 'Format must be DSL-XX-XXXXXX (e.g. DSL-KP-458921)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Currency', tokens),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tokens.isDark ? tokens.colors.track : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.colors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCurrency = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Owner Name, Pharmacist Name, Pharmacist Registration, CNIC
  Widget _buildStep2(AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Owner Name', tokens),
        TextFormField(
          controller: _ownerNameController,
          style: tokens.typography.body,
          decoration:
              _inputDecoration(tokens, 'e.g. Khushal Khan', LucideIcons.user),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Owner name is required' : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Pharmacist Name', tokens),
        TextFormField(
          controller: _pharmacistNameController,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, 'e.g. Dr. Ahmad Jan (Pharm-D)', LucideIcons.stethoscope),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Pharmacist name is required'
              : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Pharmacist Registration (e.g. PHA-12345)', tokens),
        TextFormField(
          controller: _pharmacistRegController,
          style: tokens.typography.body,
          decoration: _inputDecoration(tokens, 'e.g. PHA-12345 / PR-78452',
              LucideIcons.fileSignature),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Pharmacist registration is required'
              : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Owner CNIC (Format: 14xxx-xxxxxxx-x)', tokens),
        TextFormField(
          controller: _cnicController,
          style: tokens.typography.body,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
              tokens, 'e.g. 14301-1234567-1', LucideIcons.creditCard),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'CNIC is required';
            if (!_cnicRegex.hasMatch(v.trim())) {
              return 'Format must be 14xxx-xxxxxxx-x (5-7-1 digits)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // STEP 3: Phone, Email, Province, City, Address
  Widget _buildStep3(AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Official Phone (Format: +92 followed by 10 digits)', tokens),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, '+923001234567', LucideIcons.phone),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone is required';
            final clean = _cleanPhone(v.trim());
            if (!_phoneRegex.hasMatch(clean)) {
              return 'Must be in format +92 followed by 10 digits (e.g. +923001234567)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Official Email', tokens),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: tokens.typography.body,
          decoration:
              _inputDecoration(tokens, 'owner@pharmacy.com', LucideIcons.mail),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Province', tokens),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tokens.isDark ? tokens.colors.track : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.colors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProvince,
              isExpanded: true,
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedProvince = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('City', tokens),
        TextFormField(
          controller: _cityController,
          style: tokens.typography.body,
          decoration: _inputDecoration(
              tokens, 'e.g. Peshawar / Lahore / Karachi', LucideIcons.mapPin),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'City is required' : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Full Street Address', tokens),
        TextFormField(
          controller: _addressController,
          style: tokens.typography.body,
          decoration: _inputDecoration(tokens,
              'e.g. Shop #4, Khyber Medical Complex, Saddar', LucideIcons.home),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Address is required' : null,
        ),
      ],
    );
  }

  // STEP 4: License Issue Date, License Expiry Date, Document & Logo Upload, Review Summary
  Widget _buildStep4(AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('License Issue Date', tokens),
                  InkWell(
                    onTap: _pickIssueDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tokens.isDark ? tokens.colors.track : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendar,
                              size: 18, color: tokens.colors.muted),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(_licenseIssueDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _licenseIssueDate != null
                                  ? tokens.colors.ink
                                  : tokens.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('License Expiry Date', tokens),
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tokens.isDark ? tokens.colors.track : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendarCheck,
                              size: 18, color: tokens.colors.muted),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(_licenseExpiryDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _licenseExpiryDate != null
                                  ? tokens.colors.ink
                                  : tokens.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _fieldLabel('License Document / Certificate', tokens),
        InkWell(
          onTap: () {
            setState(() {
              _licenseDocBytes = Uint8List.fromList([1, 2, 3]);
              _licenseDocName = 'drug_sale_license.pdf';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.colors.track,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.colors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _licenseDocBytes != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.uploadCloud,
                  color: _licenseDocBytes != null
                      ? AppColorsTokens.success
                      : tokens.colors.muted,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _licenseDocName ?? 'Attach License PDF or Scanned Copy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _licenseDocBytes != null
                        ? AppColorsTokens.success
                        : tokens.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Pharmacy Logo (Optional)', tokens),
        InkWell(
          onTap: () {
            setState(() {
              _logoBytes = Uint8List.fromList([1, 2, 3]);
              _logoName = 'pharmacy_logo.png';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.colors.track,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.colors.line),
            ),
            child: Row(
              children: [
                Icon(
                  _logoBytes != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.image,
                  color: _logoBytes != null
                      ? AppColorsTokens.success
                      : tokens.colors.muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _logoName ?? 'Upload Logo Image (PNG / JPG)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _logoBytes != null
                        ? AppColorsTokens.success
                        : tokens.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Comprehensive Review Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.colors.track,
            borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
            border: Border.all(color: tokens.colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Regulatory Compliance Summary',
                  style: tokens.typography.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 10),
              _summaryRow('Pharmacy Name:', _nameController.text),
              _summaryRow('Reg. Number:', _regNumberController.text),
              _summaryRow('Drug Sale License:', _dslController.text),
              _summaryRow('Owner Name:', _ownerNameController.text),
              _summaryRow('Pharmacist:', _pharmacistNameController.text),
              _summaryRow('Pharmacist Reg:', _pharmacistRegController.text),
              _summaryRow('CNIC:', _cnicController.text),
              _summaryRow('Phone:', _cleanPhone(_phoneController.text)),
              _summaryRow('Province & City:', '$_selectedProvince, ${_cityController.text}'),
              _summaryRow('License Validity:', '${_formatDate(_licenseIssueDate)} to ${_formatDate(_licenseExpiryDate)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, AppTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tokens.colors.ink,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B6567))),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      AppTokens tokens, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: tokens.colors.muted),
      filled: true,
      fillColor: tokens.isDark ? tokens.colors.track : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColorsTokens.focusRing, width: 2),
      ),
    );
  }
}
