import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/firebase/firebase_providers.dart';
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

              // 4. Subscription & Plan Status
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
}
