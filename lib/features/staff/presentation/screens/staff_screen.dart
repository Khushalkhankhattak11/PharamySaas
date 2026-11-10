import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/models/profile_model.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/plan_upgrade_dialog.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/staff_controller.dart';
import '../widgets/cashier_shifts_view.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 = Staff Directory, 1 = Cashier Shifts & Sales Progress

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddStaffDialog(BuildContext context) {
    final PharmacyModel? pharmacy = ref.read(currentPharmacyProvider).value;
    final pharmacyDomain = pharmacy?.domain ?? 'pharmacy.com';

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.cashier;
    String shiftPreset = 'morning';
    String shiftStart = '09:00';
    String shiftEnd = '17:00';
    String shiftLabel = 'Morning (09:00 - 17:00)';
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
          title: const Text('Add Pharmacy Staff'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create credentials for your Cashier or Storekeeper under @$pharmacyDomain or any valid email.',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColorsTokens.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColorsTokens.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertTriangle,
                              size: 16, color: AppColorsTokens.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColorsTokens.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Staff Username or Email *',
                      hintText: 'e.g. storekeeper or user@gmail.com',
                      prefixIcon: const Icon(LucideIcons.mail),
                      suffixText: usernameController.text.contains('@')
                          ? null
                          : '@$pharmacyDomain',
                      suffixStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColorsTokens.brand,
                      ),
                      helperText: usernameController.text.contains('@')
                          ? 'Using custom email address'
                          : 'Username shorthand auto-appends @$pharmacyDomain',
                      helperMaxLines: 2,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username or email is required';
                      }
                      final clean = v.trim().toLowerCase();
                      if (clean.contains('@')) {
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(clean)) {
                          return 'Enter a valid email address';
                        }
                      } else {
                        if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(clean)) {
                          return 'Username can only contain letters, numbers, and .-_';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    enabled: !isSubmitting,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password *',
                      prefixIcon: Icon(LucideIcons.lock),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign Staff Role:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Cashier'),
                        selected: selectedRole == UserRole.cashier,
                        selectedColor:
                            AppColorsTokens.info.withValues(alpha: 0.2),
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(
                                      () => selectedRole = UserRole.cashier);
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Storekeeper'),
                        selected: selectedRole == UserRole.storekeeper,
                        selectedColor: AppColorsTokens.mint,
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() =>
                                      selectedRole = UserRole.storekeeper);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assigned Shift Time (Punctuality Schedule):',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Set expected shift hours so you can track if staff arrive on time or late.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Morning (09:00 - 17:00)'),
                        selected: shiftPreset == 'morning',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() {
                                    shiftPreset = 'morning';
                                    shiftStart = '09:00';
                                    shiftEnd = '17:00';
                                    shiftLabel = 'Morning (09:00 - 17:00)';
                                  });
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Evening (17:00 - 23:00)'),
                        selected: shiftPreset == 'evening',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() {
                                    shiftPreset = 'evening';
                                    shiftStart = '17:00';
                                    shiftEnd = '23:00';
                                    shiftLabel = 'Evening (17:00 - 23:00)';
                                  });
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Night (23:00 - 07:00)'),
                        selected: shiftPreset == 'night',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() {
                                    shiftPreset = 'night';
                                    shiftStart = '23:00';
                                    shiftEnd = '07:00';
                                    shiftLabel = 'Night (23:00 - 07:00)';
                                  });
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Custom Hours'),
                        selected: shiftPreset == 'custom',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: isSubmitting
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() {
                                    shiftPreset = 'custom';
                                    shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                  if (shiftPreset == 'custom') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    final parts = shiftStart.split(':');
                                    final initial = TimeOfDay(
                                      hour: int.tryParse(parts[0]) ?? 9,
                                      minute: int.tryParse(parts[1]) ?? 0,
                                    );
                                    final picked = await showTimePicker(
                                        context: ctx, initialTime: initial);
                                    if (picked != null) {
                                      final h = picked.hour.toString().padLeft(2, '0');
                                      final m = picked.minute.toString().padLeft(2, '0');
                                      setDialogState(() {
                                        shiftStart = '$h:$m';
                                        shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                                      });
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock,
                                      size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text('Start: $shiftStart',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    final parts = shiftEnd.split(':');
                                    final initial = TimeOfDay(
                                      hour: int.tryParse(parts[0]) ?? 17,
                                      minute: int.tryParse(parts[1]) ?? 0,
                                    );
                                    final picked = await showTimePicker(
                                        context: ctx, initialTime: initial);
                                    if (picked != null) {
                                      final h = picked.hour.toString().padLeft(2, '0');
                                      final m = picked.minute.toString().padLeft(2, '0');
                                      setDialogState(() {
                                        shiftEnd = '$h:$m';
                                        shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                                      });
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock,
                                      size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text('End: $shiftEnd',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: isSubmitting ? 'Creating...' : 'Create Account',
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final raw = usernameController.text.trim().toLowerCase();
                      final staffEmail =
                          raw.contains('@') ? raw : '$raw@$pharmacyDomain';

                      final fullName = nameController.text.trim();
                      final staffRole = selectedRole;
                      final staffPhone = phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim();

                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });

                      try {
                        await ref
                            .read(staffActionControllerProvider.notifier)
                            .createStaff(
                              email: staffEmail,
                              password: passwordController.text,
                              fullName: fullName,
                              role: staffRole,
                              phone: staffPhone,
                              shiftStart: shiftStart,
                              shiftEnd: shiftEnd,
                              shiftLabel: shiftLabel,
                            );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          _showCredentialsDialog(
                            context,
                            email: staffEmail,
                            fullName: fullName,
                            role: staffRole.label,
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMessage =
                              e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(
    BuildContext context, {
    required String email,
    required String fullName,
    required String role,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColorsTokens.trendGreenText),
            SizedBox(width: 8),
            Text('Staff Account Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share these exact login credentials with $fullName:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F9F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDFECEB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$role Login Email',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColorsTokens.brand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF06292B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    tooltip: 'Copy Email',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: email));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Staff login email copied to clipboard!'),
                          backgroundColor: AppColorsTokens.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The staff member must enter this full email and their assigned password on the Login Screen.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF4B6567),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: 'Done',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showStaffLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppColorsTokens.brand, size: 20),
            SizedBox(width: 8),
            Text('Staff Quota Reached'),
          ],
        ),
        content: const Text(
          'Your pharmacy is currently on the Standard Plan, which includes up to 2 staff accounts (e.g. 1 Cashier and 1 Storekeeper).\n\n'
          'To add more staff members with dedicated accounts, upgrade to the Professional or Enterprise Plan.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: Color(0xFF4B6567)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'View Plans & Upgrade',
            onPressed: () {
              Navigator.pop(ctx);
              showPlanUpgradeDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void showEditStaffDialog(BuildContext context, ProfileModel staff) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff.fullName);
    final phoneController = TextEditingController(text: staff.phone ?? '');
    UserRole selectedRole = staff.role;

    String shiftStart = staff.shiftStart ?? '09:00';
    String shiftEnd = staff.shiftEnd ?? '17:00';
    String shiftLabel = staff.shiftLabel ??
        (staff.shiftStart != null ? '${staff.shiftStart} - ${staff.shiftEnd}' : 'Morning (09:00 - 17:00)');
    String shiftPreset = 'morning';
    if (staff.shiftStart == '09:00' && staff.shiftEnd == '17:00') {
      shiftPreset = 'morning';
    } else if (staff.shiftStart == '17:00' && staff.shiftEnd == '23:00') {
      shiftPreset = 'evening';
    } else if (staff.shiftStart == '23:00' && staff.shiftEnd == '07:00') {
      shiftPreset = 'night';
    } else if (staff.shiftStart != null) {
      shiftPreset = 'custom';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
          title: Text('Edit Staff: ${staff.fullName}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Cashier'),
                        selected: selectedRole == UserRole.cashier,
                        selectedColor:
                            AppColorsTokens.info.withValues(alpha: 0.2),
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(
                                () => selectedRole = UserRole.cashier);
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Storekeeper'),
                        selected: selectedRole == UserRole.storekeeper,
                        selectedColor: AppColorsTokens.mint,
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(
                                () => selectedRole = UserRole.storekeeper);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assigned Shift Time (Punctuality Schedule):',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Shift hours used to verify if staff arrives on time.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Morning (09:00 - 17:00)'),
                        selected: shiftPreset == 'morning',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(() {
                              shiftPreset = 'morning';
                              shiftStart = '09:00';
                              shiftEnd = '17:00';
                              shiftLabel = 'Morning (09:00 - 17:00)';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Evening (17:00 - 23:00)'),
                        selected: shiftPreset == 'evening',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(() {
                              shiftPreset = 'evening';
                              shiftStart = '17:00';
                              shiftEnd = '23:00';
                              shiftLabel = 'Evening (17:00 - 23:00)';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Night (23:00 - 07:00)'),
                        selected: shiftPreset == 'night',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(() {
                              shiftPreset = 'night';
                              shiftStart = '23:00';
                              shiftEnd = '07:00';
                              shiftLabel = 'Night (23:00 - 07:00)';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Custom Hours'),
                        selected: shiftPreset == 'custom',
                        selectedColor: AppColorsTokens.brand.withValues(alpha: 0.15),
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(() {
                              shiftPreset = 'custom';
                              shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (shiftPreset == 'custom') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final parts = shiftStart.split(':');
                              final initial = TimeOfDay(
                                hour: int.tryParse(parts[0]) ?? 9,
                                minute: int.tryParse(parts[1]) ?? 0,
                              );
                              final picked = await showTimePicker(
                                  context: ctx, initialTime: initial);
                              if (picked != null) {
                                final h = picked.hour.toString().padLeft(2, '0');
                                final m = picked.minute.toString().padLeft(2, '0');
                                setDialogState(() {
                                  shiftStart = '$h:$m';
                                  shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock,
                                      size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text('Start: $shiftStart',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final parts = shiftEnd.split(':');
                              final initial = TimeOfDay(
                                hour: int.tryParse(parts[0]) ?? 17,
                                minute: int.tryParse(parts[1]) ?? 0,
                              );
                              final picked = await showTimePicker(
                                  context: ctx, initialTime: initial);
                              if (picked != null) {
                                final h = picked.hour.toString().padLeft(2, '0');
                                final m = picked.minute.toString().padLeft(2, '0');
                                setDialogState(() {
                                  shiftEnd = '$h:$m';
                                  shiftLabel = 'Custom ($shiftStart - $shiftEnd)';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock,
                                      size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text('End: $shiftEnd',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(staffActionControllerProvider.notifier)
                      .updateStaff(
                        staffId: staff.id,
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        role: selectedRole,
                        shiftStart: shiftStart,
                        shiftEnd: shiftEnd,
                        shiftLabel: shiftLabel,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Staff details updated!'),
                        backgroundColor: AppColorsTokens.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: AppColorsTokens.danger,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void showResetPasswordDialog(BuildContext context, ProfileModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text('Reset Password for ${staff.fullName}'),
        content: Text(
          'Send a password reset email to ${staff.email ?? "their registered email"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Send Reset Email',
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(staffActionControllerProvider.notifier)
                    .resetStaffPassword(
                      staffId: staff.id,
                      newPassword: '',
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset instructions sent!'),
                      backgroundColor: AppColorsTokens.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to reset: $e'),
                        backgroundColor: AppColorsTokens.danger),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void toggleStaffStatus(BuildContext context, ProfileModel staff) {
    final isDeactivating = staff.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text(
            '${isDeactivating ? 'Deactivate' : 'Reactivate'} "${staff.fullName}"?'),
        content: Text(
          isDeactivating
              ? 'This staff member will immediately be logged out and blocked from accessing the system.'
              : 'This will restore login and operational access for this staff member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: isDeactivating ? 'Deactivate' : 'Reactivate',
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(staffActionControllerProvider.notifier)
                    .toggleStaffStatus(
                      staffId: staff.id,
                      isActive: !isDeactivating,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Action failed: $e'),
                        backgroundColor: AppColorsTokens.danger),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void confirmDeleteStaff(BuildContext context, ProfileModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text('Delete "${staff.fullName}"?'),
        content: Text(
          'Are you sure you want to remove this ${staff.role.label}? Their profile and permissions will be deleted from your pharmacy staff directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton.danger(
            text: 'Delete Staff',
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(staffActionControllerProvider.notifier)
                    .deleteStaff(
                      staffId: staff.id,
                      role: staff.role,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Staff member "${staff.fullName}" removed.'),
                      backgroundColor: AppColorsTokens.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final staffAsync = ref.watch(staffListProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final staffList = staffAsync.value ?? [];
    final isStaffLimitReached =
        pharmacy != null && !pharmacy.canAddMoreStaff(staffList.length);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan Quota Banner (for Standard Plan)
          if (pharmacy != null && pharmacy.isStandardPlan) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isStaffLimitReached
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isStaffLimitReached
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isStaffLimitReached
                        ? LucideIcons.alertCircle
                        : LucideIcons.checkCircle2,
                    size: 16,
                    color: isStaffLimitReached
                        ? AppColorsTokens.danger
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isStaffLimitReached
                          ? 'Standard Plan staff quota reached (${staffList.length}/2 accounts). Upgrade to Professional for unlimited staff.'
                          : 'Staff Quota: ${staffList.length}/2 accounts used (Standard Plan)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isStaffLimitReached
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ),
                  if (isStaffLimitReached)
                    TextButton(
                      onPressed: () => showPlanUpgradeDialog(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        foregroundColor: AppColorsTokens.danger,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Upgrade Plan'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Navigation Tabs: Directory vs Shifts & Sales Progress
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tokens.colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.colors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0 ? AppColorsTokens.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 16,
                            color: _selectedTabIndex == 0 ? Colors.white : tokens.colors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Staff Accounts Directory (${staffList.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTabIndex == 0 ? Colors.white : tokens.colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1 ? AppColorsTokens.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.wallet,
                            size: 16,
                            color: _selectedTabIndex == 1 ? Colors.white : tokens.colors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cashier Shifts & Sales Progress',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTabIndex == 1 ? Colors.white : tokens.colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedTabIndex == 1)
            const CashierShiftsView()
          else ...[
            // Controls Row
            Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    controller: _searchController,
                    maxWidth: double.infinity,
                    placeholder: 'Search staff name, email, or phone...',
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: '+ Add Staff',
                  icon: const Icon(LucideIcons.userPlus,
                      size: 16, color: Colors.white),
                  onPressed: () => isStaffLimitReached
                      ? _showStaffLimitReachedDialog(context)
                      : _showAddStaffDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            staffAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Error loading staff: $err')),
            data: (staffList) {
              final filtered = _searchQuery.isEmpty
                  ? staffList
                  : staffList.where((s) {
                      final n = s.fullName.toLowerCase();
                      final p = s.phone?.toLowerCase() ?? '';
                      final e = s.email?.toLowerCase() ?? '';
                      return n.contains(_searchQuery) ||
                          p.contains(_searchQuery) ||
                          e.contains(_searchQuery);
                    }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  title: 'No Staff Accounts Found',
                  subtitle:
                      'Invite cashiers and storekeepers to operate your store.',
                  icon: LucideIcons.users,
                  actionLabel: 'Add First Staff Member',
                  onAction: () => isStaffLimitReached
                      ? _showStaffLimitReachedDialog(context)
                      : _showAddStaffDialog(context),
                );
              }

              const columns = [
                AppTableColumn(label: 'Staff Member', flex: 3),
                AppTableColumn(label: 'Role & Shift Schedule', flex: 3),
                AppTableColumn(label: 'Phone Contact', flex: 2),
                AppTableColumn(label: 'Account Status', flex: 2),
                AppTableColumn(
                    label: 'Actions', align: TextAlign.right, flex: 2),
              ];

              final rows = filtered.map((s) {
                final isCashier = s.role == UserRole.cashier;
                final hasShift = s.shiftStart != null;
                final shiftDisplay = s.shiftLabel ??
                    (hasShift ? '${s.shiftStart} - ${s.shiftEnd}' : 'Not scheduled');

                return [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      if (s.email != null)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: s.email!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied: ${s.email}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.email!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColorsTokens.brand,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.copy,
                                  size: 11, color: AppColorsTokens.brand),
                            ],
                          ),
                        ),
                      Text(
                        'Joined ${s.createdAt != null ? s.createdAt.toString().split(' ').first : 'Recently'}',
                        style:
                            TextStyle(fontSize: 11, color: tokens.colors.muted),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: s.role.label,
                        variant: isCashier
                            ? StatusBadgeVariant.info
                            : StatusBadgeVariant.success,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock,
                              size: 11,
                              color: hasShift
                                  ? const Color(0xFF0F766E)
                                  : tokens.colors.muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              shiftDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: hasShift
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: hasShift
                                    ? const Color(0xFF0F766E)
                                    : tokens.colors.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(s.phone ?? '—', style: const TextStyle(fontSize: 13)),
                  StatusBadge(
                    label: s.isActive ? 'Active' : 'Deactivated',
                    variant: s.isActive
                        ? StatusBadgeVariant.success
                        : StatusBadgeVariant.danger,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.edit2, size: 16),
                          color: tokens.colors.muted,
                          tooltip: 'Edit Staff Details',
                          onPressed: () => showEditStaffDialog(context, s),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.key, size: 16),
                          color: tokens.colors.muted,
                          tooltip: 'Reset Password',
                          onPressed: () => showResetPasswordDialog(context, s),
                        ),
                        IconButton(
                          icon: Icon(
                            s.isActive
                                ? LucideIcons.userX
                                : LucideIcons.userCheck,
                            size: 16,
                            color: s.isActive
                                ? AppColorsTokens.amber
                                : AppColorsTokens.success,
                          ),
                          tooltip: s.isActive ? 'Deactivate' : 'Reactivate',
                          onPressed: () => toggleStaffStatus(context, s),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          color: AppColorsTokens.danger,
                          tooltip: 'Delete Staff',
                          onPressed: () => confirmDeleteStaff(context, s),
                        ),
                      ],
                    ),
                  ),
                ];
              }).toList();

              final mobileCards = filtered.map((s) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                    border: Border.all(color: tokens.colors.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (s.email != null)
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: s.email!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied: ${s.email}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        s.email!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColorsTokens.brand),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.copy,
                                        size: 11,
                                        color: AppColorsTokens.brand),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.role.label}${s.shiftStart != null ? " • Shift: ${s.shiftStart}-${s.shiftEnd}" : ""} • ${s.isActive ? 'Active' : 'Deactivated'} • ${s.phone ?? 'No phone'}',
                              style: TextStyle(
                                  fontSize: 12, color: tokens.colors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(LucideIcons.edit2, size: 18),
                        tooltip: 'Edit',
                        onPressed: () => showEditStaffDialog(context, s),
                      ),
                      IconButton(
                        icon: Icon(
                          s.isActive
                              ? LucideIcons.userX
                              : LucideIcons.userCheck,
                          size: 18,
                          color: s.isActive
                              ? AppColorsTokens.amber
                              : AppColorsTokens.success,
                        ),
                        tooltip: s.isActive ? 'Deactivate' : 'Reactivate',
                        onPressed: () => toggleStaffStatus(context, s),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        color: AppColorsTokens.danger,
                        tooltip: 'Delete',
                        onPressed: () => confirmDeleteStaff(context, s),
                      ),
                    ],
                  ),
                );
              }).toList();

              return SectionCard(
                title: 'Staff Accounts',
                subtitle:
                    'Showing ${filtered.length} active and inactive staff members',
                child: AppDataTable(
                  columns: columns,
                  rows: rows,
                  mobileCards: mobileCards,
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
  }
}
