import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/firebase/firebase_providers.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/models/profile_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/plan_card.dart';
import '../../../../shared/widgets/plan_upgrade_dialog.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Pharmacy Details Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  // Owner Profile Controllers
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  // Appearance & Custom Theme Controller
  final _customHexController = TextEditingController();
  bool _isHexInitialized = false;

  static const List<Color> _brandSwatches = [
    Color(0xFF0F766E), // Teal
    Color(0xFF059669), // Emerald
    Color(0xFF2563EB), // Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFFE11D48), // Rose
    Color(0xFFEA580C), // Orange
    Color(0xFF0284C7), // Sky
    Color(0xFFD97706), // Gold
    Color(0xFF334155), // Slate
  ];

  static const List<({String id, String name, bool isDark, Color brand1, Color brand2, Color glow, Color bg, int requiredTier})> _themePresets = [
    (id: 'ocean', name: 'Ocean', isDark: false, brand1: Color(0xFF1D4ED8), brand2: Color(0xFF0B2A6F), glow: Color(0xFF38BDF8), bg: Color(0xFFF3F8FF), requiredTier: 1),
    (id: 'violet', name: 'Violet', isDark: false, brand1: Color(0xFF7C3AED), brand2: Color(0xFF3B1B8F), glow: Color(0xFFC084FC), bg: Color(0xFFF7F4FF), requiredTier: 3),
    (id: 'midnight', name: 'Midnight', isDark: true, brand1: Color(0xFF0891B2), brand2: Color(0xFF0E2F63), glow: Color(0xFF22D3EE), bg: Color(0xFF070B16), requiredTier: 3),
    (id: 'emerald', name: 'Emerald', isDark: false, brand1: Color(0xFF059669), brand2: Color(0xFF065F46), glow: Color(0xFF34D399), bg: Color(0xFFF2FAF5), requiredTier: 2),
    (id: 'rose', name: 'Rose', isDark: false, brand1: Color(0xFFE11D48), brand2: Color(0xFF9F1239), glow: Color(0xFFFB7185), bg: Color(0xFFFFF5F7), requiredTier: 2),
    (id: 'sunset', name: 'Sunset', isDark: false, brand1: Color(0xFFF97316), brand2: Color(0xFFB91C1C), glow: Color(0xFFFBBF24), bg: Color(0xFFFFF6EF), requiredTier: 3),
    (id: 'graphite', name: 'Graphite', isDark: false, brand1: Color(0xFF1F2937), brand2: Color(0xFF0B1220), glow: Color(0xFF94A3B8), bg: Color(0xFFF6F7F9), requiredTier: 3),
    (id: 'lagoon', name: 'Lagoon', isDark: false, brand1: Color(0xFF0D9488), brand2: Color(0xFF155E75), glow: Color(0xFF5EEAD4), bg: Color(0xFFEFFCFB), requiredTier: 3),
    (id: 'forest', name: 'Forest', isDark: true, brand1: Color(0xFF16A34A), brand2: Color(0xFF14532D), glow: Color(0xFF4ADE80), bg: Color(0xFF07110C), requiredTier: 3),
    (id: 'aurora', name: 'Aurora', isDark: true, brand1: Color(0xFFA855F7), brand2: Color(0xFF4C1D95), glow: Color(0xFFF0ABFC), bg: Color(0xFF0D0817), requiredTier: 3),
  ];

  Color? _parseHexColor(String hex) {
    var cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final value = int.tryParse(cleanHex, radix: 16);
      if (value != null) return Color(value);
    }
    return null;
  }

  String _selectedCurrency = 'Rs';
  bool _isPharmacyInitialized = false;
  bool _isProfileInitialized = false;

  final List<String> _currencies = [
    'Rs',
    'USD',
    'EUR',
    'GBP',
    'SAR',
    'AED',
    'CAD',
    'AUD',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _customHexController.dispose();
    super.dispose();
  }

  void _populatePharmacyData(PharmacyModel pharmacy) {
    if (_isPharmacyInitialized) return;
    _isPharmacyInitialized = true;
    _nameController.text = pharmacy.name;
    _phoneController.text = pharmacy.phone ?? '';
    _addressController.text = pharmacy.address ?? '';
    _cityController.text = pharmacy.city ?? '';
    _headerController.text = pharmacy.receiptHeader ?? '';
    _footerController.text = pharmacy.receiptFooter ?? '';
    if (_currencies.contains(pharmacy.currency)) {
      _selectedCurrency = pharmacy.currency;
    }
  }

  void _populateProfileData(ProfileModel profile) {
    if (_isProfileInitialized) return;
    _isProfileInitialized = true;
    _ownerNameController.text = profile.fullName;
    _ownerPhoneController.text = profile.phone ?? '';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(settingsActionControllerProvider.notifier).updatePharmacy(
            name: _nameController.text,
            address: _addressController.text,
            city: _cityController.text,
            phone: _phoneController.text,
            currency: _selectedCurrency,
            receiptHeader: _headerController.text,
            receiptFooter: _footerController.text,
            ownerFullName: _ownerNameController.text,
            ownerPhone: _ownerPhoneController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pharmacy details and owner profile updated successfully!'),
            backgroundColor: AppColorsTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, String? email) {
    final passFormKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final tokens = context.tokens;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorsTokens.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                    ),
                    child: const Icon(LucideIcons.keyRound, size: 20, color: AppColorsTokens.brand),
                  ),
                  const SizedBox(width: 12),
                  const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: passFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email != null) ...[
                          Text(
                            'Updating login password for $email',
                            style: TextStyle(fontSize: 13, color: tokens.colors.muted),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (dialogError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColorsTokens.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                              border: Border.all(color: AppColorsTokens.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertTriangle, size: 16, color: AppColorsTokens.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogError!,
                                    style: const TextStyle(fontSize: 12, color: AppColorsTokens.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text('Current Password *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            hintText: 'Enter current password',
                            prefixIcon: const Icon(LucideIcons.lock, size: 16),
                            suffixIcon: IconButton(
                              icon: Icon(obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
                              onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Text('New Password *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            hintText: 'At least 6 characters',
                            prefixIcon: const Icon(LucideIcons.key, size: 16),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
                              onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'Must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text('Confirm New Password *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            hintText: 'Re-enter new password',
                            prefixIcon: const Icon(LucideIcons.checkCheck, size: 16),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
                              onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v != newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  text: 'Update Password',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!passFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            await ref.read(settingsActionControllerProvider.notifier).changePassword(
                                  currentPassword: currentPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password updated successfully!'),
                                  backgroundColor: AppColorsTokens.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final pharmacyAsync = ref.watch(currentPharmacyProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final isSaving = ref.watch(settingsActionControllerProvider).isLoading;
    final currentThemeMode = ref.watch(themeModeProvider);
    final activePreset = ref.watch(themePresetProvider);
    final customColor = ref.watch(customBrandColorProvider);

    if (!_isHexInitialized) {
      _customHexController.text = '#${customColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      _isHexInitialized = true;
    }

    return pharmacyAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (pharmacy) {
        if (pharmacy == null) {
          return const Center(child: Text('No pharmacy found'));
        }

        _populatePharmacyData(pharmacy);

        final profile = profileAsync.valueOrNull;
        if (profile != null) {
          _populateProfileData(profile);
        }

        final authUser = ref.watch(firebaseAuthProvider).currentUser;
        final ownerEmail = profile?.id != null
            ? (pharmacy.ownerEmail ?? authUser?.email ?? 'Account Linked')
            : (pharmacy.ownerEmail ?? authUser?.email);

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Owner Profile & Account Card
              SectionCard(
                title: 'Owner Account & Security',
                subtitle: 'Manage your administrator account credentials and personal profile',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email & Role banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.colors.track,
                        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final accountInfo = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColorsTokens.brand.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                                ),
                                child: const Icon(LucideIcons.user, size: 18, color: AppColorsTokens.brand),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          ownerEmail ?? 'Active Administrator',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        const StatusBadge(label: 'Owner / Admin', variant: StatusBadgeVariant.info),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Official owner login credential for this pharmacy branch',
                                      style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final changePassBtn = AppButton.secondary(
                            text: 'Change Password',
                            icon: const Icon(LucideIcons.keyRound, size: 15),
                            onPressed: () => _showChangePasswordDialog(context, ownerEmail),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                accountInfo,
                                const SizedBox(height: 12),
                                changePassBtn,
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: accountInfo),
                              const SizedBox(width: 16),
                              changePassBtn,
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Owner Full Name & Phone
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 550;
                        final nameField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Owner Full Name *',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _ownerNameController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Dr. John Doe',
                                prefixIcon: Icon(LucideIcons.userCheck, size: 16),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        );
                        final phoneField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Contact Phone',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _ownerPhoneController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. +92 300 1234567',
                                prefixIcon: Icon(LucideIcons.phone, size: 16),
                              ),
                            ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              nameField,
                              const SizedBox(height: 16),
                              phoneField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 16),
                            Expanded(child: phoneField),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Pharmacy Store Profile Card
              SectionCard(
                title: 'Pharmacy Profile',
                subtitle: 'Store identity and public contact details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 550;
                        final nameField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pharmacy Legal Name *',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  hintText: 'Pharmacy Name'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        );
                        final phoneField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Official Store Phone *',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                  hintText: 'Official Store Phone'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              nameField,
                              const SizedBox(height: 16),
                              phoneField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 16),
                            Expanded(child: phoneField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;
                        final addressField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Store Address',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                  hintText: 'Street Address'),
                            ),
                          ],
                        );
                        final cityField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('City',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cityController,
                              decoration:
                                  const InputDecoration(hintText: 'City'),
                            ),
                          ],
                        );
                        final currencyField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Currency',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.colors.ink)),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: tokens.colors.card,
                                borderRadius: BorderRadius.circular(
                                    AppRadiusTokens.pill),
                                border: Border.all(color: tokens.colors.line),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCurrency,
                                  isExpanded: true,
                                  items: _currencies
                                      .map((c) => DropdownMenuItem(
                                          value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedCurrency = v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              addressField,
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: cityField),
                                  const SizedBox(width: 16),
                                  Expanded(child: currencyField),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 2, child: addressField),
                            const SizedBox(width: 16),
                            Expanded(child: cityField),
                            const SizedBox(width: 16),
                            Expanded(child: currencyField),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Receipt Customization Card
              SectionCard(
                title: 'Receipt Header & Footer',
                subtitle:
                    'Custom messages printed on 80mm thermal customer receipts',
                child: Column(
                  children: [
                    if (pharmacy.isStandardPlan) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.sparkles,
                                size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Custom receipt headers & footers are enabled on the Professional and Enterprise plans.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => showPlanUpgradeDialog(context),
                              child: const Text('Upgrade Plan',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _headerController,
                      enabled: pharmacy.canUseCustomReceiptBranding,
                      decoration: InputDecoration(
                        labelText: 'Receipt Header Text',
                        hintText: pharmacy.canUseCustomReceiptBranding
                            ? 'e.g. Welcome to City Central Pharmacy! 24/7 Service.'
                            : 'Upgrade to Professional to customize receipt header',
                        prefixIcon: const Icon(LucideIcons.alignLeft),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _footerController,
                      enabled: pharmacy.canUseCustomReceiptBranding,
                      decoration: InputDecoration(
                        labelText: 'Receipt Footer Text',
                        hintText: pharmacy.canUseCustomReceiptBranding
                            ? 'e.g. Thank you for your visit. Goods once sold are not returnable without bill.'
                            : 'Upgrade to Professional to customize receipt footer',
                        prefixIcon: const Icon(LucideIcons.messageSquare),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Appearance & Themes Card
              SectionCard(
                title: 'Appearance & Themes',
                subtitle: 'Personalize your interface with color presets, dark mode, and custom branding',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Mode Switcher
                    Text(
                      'Display Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDisplayModeButton(
                          label: 'Light Mode',
                          icon: LucideIcons.sun,
                          mode: ThemeMode.light,
                          isSelected: currentThemeMode == ThemeMode.light,
                        ),
                        const SizedBox(width: 10),
                        _buildDisplayModeButton(
                          label: 'Dark Mode',
                          icon: LucideIcons.moon,
                          mode: ThemeMode.dark,
                          isSelected: currentThemeMode == ThemeMode.dark,
                        ),
                        const SizedBox(width: 10),
                        _buildDisplayModeButton(
                          label: 'System',
                          icon: LucideIcons.laptop,
                          mode: ThemeMode.system,
                          isSelected: currentThemeMode == ThemeMode.system,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Plan Theme Quota Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: tokens.colors.track,
                        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pharmacy.isEnterprisePlan
                                ? LucideIcons.crown
                                : (pharmacy.isProfessionalPlan ? LucideIcons.sparkles : LucideIcons.palette),
                            size: 16,
                            color: tokens.colors.brand1,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pharmacy.isEnterprisePlan
                                  ? 'Enterprise Plan: All 10 themes & custom branding unlocked'
                                  : (pharmacy.isProfessionalPlan
                                      ? 'Professional Plan: 3 selectable theme presets enabled'
                                      : 'Standard Plan: 1 theme preset (Ocean) enabled'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.colors.ink,
                              ),
                            ),
                          ),
                          if (!pharmacy.isEnterprisePlan)
                            TextButton(
                              onPressed: () => showPlanUpgradeDialog(context),
                              child: Text(
                                pharmacy.isProfessionalPlan ? 'Upgrade to Enterprise' : 'Upgrade Plan',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Presets Grid
                    Text(
                      'Theme Presets (10 Available)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth < 450
                            ? (constraints.maxWidth - 10) / 2
                            : (constraints.maxWidth < 750
                                ? (constraints.maxWidth - 20) / 3
                                : (constraints.maxWidth - 40) / 5);

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _themePresets.map((t) {
                            final isLocked = pharmacy.isStandardPlan
                                ? t.requiredTier > 1
                                : (pharmacy.isProfessionalPlan ? t.requiredTier > 2 : false);
                            final lockLabel = t.requiredTier == 2 ? 'Pro' : 'Enterprise';
                            final isSelected = activePreset.toLowerCase() == t.id.toLowerCase();

                            return SizedBox(
                              width: cardWidth.clamp(140.0, 260.0),
                              child: _buildThemeCard(
                                id: t.id,
                                name: t.name,
                                isDark: t.isDark,
                                brand1: t.brand1,
                                brand2: t.brand2,
                                glow: t.glow,
                                bg: t.bg,
                                isLocked: isLocked,
                                lockTier: lockLabel,
                                isSelected: isSelected,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Custom Brand Theme Section (Enterprise)
                    _buildCustomBrandingSection(context, pharmacy, activePreset, customColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Subscription & Plan Status
              SectionCard(
                title: 'Subscription & License',
                subtitle: 'Your active tier and regulatory credentials',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    const planCard = PlanCard();
                    final licenseCard = Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tokens.colors.track,
                        borderRadius:
                            BorderRadius.circular(AppRadiusTokens.tile),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('License Registration',
                              style: tokens.typography.cardTitle
                                  .copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('No: ${pharmacy.licenseNo ?? 'Not Specified'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const StatusBadge(
                              label: 'Verified & Active',
                              variant: StatusBadgeVariant.success),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          planCard,
                          const SizedBox(height: 16),
                          licenseCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Expanded(child: PlanCard()),
                        const SizedBox(width: 20),
                        Expanded(child: licenseCard),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Changes & Sign Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton.danger(
                    text: 'Sign Out Account',
                    icon: const Icon(LucideIcons.logOut,
                        size: 16, color: Colors.white),
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  AppButton(
                    text: 'Save All Changes',
                    icon: const Icon(LucideIcons.save,
                        size: 16, color: Colors.white),
                    isLoading: isSaving,
                    onPressed: isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayModeButton({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    final tokens = context.tokens;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? tokens.colors.brand1 : tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
            border: Border.all(
              color: isSelected ? tokens.colors.brand1 : tokens.colors.line,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tokens.colors.brand1.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : tokens.colors.ink,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : tokens.colors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String id,
    required String name,
    required bool isDark,
    required Color brand1,
    required Color brand2,
    required Color glow,
    required Color bg,
    required bool isLocked,
    required String lockTier,
    required bool isSelected,
  }) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () {
        if (isLocked) {
          showPlanUpgradeDialog(context);
        } else {
          ref.read(themePresetProvider.notifier).setThemePreset(id);
        }
      },
      borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.colors.card,
          borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
          border: Border.all(
            color: isSelected
                ? tokens.colors.brand1
                : (isLocked ? tokens.colors.line.withValues(alpha: 0.6) : tokens.colors.line),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tokens.colors.brand1.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color swatches row
            Row(
              children: [
                _buildColorDot(brand1),
                const SizedBox(width: 4),
                _buildColorDot(brand2),
                const SizedBox(width: 4),
                _buildColorDot(glow),
                const SizedBox(width: 4),
                _buildColorDot(bg, border: true),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorsTokens.success,
                    ),
                    child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                  )
                else if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.colors.track,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.lock, size: 10, color: tokens.colors.muted),
                        const SizedBox(width: 3),
                        Text(
                          lockTier,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tokens.colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isLocked ? tokens.colors.muted : tokens.colors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDark)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: tokens.colors.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dark',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, {bool border = false}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border ? Border.all(color: Colors.black12, width: 1) : null,
      ),
    );
  }

  Widget _buildCustomBrandingSection(
    BuildContext context,
    PharmacyModel pharmacy,
    String activePreset,
    Color customColor,
  ) {
    final tokens = context.tokens;
    final isCustomActive = activePreset.toLowerCase() == 'custom';

    if (!pharmacy.isEnterprisePlan) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.colors.track,
          borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
          border: Border.all(color: tokens.colors.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsTokens.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
              ),
              child: const Icon(LucideIcons.palette, size: 20, color: AppColorsTokens.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Custom Brand Theme & Color Derivation',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                        ),
                        child: const Text(
                          'Enterprise',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pick your own primary brand color to derive a completely custom, balanced theme palette across your entire pharmacy.',
                    style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => showPlanUpgradeDialog(context),
              child: const Text(
                'Upgrade Plan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colors.track,
        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        border: Border.all(
          color: isCustomActive ? tokens.colors.brand1 : tokens.colors.line,
          width: isCustomActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tokens.colors.brand1.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                ),
                child: Icon(LucideIcons.palette, size: 18, color: tokens.colors.brand1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Custom Brand Theme',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (isCustomActive)
                          const StatusBadge(label: 'Active Theme', variant: StatusBadgeVariant.success),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a brand color swatch or enter a hex code to automatically generate your pharmacy theme',
                      style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Swatches
          Text(
            'Quick Brand Palette Swatches',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.colors.ink),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _brandSwatches.map((color) {
              final isColorSelected = isCustomActive && customColor.toARGB32() == color.toARGB32();
              return InkWell(
                onTap: () {
                  _customHexController.text = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                  ref.read(customBrandColorProvider.notifier).setCustomBrandColor(color);
                  ref.read(themePresetProvider.notifier).setThemePreset('custom');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isColorSelected ? Colors.white : Colors.black12,
                      width: isColorSelected ? 2.5 : 1,
                    ),
                    boxShadow: isColorSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: isColorSelected
                      ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Hex Color Input Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final hexInput = TextFormField(
                controller: _customHexController,
                decoration: const InputDecoration(
                  labelText: 'Custom Brand Hex Code',
                  hintText: '#0F766E',
                  prefixIcon: Icon(LucideIcons.hash, size: 16),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              );

              final applyBtn = AppButton(
                text: 'Apply Custom Theme',
                icon: const Icon(LucideIcons.sparkles, size: 15),
                onPressed: () {
                  final parsed = _parseHexColor(_customHexController.text);
                  if (parsed != null) {
                    ref.read(customBrandColorProvider.notifier).setCustomBrandColor(parsed);
                    ref.read(themePresetProvider.notifier).setThemePreset('custom');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom brand theme applied successfully!'),
                        backgroundColor: AppColorsTokens.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid 6-character hex color (e.g. #0F766E)'),
                        backgroundColor: AppColorsTokens.danger,
                      ),
                    );
                  }
                },
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hexInput,
                    const SizedBox(height: 10),
                    applyBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: hexInput),
                  const SizedBox(width: 12),
                  applyBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
