import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../controllers/super_admin_controller.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen> {
  int _selectedTab = 0; // 0 = New Registrations, 1 = Plan Upgrades
  PharmacyModel? _selectedPharmacy;

  void _showApprovalDialog(BuildContext context, PharmacyModel pharmacy) {
    String selectedPlan = 'Standard';
    int extendDays = 365;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
          title: Text('Approve "${pharmacy.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will activate the pharmacy account and notify the owner via push notification.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPlan,
                decoration:
                    const InputDecoration(labelText: 'Subscription Plan'),
                items: const [
                  DropdownMenuItem(
                      value: 'Standard', child: Text('Standard Plan')),
                  DropdownMenuItem(
                      value: 'Professional', child: Text('Professional Plan')),
                  DropdownMenuItem(
                      value: 'Enterprise', child: Text('Enterprise Plan')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedPlan = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: extendDays,
                decoration: const InputDecoration(labelText: 'Validity Period'),
                items: const [
                  DropdownMenuItem(
                      value: 30, child: Text('1 Month (30 Days)')),
                  DropdownMenuItem(
                      value: 180, child: Text('6 Months (180 Days)')),
                  DropdownMenuItem(
                      value: 365, child: Text('1 Year (365 Days)')),
                  DropdownMenuItem(
                      value: 730, child: Text('2 Years (730 Days)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => extendDays = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Confirm Approval',
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(superAdminActionControllerProvider.notifier)
                      .reviewPharmacy(
                        pharmacyId: pharmacy.id,
                        action: 'approved',
                        plan: selectedPlan,
                        extendDays: extendDays,
                      );
                  setState(() => _selectedPharmacy = null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Pharmacy "${pharmacy.name}" approved successfully!'),
                        backgroundColor: AppColorsTokens.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Approval failed: $e'),
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

  void _showRejectDialog(BuildContext context, PharmacyModel pharmacy) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text('Reject "${pharmacy.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the reason for rejection. This will be shown to the pharmacy owner.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText:
                    'e.g. License document illegible or expired license number.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton.danger(
            text: 'Reject Registration',
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: AppColorsTokens.danger,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await ref
                    .read(superAdminActionControllerProvider.notifier)
                    .reviewPharmacy(
                      pharmacyId: pharmacy.id,
                      action: 'rejected',
                      reason: reason,
                    );
                setState(() => _selectedPharmacy = null);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pharmacy "${pharmacy.name}" rejected.'),
                      backgroundColor: AppColorsTokens.danger,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rejection failed: $e'),
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

  void _showAcceptUpgradeDialog(
      BuildContext context, PharmacyModel pharmacy) {
    String selectedPlan = pharmacy.requestedPlan ?? 'Professional';
    int extendDays = pharmacy.requestedPlanDays ?? 365;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
          title: Text('Approve Plan Upgrade for "${pharmacy.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This pharmacy requested to upgrade from ${pharmacy.plan ?? 'Standard'} to ${pharmacy.requestedPlan ?? 'Professional'}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPlan,
                decoration:
                    const InputDecoration(labelText: 'Plan Tier to Activate'),
                items: const [
                  DropdownMenuItem(
                      value: 'Standard', child: Text('Standard Plan')),
                  DropdownMenuItem(
                      value: 'Professional', child: Text('Professional Plan')),
                  DropdownMenuItem(
                      value: 'Enterprise', child: Text('Enterprise Plan')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlan = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: extendDays,
                decoration:
                    const InputDecoration(labelText: 'Validity Extension'),
                items: const [
                  DropdownMenuItem(
                      value: 30, child: Text('1 Month (30 Days)')),
                  DropdownMenuItem(
                      value: 90, child: Text('3 Months (90 Days)')),
                  DropdownMenuItem(
                      value: 180, child: Text('6 Months (180 Days)')),
                  DropdownMenuItem(
                      value: 365, child: Text('1 Year (365 Days)')),
                  DropdownMenuItem(
                      value: 730, child: Text('2 Years (730 Days)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => extendDays = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Activate Plan Upgrade',
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(superAdminActionControllerProvider.notifier)
                      .acceptPlanUpgrade(
                        pharmacyId: pharmacy.id,
                        plan: selectedPlan,
                        planDays: extendDays,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Upgrade to $selectedPlan approved for "${pharmacy.name}"!'),
                        backgroundColor: AppColorsTokens.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to activate upgrade: $e'),
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

  void _showRejectUpgradeDialog(
      BuildContext context, PharmacyModel pharmacy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Text('Reject Upgrade Request'),
        content: Text(
          'Are you sure you want to reject the upgrade request for "${pharmacy.name}" to ${pharmacy.requestedPlan}? The pharmacy will remain on their current active plan (${pharmacy.plan ?? 'Standard'}).',
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B6567)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton.danger(
            text: 'Reject Request',
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
                      content: Text('Failed to reject upgrade: $e'),
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
    final pendingRegistrations =
        ref.watch(pendingApprovalsProvider).value ?? [];
    final upgradeRequests =
        ref.watch(planUpgradeRequestsProvider).value ?? [];

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Tabs Header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.building,
                            size: 16,
                            color: _selectedTab == 0
                                ? AppColorsTokens.brand
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Registration Approvals (${pendingRegistrations.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTab == 0
                                  ? AppColorsTokens.brand
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: _selectedTab == 1
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Plan Upgrade Requests (${upgradeRequests.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTab == 1
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF64748B),
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
          const SizedBox(height: 20),

          // TAB 0: Registration Approvals
          if (_selectedTab == 0) ...[
            if (pendingRegistrations.isEmpty)
              const EmptyState(
                title: 'No Pending Registration Approvals',
                subtitle:
                    'All pharmacy registration applications have been reviewed.',
                icon: LucideIcons.checkSquare,
              )
            else
              _buildRegistrationsView(
                context,
                pendingRegistrations,
                isDesktop,
              ),
          ],

          // TAB 1: Plan Upgrade Requests
          if (_selectedTab == 1) ...[
            if (upgradeRequests.isEmpty)
              const EmptyState(
                title: 'No Pending Plan Upgrades',
                subtitle:
                    'When pharmacy administrators request to upgrade their plan, requests will appear here for your review and activation.',
                icon: LucideIcons.sparkles,
              )
            else
              _buildUpgradesView(context, upgradeRequests),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationsView(
    BuildContext context,
    List<PharmacyModel> pharmacies,
    bool isDesktop,
  ) {
    final selected = _selectedPharmacy ?? pharmacies.first;

    final tableWidget = SectionCard(
      title: 'Pending Applications',
      subtitle: '${pharmacies.length} pharmacies waiting for verification',
      child: AppDataTable(
        columns: const [
          AppTableColumn(label: 'Pharmacy', flex: 3),
          AppTableColumn(label: 'City', flex: 2),
          AppTableColumn(label: 'License No', flex: 2),
          AppTableColumn(label: 'Submitted', flex: 2),
          AppTableColumn(label: 'Status', flex: 2),
        ],
        rows: pharmacies.map((p) {
          final isSelected = selected.id == p.id;
          return [
            InkWell(
              onTap: () => setState(() => _selectedPharmacy = p),
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isSelected ? AppColorsTokens.brand : null,
                ),
              ),
            ),
            Text(p.city ?? '—',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            Text(p.licenseNo ?? '—',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            Text(
              p.createdAt.toString().split(' ').first,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF4B6567)),
            ),
            const StatusBadge(
                label: 'Pending', variant: StatusBadgeVariant.amber),
          ];
        }).toList(),
        mobileCards: pharmacies.map((p) {
          final isSelected = selected.id == p.id;
          return InkWell(
            onTap: () => setState(() => _selectedPharmacy = p),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColorsTokens.mint.withValues(alpha: 0.15)
                    : context.tokens.colors.card,
                borderRadius:
                    BorderRadius.circular(AppRadiusTokens.tile),
                border: Border.all(
                  color: isSelected
                      ? AppColorsTokens.brand
                      : context.tokens.colors.line,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? AppColorsTokens.brand
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.city ?? 'No city'} • ${p.licenseNo ?? 'No license'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.tokens.colors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(
                      label: 'Pending',
                      variant: StatusBadgeVariant.amber),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    final previewSidePanel = SectionCard(
      title: 'License Preview & Details',
      subtitle: 'Verification inspector',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorsTokens.light.track,
              borderRadius:
                  BorderRadius.circular(AppRadiusTokens.tile),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selected.address ?? ''}, ${selected.city ?? ''}${selected.province != null ? ' (${selected.province})' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF4B6567)),
                ),
                const SizedBox(height: 12),
                _infoRow('Reg. Number:', selected.registrationNumber ?? '—'),
                _infoRow('Drug Sale License:', selected.drugSaleLicense ?? selected.licenseNo ?? '—'),
                _infoRow('Owner Name:', selected.ownerName ?? '—'),
                _infoRow('Pharmacist:', selected.pharmacistName ?? '—'),
                _infoRow('Pharmacist Reg:', selected.pharmacistRegistration ?? '—'),
                _infoRow('Owner CNIC:', selected.cnic ?? '—'),
                _infoRow('Official Phone:', selected.phone ?? '—'),
                _infoRow('Email:', selected.email ?? selected.ownerEmail ?? '—'),
                _infoRow('Province:', selected.province ?? '—'),
                _infoRow('Issue Date:', selected.licenseIssueDate != null
                    ? '${selected.licenseIssueDate!.year}-${selected.licenseIssueDate!.month.toString().padLeft(2, '0')}-${selected.licenseIssueDate!.day.toString().padLeft(2, '0')}'
                    : '—'),
                _infoRow('Expiry Date:', selected.licenseExpiryDate != null
                    ? '${selected.licenseExpiryDate!.year}-${selected.licenseExpiryDate!.month.toString().padLeft(2, '0')}-${selected.licenseExpiryDate!.day.toString().padLeft(2, '0')}'
                    : '—'),
                _infoRow('Currency:', selected.currency),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Document preview box
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(AppRadiusTokens.tile),
              border: Border.all(color: AppColorsTokens.light.line),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.fileText,
                      size: 40, color: AppColorsTokens.brand),
                  const SizedBox(height: 8),
                  Text(
                    selected.licenseDocUrl != null
                        ? 'License Document Attached'
                        : 'Standard License Record',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verified for pharmaceutical trade',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF4B6567)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Approve / Reject actions
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Approve',
                  icon: const Icon(LucideIcons.check,
                      size: 16, color: Colors.white),
                  onPressed: () =>
                      _showApprovalDialog(context, selected),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton.danger(
                  text: 'Reject',
                  icon: const Icon(LucideIcons.x,
                      size: 16, color: Colors.white),
                  onPressed: () =>
                      _showRejectDialog(context, selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [
          tableWidget,
          const SizedBox(height: 20),
          previewSidePanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 16, child: tableWidget),
        const SizedBox(width: 16),
        SizedBox(width: 380, child: previewSidePanel),
      ],
    );
  }

  Widget _buildUpgradesView(
    BuildContext context,
    List<PharmacyModel> pharmacies,
  ) {
    return SectionCard(
      title: 'Plan Upgrade Requests',
      subtitle:
          '${pharmacies.length} pharmacies requested to switch subscription tiers',
      child: Column(
        children: pharmacies.map((p) {
          final requested = p.requestedPlan ?? 'Professional';
          final current = p.plan ?? 'Standard';
          final duration = p.requestedPlanDays ?? 365;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (p.city != null)
                            Text(
                              '(${p.city})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$current Plan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(LucideIcons.arrowRight,
                                size: 13, color: Color(0xFF94A3B8)),
                          ),
                          Text(
                            '$requested Plan ($duration Days)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      if (p.requestedPlanAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Requested on ${p.requestedPlanAt!.toLocal().toString().split(' ').first}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: 'Accept Upgrade',
                      icon: const Icon(LucideIcons.check,
                          size: 15, color: Colors.white),
                      onPressed: () => _showAcceptUpgradeDialog(context, p),
                    ),
                    const SizedBox(width: 8),
                    AppButton.danger(
                      text: 'Reject',
                      icon: const Icon(LucideIcons.x,
                          size: 15, color: Colors.white),
                      onPressed: () => _showRejectUpgradeDialog(context, p),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B6567))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
